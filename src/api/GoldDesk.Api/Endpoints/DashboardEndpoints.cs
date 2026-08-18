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

        karigarGroup.MapGet("/orders", async (string? status, string? assignmentStatus, string? due, int? page, int? pageSize, IMediator mediator) =>
        {
            var result = await mediator.Send(new GetKarigarOrdersQuery
            {
                Status = status,
                AssignmentStatus = assignmentStatus,
                Due = due,
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
