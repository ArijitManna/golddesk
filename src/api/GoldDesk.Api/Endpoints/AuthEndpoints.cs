using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Auth.ChangePassword;
using GoldDesk.Application.Features.Auth.Login;
using GoldDesk.Application.Features.Auth.RefreshToken;
using GoldDesk.Application.Features.Auth.Register;
using MediatR;

namespace GoldDesk.Api.Endpoints;

public static class AuthEndpoints
{
    public static void MapAuthEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/auth").WithTags("Authentication");

        group.MapPost("/register", async (RegisterCommand command, IMediator mediator) =>
        {
            var result = await mediator.Send(command);
            return ToResponse(result);
        })
        .WithName("Register")
        .WithDescription("Register a new shop. Account will be pending approval.")
        .AllowAnonymous();

        group.MapPost("/login", async (LoginCommand command, IMediator mediator) =>
        {
            var result = await mediator.Send(command);
            return ToResponse(result);
        })
        .WithName("Login")
        .WithDescription("Login with email and password")
        .AllowAnonymous();

        group.MapPost("/refresh", async (RefreshTokenCommand command, IMediator mediator) =>
        {
            var result = await mediator.Send(command);
            return ToResponse(result);
        })
        .WithName("RefreshToken")
        .WithDescription("Refresh an expired access token using a valid refresh token")
        .AllowAnonymous();

        group.MapPost("/change-password", async (ChangePasswordCommand command, IMediator mediator) =>
        {
            var result = await mediator.Send(command);
            return result.IsSuccess
                ? Results.Ok(new { message = "Password changed successfully" })
                : ToResponse(result);
        })
        .RequireAuthorization()
        .WithName("ChangePassword")
        .WithDescription("Change the current user's password");
    }

    private static IResult ToResponse<T>(Result<T> result)
    {
        if (result.IsSuccess)
        {
            return result.StatusCode == 201
                ? Results.Created("", result.Data)
                : Results.Ok(result.Data);
        }

        return result.StatusCode switch
        {
            401 => Results.Unauthorized(),
            403 => Results.Json(new { error = result.Error }, statusCode: 403),
            404 => Results.NotFound(new { error = result.Error }),
            409 => Results.Conflict(new { error = result.Error }),
            _ => Results.BadRequest(new { error = result.Error })
        };
    }
}
