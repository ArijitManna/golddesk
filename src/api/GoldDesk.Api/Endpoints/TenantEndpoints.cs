using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.ShopProfile.GetTenantProfile;
using GoldDesk.Application.Features.ShopProfile.UpdateNotificationPreferences;
using GoldDesk.Application.Features.ShopProfile.UpdateTenantProfile;
using MediatR;

namespace GoldDesk.Api.Endpoints;

public static class TenantEndpoints
{
    public static void MapTenantEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/tenant")
            .WithTags("Tenant")
            .RequireAuthorization();

        group.MapGet("/profile", async (IMediator mediator) =>
        {
            var result = await mediator.Send(new GetTenantProfileQuery());
            return ToResponse(result);
        })
        .WithName("GetTenantProfile");

        group.MapPut("/profile", async (UpdateTenantProfileCommand command, IMediator mediator) =>
        {
            var result = await mediator.Send(command);
            return ToResponse(result);
        })
        .RequireAuthorization(policy => policy.RequireRole("ShopOwner"))
        .WithName("UpdateTenantProfile");

        group.MapPut("/notification-prefs", async (UpdateNotificationPreferencesCommand command, IMediator mediator) =>
        {
            var result = await mediator.Send(command);
            return ToResponse(result);
        })
        .RequireAuthorization(policy => policy.RequireRole("ShopOwner"))
        .WithName("UpdateNotificationPreferences");
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
}
