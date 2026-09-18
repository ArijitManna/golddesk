using System.Security.Claims;
using GoldDesk.Domain.Entities;
using GoldDesk.Domain.Enums;
using GoldDesk.Infrastructure.Persistence;
using GoldDesk.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Api.Endpoints;

public static class PlatformNotificationEndpoints
{
    public static void MapPlatformNotificationEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/admin/platform-notifications")
            .WithTags("Platform Notifications")
            .RequireAuthorization(policy => policy.RequireRole("SuperAdmin"));

        group.MapGet("/", async (
            string? type,
            ApplicationDbContext db) =>
        {
            var query = db.PlatformNotifications.AsNoTracking().AsQueryable();

            if (!string.IsNullOrWhiteSpace(type) &&
                Enum.TryParse<PlatformNotificationType>(type, true, out var parsedType))
            {
                query = query.Where(n => n.Type == parsedType);
            }

            var rows = await query
                .OrderByDescending(n => n.CreatedAt)
                .Take(50)
                .Select(n => new
                {
                    id = n.Id,
                    type = n.Type.ToString(),
                    title = n.Title,
                    body = n.Body,
                    scheduledAt = n.ScheduledAt,
                    status = n.Status.ToString(),
                    sentAt = n.SentAt,
                    targetCount = n.TargetCount,
                    errorMessage = n.ErrorMessage,
                    createdAt = n.CreatedAt
                })
                .ToListAsync();

            return Results.Ok(rows);
        })
        .WithName("ListPlatformNotifications");

        group.MapPost("/", async (
            CreatePlatformNotificationRequest request,
            ClaimsPrincipal user,
            ApplicationDbContext db,
            PlatformNotificationDispatcher dispatcher) =>
        {
            var title = (request.Title ?? string.Empty).Trim();
            var body = (request.Body ?? string.Empty).Trim();

            if (string.IsNullOrWhiteSpace(title))
                return Results.BadRequest(new { error = "Title is required" });
            if (string.IsNullOrWhiteSpace(body))
                return Results.BadRequest(new { error = "Message body is required" });
            if (title.Length > 200)
                return Results.BadRequest(new { error = "Title max length is 200" });
            if (body.Length > 2000)
                return Results.BadRequest(new { error = "Body max length is 2000" });

            var type = PlatformNotificationType.Push;
            if (!string.IsNullOrWhiteSpace(request.Type) &&
                !Enum.TryParse(request.Type, true, out type))
            {
                return Results.BadRequest(new { error = "Unsupported notification type" });
            }

            if (type != PlatformNotificationType.Push)
                return Results.BadRequest(new { error = "Only Push is supported for now" });

            DateTime? scheduledAt = null;
            if (!string.IsNullOrWhiteSpace(request.ScheduledAt))
            {
                if (!DateTime.TryParse(
                        request.ScheduledAt,
                        null,
                        System.Globalization.DateTimeStyles.RoundtripKind,
                        out var parsed))
                {
                    return Results.BadRequest(new { error = "Invalid scheduledAt datetime" });
                }

                scheduledAt = parsed.Kind switch
                {
                    DateTimeKind.Utc => parsed,
                    DateTimeKind.Local => parsed.ToUniversalTime(),
                    _ => DateTime.SpecifyKind(parsed, DateTimeKind.Utc)
                };
            }

            var now = DateTime.UtcNow;
            var sendImmediately = scheduledAt == null || scheduledAt <= now.AddSeconds(30);

            var notification = new PlatformNotification
            {
                Type = type,
                Title = title,
                Body = body,
                ScheduledAt = scheduledAt ?? now,
                Status = PlatformNotificationStatus.Scheduled,
                CreatedBy = TryGetUserId(user)
            };

            db.PlatformNotifications.Add(notification);
            await db.SaveChangesAsync();

            if (sendImmediately)
            {
                await dispatcher.SendPushAsync(notification);
            }

            return Results.Ok(new
            {
                id = notification.Id,
                type = notification.Type.ToString(),
                title = notification.Title,
                body = notification.Body,
                scheduledAt = notification.ScheduledAt,
                status = notification.Status.ToString(),
                sentAt = notification.SentAt,
                targetCount = notification.TargetCount,
                errorMessage = notification.ErrorMessage,
                createdAt = notification.CreatedAt,
                message = sendImmediately
                    ? (notification.Status == PlatformNotificationStatus.Sent
                        ? $"Push sent to {notification.TargetCount} device(s)"
                        : "Push send failed")
                    : "Push scheduled"
            });
        })
        .WithName("CreatePlatformNotification");

        group.MapPost("/{id:guid}/cancel", async (
            Guid id,
            ApplicationDbContext db) =>
        {
            var row = await db.PlatformNotifications.FirstOrDefaultAsync(n => n.Id == id);
            if (row == null)
                return Results.NotFound(new { error = "Notification not found" });

            if (row.Status != PlatformNotificationStatus.Scheduled)
                return Results.BadRequest(new { error = "Only scheduled notifications can be cancelled" });

            row.Status = PlatformNotificationStatus.Cancelled;
            row.UpdatedAt = DateTime.UtcNow;
            await db.SaveChangesAsync();

            return Results.Ok(new { id = row.Id, status = row.Status.ToString(), message = "Cancelled" });
        })
        .WithName("CancelPlatformNotification");
    }

    private static Guid? TryGetUserId(ClaimsPrincipal user)
    {
        var raw = user.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? user.FindFirstValue("sub");
        return Guid.TryParse(raw, out var id) ? id : null;
    }
}

public record CreatePlatformNotificationRequest
{
    public string? Type { get; init; }
    public string? Title { get; init; }
    public string? Body { get; init; }
    /// <summary>ISO-8601 datetime. Null/empty = send immediately.</summary>
    public string? ScheduledAt { get; init; }
}
