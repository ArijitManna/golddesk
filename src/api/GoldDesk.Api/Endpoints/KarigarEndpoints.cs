using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Karigars.CreateKarigar;
using GoldDesk.Application.Features.Karigars.DeactivateKarigar;
using GoldDesk.Application.Features.Karigars.GetKarigars;
using GoldDesk.Application.Features.Karigars.UpdateKarigar;
using MediatR;

namespace GoldDesk.Api.Endpoints;

public static class KarigarEndpoints
{
    public static void MapKarigarEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/karigars")
            .WithTags("Karigars")
            .RequireAuthorization();

        group.MapGet("/", async (string? search, bool? activeOnly, int? page, int? pageSize, IMediator mediator) =>
        {
            var result = await mediator.Send(new GetKarigarsQuery
            {
                Search = search,
                ActiveOnly = activeOnly ?? true,
                Page = page ?? 1,
                PageSize = pageSize ?? 20
            });
            return ToResponse(result);
        })
        .WithName("GetKarigars");

        group.MapPost("/", async (CreateKarigarCommand command, IMediator mediator) =>
        {
            var result = await mediator.Send(command);
            return result.IsSuccess
                ? Results.Created($"/api/karigars/{result.Data!.Id}", result.Data)
                : ToErrorResponse(result);
        })
        .WithName("CreateKarigar");

        group.MapPut("/{id:guid}", async (Guid id, UpdateKarigarRequest request, IMediator mediator) =>
        {
            var result = await mediator.Send(new UpdateKarigarCommand
            {
                Id = id,
                Name = request.Name,
                Mobile = request.Mobile,
                Email = request.Email,
                Address = request.Address,
                Specialization = request.Specialization
            });
            return ToResponse(result);
        })
        .WithName("UpdateKarigar");

        group.MapPost("/{id:guid}/deactivate", async (Guid id, IMediator mediator) =>
        {
            var result = await mediator.Send(new DeactivateKarigarCommand(id));
            return result.IsSuccess ? Results.Ok(new { message = "Karigar deactivated" }) : Results.NotFound(new { error = result.Error });
        })
        .WithName("DeactivateKarigar");
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

    private static IResult ToErrorResponse<T>(Result<T> result)
    {
        return result.StatusCode switch
        {
            409 => Results.Conflict(new { error = result.Error }),
            404 => Results.NotFound(new { error = result.Error }),
            _ => Results.BadRequest(new { error = result.Error })
        };
    }
}

public record UpdateKarigarRequest
{
    public string Name { get; init; } = string.Empty;
    public string Mobile { get; init; } = string.Empty;
    public string? Email { get; init; }
    public string? Address { get; init; }
    public string? Specialization { get; init; }
}
