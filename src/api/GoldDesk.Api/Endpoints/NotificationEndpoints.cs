using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Notifications.GetNotifications;
using GoldDesk.Application.Features.Notifications.GetUnreadCount;
using GoldDesk.Application.Features.Notifications.MarkAsRead;
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

        group.MapGet("/unread-count", async (IMediator mediator) =>
        {
            var result = await mediator.Send(new GetUnreadCountQuery());
            return Results.Ok(new { count = result.Data });
        })
        .WithName("GetUnreadCount")
        .WithDescription("Get count of unread notifications");

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
    }
}
