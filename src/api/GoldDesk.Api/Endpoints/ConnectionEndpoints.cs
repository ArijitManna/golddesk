using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Connections.BlockConnection;
using GoldDesk.Application.Features.Connections.CancelConnection;
using GoldDesk.Application.Features.Connections.GetConnections;
using GoldDesk.Application.Features.Connections.RequestConnection;
using GoldDesk.Application.Features.Connections.RespondConnection;
using GoldDesk.Application.Features.Connections.SearchBusiness;
using MediatR;

namespace GoldDesk.Api.Endpoints;

public static class ConnectionEndpoints
{
    public static void MapConnectionEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/connections")
            .WithTags("Connections")
            .RequireAuthorization();

        group.MapGet("/", async (string? status, string? connectionType, IMediator mediator) =>
        {
            var result = await mediator.Send(new GetConnectionsQuery
            {
                Status = status,
                ConnectionType = connectionType
            });
            return ToResponse(result);
        })
        .WithName("GetConnections");

        group.MapGet("/search", async (string goldDeskId, IMediator mediator) =>
        {
            var result = await mediator.Send(new SearchBusinessQuery { GoldDeskId = goldDeskId });
            return ToResponse(result);
        })
        .WithName("SearchBusiness");

        group.MapPost("/request", async (RequestConnectionCommand command, IMediator mediator) =>
        {
            var result = await mediator.Send(command);
            return result.IsSuccess
                ? Results.Created($"/api/connections/{result.Data!.Id}", result.Data)
                : ToErrorResponse(result);
        })
        .WithName("RequestConnection");

        group.MapPost("/{id:guid}/respond", async (Guid id, RespondConnectionRequest body, IMediator mediator) =>
        {
            var result = await mediator.Send(new RespondConnectionCommand
            {
                ConnectionId = id,
                Accept = body.Accept
            });
            return result.IsSuccess ? Results.Ok(result.Data) : ToErrorResponse(result);
        })
        .WithName("RespondConnection");

        group.MapDelete("/{id:guid}", async (Guid id, IMediator mediator) =>
        {
            var result = await mediator.Send(new CancelConnectionCommand(id));
            return result.IsSuccess ? Results.NoContent() : ToErrorResponse(result);
        })
        .WithName("CancelConnectionRequest");

        group.MapPost("/{id:guid}/block", async (Guid id, IMediator mediator) =>
        {
            var result = await mediator.Send(new BlockConnectionCommand(id));
            return result.IsSuccess
                ? Results.Ok(new { message = "Connection blocked" })
                : ToErrorResponse(result);
        })
        .WithName("BlockConnection");
    }

    private static IResult ToResponse<T>(Result<T> result)
    {
        if (result.IsSuccess) return Results.Ok(result.Data);
        return result.StatusCode switch
        {
            401 => Results.Unauthorized(),
            403 => Results.Json(new { error = result.Error }, statusCode: 403),
            404 => Results.NotFound(new { error = result.Error }),
            409 => Results.Conflict(new { error = result.Error }),
            _ => Results.BadRequest(new { error = result.Error })
        };
    }

    private static IResult ToErrorResponse<T>(Result<T> result) => ToResponse(result);
}

public record RespondConnectionRequest
{
    public bool Accept { get; init; }
}
