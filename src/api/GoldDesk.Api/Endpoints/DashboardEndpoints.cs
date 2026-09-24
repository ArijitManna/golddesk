using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Dashboard.KarigarDashboard;
using GoldDesk.Application.Features.Dashboard.ShopDashboard;
using MediatR;

namespace GoldDesk.Api.Endpoints;

public static class DashboardEndpoints
{
    public static void MapDashboardEndpoints(this IEndpointRouteBuilder app)
    {
        // Shop Dashboard
        var shopGroup = app.MapGroup("/api/dashboard")
            .WithTags("Dashboard")
            .RequireAuthorization();

        shopGroup.MapGet("/", async (IMediator mediator) =>
        {
            var result = await mediator.Send(new GetShopDashboardQuery());
            return ToResponse(result);
        })
        .WithName("GetShopDashboard")
        .WithDescription("Get shop owner dashboard with order stats and alerts");

        shopGroup.MapGet("/gold-rate", async (IGoldRateService goldRates) =>
        {
            var snapshot = await goldRates.GetLatestAsync();
            if (snapshot == null)
                return Results.Ok(new { available = false });

            return Results.Ok(new
            {
                available = true,
                rate24k = snapshot.Rate24kPerGramInr,
                rate22k = snapshot.Rate22kPerGramInr,
                changePercent24k = snapshot.ChangePercent24k,
                updatedAt = snapshot.UpdatedAtUtc,
                source = snapshot.Source,
                unit = "INR per gram"
            });
        })
        .WithName("GetLiveGoldRate")
        .WithDescription("Live 24K/22K gold rate in INR per gram (cached international spot)");

        // Karigar Dashboard
        var karigarGroup = app.MapGroup("/api/karigar")
            .WithTags("Karigar Portal")
            .RequireAuthorization(policy => policy.RequireRole("Karigar", "ShopOwner"));

        karigarGroup.MapGet("/dashboard", async (IMediator mediator) =>
        {
            var result = await mediator.Send(new GetKarigarDashboardQuery());
            return ToResponse(result);
        })
        .WithName("GetKarigarDashboard")
        .WithDescription("Get Karigar dashboard with assignment stats and due-date alerts");

        karigarGroup.MapGet("/orders", async (string? status, string? assignmentStatus, string? due, Guid? shopId, int? page, int? pageSize, IMediator mediator) =>
        {
            var result = await mediator.Send(new GetKarigarOrdersQuery
            {
                Status = status,
                AssignmentStatus = assignmentStatus,
                Due = due,
                ShopId = shopId,
                Page = page ?? 1,
                PageSize = pageSize ?? 20
            });
            return ToResponse(result);
        })
        .WithName("GetKarigarOrders")
        .WithDescription("Get Karigar's assigned orders with optional status filter");
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
}
