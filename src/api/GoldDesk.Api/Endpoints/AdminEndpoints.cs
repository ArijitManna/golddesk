using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Admin.ApproveShop;
using GoldDesk.Application.Features.Admin.GetPendingRegistrations;
using GoldDesk.Application.Features.Admin.GetPlatformShopsReport;
using GoldDesk.Application.Features.Admin.RejectShop;
using GoldDesk.Application.Features.Admin.SetBusinessStatus;
using MediatR;

namespace GoldDesk.Api.Endpoints;

public static class AdminEndpoints
{
    public static void MapAdminEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/admin")
            .WithTags("Admin")
            .RequireAuthorization(policy => policy.RequireRole("SuperAdmin"));

        group.MapGet("/registrations/pending", async (string? search, string? businessType, IMediator mediator) =>
        {
            var result = await mediator.Send(new GetPendingRegistrationsQuery
            {
                Search = search,
                BusinessType = businessType
            });
            return ToResponse(result);
        })
        .WithName("GetPendingRegistrations")
        .WithDescription("Get pending registrations, optionally filtered by business type");

        group.MapPost("/registrations/{tenantId:guid}/approve", async (Guid tenantId, ApproveShopRequest? request, IMediator mediator) =>
        {
            var result = await mediator.Send(new ApproveShopCommand
            {
                TenantId = tenantId,
                AdminNote = request?.AdminNote
            });
            return ToResponse(result);
        })
        .WithName("ApproveShop")
        .WithDescription("Approve a pending shop registration");

        group.MapPost("/registrations/{tenantId:guid}/reject", async (Guid tenantId, RejectShopRequest request, IMediator mediator) =>
        {
            var result = await mediator.Send(new RejectShopCommand
            {
                TenantId = tenantId,
                Reason = request.Reason
            });
            return ToResponse(result);
        })
        .WithName("RejectShop")
        .WithDescription("Reject a pending shop registration");

        group.MapGet("/reports/shops", async (string? businessType, bool? includeInactive, IMediator mediator) =>
        {
            var result = await mediator.Send(new GetPlatformShopsReportQuery
            {
                BusinessType = businessType,
                IncludeInactive = includeInactive == true
            });
            return ToResponse(result);
        })
        .WithName("GetPlatformShopsReport")
        .WithDescription("Platform report: shops with karigar counts");

        group.MapPost("/businesses/{tenantId:guid}/deactivate", async (Guid tenantId, IMediator mediator) =>
        {
            var result = await mediator.Send(new DeactivateBusinessCommand { TenantId = tenantId });
            return ToResponse(result);
        })
        .WithName("DeactivateBusiness")
        .WithDescription("Inactivate an active shop, showroom, or karigar business");

        group.MapPost("/businesses/{tenantId:guid}/activate", async (Guid tenantId, IMediator mediator) =>
        {
            var result = await mediator.Send(new ActivateBusinessCommand { TenantId = tenantId });
            return ToResponse(result);
        })
        .WithName("ActivateBusiness")
        .WithDescription("Reactivate an inactive shop, showroom, or karigar business");
    }

    private static IResult ToResponse<T>(Result<T> result)
    {
        if (result.IsSuccess)
            return Results.Ok(result.Data);

        return result.StatusCode switch
        {
            404 => Results.NotFound(new { error = result.Error }),
            _ => Results.BadRequest(new { error = result.Error })
        };
    }
}

public record ApproveShopRequest
{
    public string? AdminNote { get; init; }
}

public record RejectShopRequest
{
    public string Reason { get; init; } = string.Empty;
}
