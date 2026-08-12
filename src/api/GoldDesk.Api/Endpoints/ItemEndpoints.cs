using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Items.CreateItem;
using GoldDesk.Application.Features.Items.DeleteItem;
using GoldDesk.Application.Features.Items.GetItems;
using GoldDesk.Application.Features.Items.UpdateItem;
using MediatR;

namespace GoldDesk.Api.Endpoints;

public static class ItemEndpoints
{
    public static void MapItemEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/items")
            .WithTags("Items")
            .RequireAuthorization();

        group.MapGet("/", async (string? search, string? category, int? page, int? pageSize, IMediator mediator) =>
        {
            var result = await mediator.Send(new GetItemsQuery
            {
                Search = search,
                Category = category,
                Page = page ?? 1,
                PageSize = pageSize ?? 20
            });
            return ToResponse(result);
        })
        .WithName("GetItems");

        group.MapPost("/", async (CreateItemCommand command, IMediator mediator) =>
        {
            var result = await mediator.Send(command);
            return result.IsSuccess
                ? Results.Created($"/api/items/{result.Data!.Id}", result.Data)
                : result.StatusCode == 409
                    ? Results.Conflict(new { error = result.Error })
                    : ToBadRequest(result);
        })
        .WithName("CreateItem");

        group.MapPut("/{id:guid}", async (Guid id, UpdateItemRequest request, IMediator mediator) =>
        {
            var result = await mediator.Send(new UpdateItemCommand
            {
                Id = id,
                Name = request.Name,
                Category = request.Category,
                Purity = request.Purity,
                DefaultRate = request.DefaultRate,
                DefaultMakingCharge = request.DefaultMakingCharge
            });
            return ToResponse(result);
        })
        .WithName("UpdateItem");

        group.MapDelete("/{id:guid}", async (Guid id, IMediator mediator) =>
        {
            var result = await mediator.Send(new DeleteItemCommand(id));
            return result.IsSuccess ? Results.NoContent() : Results.NotFound(new { error = result.Error });
        })
        .WithName("DeleteItem");
    }

    private static IResult ToResponse<T>(Result<T> result)
    {
        if (result.IsSuccess) return Results.Ok(result.Data);
        return result.StatusCode switch
        {
            404 => Results.NotFound(new { error = result.Error }),
            _ => Results.BadRequest(new { error = result.Error })
        };
    }

    private static IResult ToBadRequest<T>(Result<T> result) =>
        Results.BadRequest(new { error = result.Error });
}

public record UpdateItemRequest
{
    public string Name { get; init; } = string.Empty;
    public string? Category { get; init; }
    public string? Purity { get; init; }
    public decimal? DefaultRate { get; init; }
    public decimal? DefaultMakingCharge { get; init; }
}
