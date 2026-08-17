using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.ExternalBusinesses;
using MediatR;

namespace GoldDesk.Api.Endpoints;

public static class ExternalBusinessEndpoints
{
    public static void MapExternalBusinessEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/external-businesses")
            .WithTags("External Businesses")
            .RequireAuthorization();

        group.MapGet("/", async (IMediator mediator) =>
        {
            var result = await mediator.Send(new GetExternalBusinessesQuery());
            return ToResponse(result);
        })
        .WithName("GetExternalBusinesses");

        group.MapPost("/", async (CreateExternalBusinessCommand command, IMediator mediator) =>
        {
            if (string.IsNullOrWhiteSpace(command.Name))
                return Results.BadRequest(new { error = "Business name is required." });

            var result = await mediator.Send(command);
            return result.IsSuccess
                ? Results.Created($"/api/external-businesses/{result.Data!.Id}", result.Data)
                : ToResponse(result);
        })
        .WithName("CreateExternalBusiness");

        group.MapPost("/{id:guid}/link", async (
            Guid id,
            LinkExternalBusinessRequest request,
            IMediator mediator) =>
        {
            var result = await mediator.Send(new LinkExternalBusinessCommand
            {
                ExternalBusinessId = id,
                GoldDeskId = request.GoldDeskId
            });
            return ToResponse(result);
        })
        .WithName("LinkExternalBusiness");
    }

    private static IResult ToResponse<T>(Result<T> result) => result.StatusCode switch
    {
        200 when result.IsSuccess => Results.Ok(result.Data),
        401 => Results.Unauthorized(),
        _ => Results.BadRequest(new { error = result.Error })
    };
}

public record LinkExternalBusinessRequest
{
    public string GoldDeskId { get; init; } = string.Empty;
}
