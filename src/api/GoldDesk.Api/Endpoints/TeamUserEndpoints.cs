using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.TeamUsers.CreateTeamUser;
using GoldDesk.Application.Features.TeamUsers.DeactivateTeamUser;
using GoldDesk.Application.Features.TeamUsers.GetTeamUsers;
using MediatR;

namespace GoldDesk.Api.Endpoints;

public static class TeamUserEndpoints
{
    public static void MapTeamUserEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/team-users")
            .WithTags("Team Users")
            .RequireAuthorization(policy => policy.RequireRole("ShopOwner"));

        group.MapGet("/", async (IMediator mediator) =>
        {
            var result = await mediator.Send(new GetTeamUsersQuery());
            return ToResponse(result);
        })
        .WithName("GetTeamUsers");

        group.MapPost("/", async (CreateTeamUserCommand command, IMediator mediator) =>
        {
            var result = await mediator.Send(command);
            return result.IsSuccess
                ? Results.Created($"/api/team-users/{result.Data!.Id}", result.Data)
                : ToErrorResponse(result);
        })
        .WithName("CreateTeamUser");

        group.MapPost("/{id:guid}/deactivate", async (Guid id, IMediator mediator) =>
        {
            var result = await mediator.Send(new DeactivateTeamUserCommand(id));
            return result.IsSuccess
                ? Results.Ok(new { message = "Team user deactivated" })
                : ToErrorResponse(result);
        })
        .WithName("DeactivateTeamUser");
    }

    private static IResult ToResponse<T>(Result<T> result)
    {
        if (result.IsSuccess) return Results.Ok(result.Data);
        return result.StatusCode switch
        {
            403 => Results.Json(new { error = result.Error }, statusCode: 403),
            404 => Results.NotFound(new { error = result.Error }),
            _ => Results.BadRequest(new { error = result.Error })
        };
    }

    private static IResult ToErrorResponse<T>(Result<T> result)
    {
        return result.StatusCode switch
        {
            403 => Results.Json(new { error = result.Error }, statusCode: 403),
            409 => Results.Conflict(new { error = result.Error }),
            404 => Results.NotFound(new { error = result.Error }),
            _ => Results.BadRequest(new { error = result.Error })
        };
    }
}
