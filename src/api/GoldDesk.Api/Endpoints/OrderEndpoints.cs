using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Assignments.AssignKarigar;
using GoldDesk.Application.Features.Assignments.GetAssignmentHistory;
using GoldDesk.Application.Features.Assignments.KarigarUpdateStatus;
using GoldDesk.Application.Features.Orders.CancelOrder;
using GoldDesk.Application.Features.Orders.CreateOrder;
using GoldDesk.Application.Features.Orders.GetOrderById;
using GoldDesk.Application.Features.Orders.GetOrders;
using GoldDesk.Application.Features.Orders.UpdateOrder;
using GoldDesk.Application.Features.Orders.UpdateOrderStatus;
using MediatR;

namespace GoldDesk.Api.Endpoints;

public static class OrderEndpoints
{
    public static void MapOrderEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/orders")
            .WithTags("Orders")
            .RequireAuthorization();

        group.MapGet("/", async (string? status, string? due, string? search, int? page, int? pageSize, IMediator mediator) =>
        {
            var result = await mediator.Send(new GetOrdersQuery
            {
                Status = status,
                Due = due,
                Search = search,
                Page = page ?? 1,
                PageSize = pageSize ?? 20
            });
            return ToResponse(result);
        })
        .WithName("GetOrders");

        group.MapGet("/{id:guid}", async (Guid id, IMediator mediator) =>
        {
            var result = await mediator.Send(new GetOrderByIdQuery(id));
            return ToResponse(result);
        })
        .WithName("GetOrderById");

        group.MapPost("/", async (CreateOrderCommand command, IMediator mediator) =>
        {
            var result = await mediator.Send(command);
            return result.IsSuccess
                ? Results.Created($"/api/orders/{result.Data!.Id}", result.Data)
                : ToErrorResponse(result);
        })
        .WithName("CreateOrder");

        group.MapPut("/{id:guid}", async (Guid id, UpdateOrderCommand command, IMediator mediator) =>
        {
            var result = await mediator.Send(command with { OrderId = id });
            return result.IsSuccess
                ? Results.Ok(result.Data)
                : ToErrorResponse(result);
        })
        .WithName("UpdateOrder");

        group.MapPost("/{id:guid}/update", async (Guid id, UpdateOrderCommand command, IMediator mediator) =>
        {
            var result = await mediator.Send(command with { OrderId = id });
            return result.IsSuccess
                ? Results.Ok(result.Data)
                : ToErrorResponse(result);
        })
        .WithName("UpdateOrderPost");

        group.MapPost("/{id:guid}/cancel", async (Guid id, CancelOrderRequest? request, IMediator mediator) =>
        {
            var result = await mediator.Send(new CancelOrderCommand
            {
                OrderId = id,
                Reason = request?.Reason
            });
            return result.IsSuccess
                ? Results.Ok(new { message = "Order cancelled" })
                : ToErrorResponse(result);
        })
        .WithName("CancelOrder");

        group.MapPost("/{id:guid}/status", async (Guid id, UpdateStatusRequest request, IMediator mediator) =>
        {
            var result = await mediator.Send(new UpdateOrderStatusCommand
            {
                OrderId = id,
                Status = request.Status,
                Remarks = request.Remarks
            });
            return result.IsSuccess
                ? Results.Ok(new { message = $"Status updated to {request.Status}" })
                : ToErrorResponse(result);
        })
        .WithName("UpdateOrderStatus");

        // Assignment endpoints
        group.MapPost("/{id:guid}/assign", async (Guid id, AssignKarigarRequest request, IMediator mediator) =>
        {
            var result = await mediator.Send(new AssignKarigarCommand
            {
                OrderId = id,
                KarigarId = request.KarigarId,
                GivenDate = request.GivenDate,
                DueDate = request.DueDate,
                Notes = request.Notes
            });
            return result.IsSuccess
                ? Results.Created($"/api/orders/{id}/assignments", result.Data)
                : ToErrorResponse(result);
        })
        .WithName("AssignKarigar");

        group.MapGet("/{id:guid}/assignments", async (Guid id, IMediator mediator) =>
        {
            var result = await mediator.Send(new GetAssignmentHistoryQuery(id));
            return ToResponse(result);
        })
        .WithName("GetAssignmentHistory");

        // Karigar status update
        group.MapPost("/{id:guid}/karigar-update", async (Guid id, KarigarStatusUpdateRequest request, IMediator mediator) =>
        {
            var result = await mediator.Send(new KarigarUpdateStatusCommand
            {
                OrderId = id,
                Status = request.Status,
                ProgressNotes = request.ProgressNotes
            });
            return result.IsSuccess
                ? Results.Ok(new { message = $"Status updated to {request.Status}" })
                : ToErrorResponse(result);
        })
        .WithName("KarigarUpdateStatus")
        .RequireAuthorization(policy => policy.RequireRole("Karigar", "ShopOwner"));
    }

    private static IResult ToResponse<T>(Result<T> result)
    {
        if (result.IsSuccess) return Results.Ok(result.Data);
        return result.StatusCode switch
        {
            404 => Results.NotFound(new { error = result.Error }),
            403 => Results.Json(new { error = result.Error }, statusCode: 403),
            _ => Results.BadRequest(new { error = result.Error })
        };
    }

    private static IResult ToErrorResponse<T>(Result<T> result)
    {
        return result.StatusCode switch
        {
            404 => Results.NotFound(new { error = result.Error }),
            403 => Results.Json(new { error = result.Error }, statusCode: 403),
            409 => Results.Conflict(new { error = result.Error }),
            _ => Results.BadRequest(new { error = result.Error })
        };
    }
}

public record CancelOrderRequest
{
    public string? Reason { get; init; }
}

public record UpdateStatusRequest
{
    public string Status { get; init; } = string.Empty;
    public string? Remarks { get; init; }
}

public record AssignKarigarRequest
{
    public Guid KarigarId { get; init; }
    public string GivenDate { get; init; } = string.Empty;
    public string DueDate { get; init; } = string.Empty;
    public string? Notes { get; init; }
}

public record KarigarStatusUpdateRequest
{
    public string Status { get; init; } = string.Empty;
    public string? ProgressNotes { get; init; }
}
