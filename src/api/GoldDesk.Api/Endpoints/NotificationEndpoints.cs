using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Notifications.GetNotifications;
using GoldDesk.Application.Features.Notifications.GetUnreadCount;
using GoldDesk.Application.Features.Notifications.MarkAsRead;
using GoldDesk.Domain.Enums;
using MediatR;

namespace GoldDesk.Api.Endpoints;

public static class NotificationEndpoints
{
    public static void MapNotificationEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/notifications")
            .WithTags("Notifications")
            .RequireAuthorization();

        group.MapGet("/", async (bool? unreadOnly, int? page, int? pageSize, IMediator mediator) =>
        {
            var result = await mediator.Send(new GetNotificationsQuery
            {
                UnreadOnly = unreadOnly,
                Page = page ?? 1,
                PageSize = pageSize ?? 20
            });
            return Results.Ok(result.Data);
        })
        .WithName("GetNotifications")
        .WithDescription("Get user's notifications with optional unread filter");

        group.MapGet("/unread-count", async (
            string? type,
            Guid? orderId,
            IMediator mediator) =>
        {
            NotificationType? parsedType = null;
            if (!string.IsNullOrWhiteSpace(type) &&
                Enum.TryParse<NotificationType>(type, true, out var value))
            {
                parsedType = value;
            }

            var result = await mediator.Send(new GetUnreadCountQuery
            {
                Type = parsedType,
                OrderId = orderId
            });
            return Results.Ok(new { count = result.Data });
        })
        .WithName("GetUnreadCount")
        .WithDescription("Get count of unread notifications, optionally filtered by type/order");

        group.MapPost("/{id:guid}/read", async (Guid id, IMediator mediator) =>
        {
            var result = await mediator.Send(new MarkNotificationReadCommand(id));
            return result.IsSuccess
                ? Results.Ok(new { message = "Marked as read" })
                : Results.NotFound(new { error = result.Error });
        })
        .WithName("MarkNotificationRead")
        .WithDescription("Mark a single notification as read");

        group.MapPost("/read-all", async (IMediator mediator) =>
        {
            var result = await mediator.Send(new MarkAllNotificationsReadCommand());
            return Results.Ok(new { message = $"{result.Data} notifications marked as read" });
        })
        .WithName("MarkAllRead")
        .WithDescription("Mark all notifications as read");

        group.MapPost("/orders/{orderId:guid}/comments/read", async (Guid orderId, IMediator mediator) =>
        {
            var result = await mediator.Send(new MarkOrderCommentNotificationsReadCommand(orderId));
            return Results.Ok(new { message = $"{result.Data} message notifications marked as read" });
        })
        .WithName("MarkOrderCommentNotificationsRead")
        .WithDescription("Mark unread CommentAdded notifications for an order as read");
    }
}
