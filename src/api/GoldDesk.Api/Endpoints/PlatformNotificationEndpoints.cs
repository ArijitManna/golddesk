using System.Security.Claims;
using GoldDesk.Domain.Entities;
using GoldDesk.Domain.Enums;
using GoldDesk.Infrastructure.Persistence;
using GoldDesk.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Api.Endpoints;

public static class PlatformNotificationEndpoints
{
    private const long MaxImageBytes = 5L * 1024 * 1024; // 5 MB
    private static readonly HashSet<string> AllowedImageExtensions = new(StringComparer.OrdinalIgnoreCase)
    {
        ".jpg", ".jpeg", ".png", ".webp", ".gif"
    };

    public static void MapPlatformNotificationEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/admin/platform-notifications")
            .WithTags("Platform Notifications")
            .RequireAuthorization(policy => policy.RequireRole("SuperAdmin"));

        group.MapGet("/", async (
            HttpContext httpContext,
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
                .ToListAsync();

            var result = rows.Select(n => new
            {
                id = n.Id,
                type = n.Type.ToString(),
                title = n.Title,
                body = n.Body,
                imageUrl = ResolvePublicImageUrl(httpContext, n.ImageUrl),
                scheduledAt = n.ScheduledAt,
                status = n.Status.ToString(),
                sentAt = n.SentAt,
                targetCount = n.TargetCount,
                errorMessage = n.ErrorMessage,
                createdAt = n.CreatedAt
            });

            return Results.Ok(result);
        })
        .WithName("ListPlatformNotifications");

        group.MapPost("/", async (
            HttpContext httpContext,
            ClaimsPrincipal user,
            IWebHostEnvironment environment,
            ApplicationDbContext db,
            PlatformNotificationDispatcher dispatcher,
            [Microsoft.AspNetCore.Mvc.FromForm] string? type,
            [Microsoft.AspNetCore.Mvc.FromForm] string? title,
            [Microsoft.AspNetCore.Mvc.FromForm] string? body,
            [Microsoft.AspNetCore.Mvc.FromForm] string? scheduledAt,
            IFormFile? image) =>
        {
            title = (title ?? string.Empty).Trim();
            body = (body ?? string.Empty).Trim();

            if (string.IsNullOrWhiteSpace(title))
                return Results.BadRequest(new { error = "Title is required" });
            if (string.IsNullOrWhiteSpace(body))
                return Results.BadRequest(new { error = "Message body is required" });
            if (title.Length > 200)
                return Results.BadRequest(new { error = "Title max length is 200" });
            if (body.Length > 2000)
                return Results.BadRequest(new { error = "Body max length is 2000" });

            var parsedType = PlatformNotificationType.Push;
            if (!string.IsNullOrWhiteSpace(type) &&
                !Enum.TryParse(type, true, out parsedType))
            {
                return Results.BadRequest(new { error = "Unsupported notification type" });
            }

            if (parsedType != PlatformNotificationType.Push)
                return Results.BadRequest(new { error = "Only Push is supported for now" });

            DateTime? scheduleUtc = null;
            if (!string.IsNullOrWhiteSpace(scheduledAt))
            {
                if (!DateTime.TryParse(
                        scheduledAt,
                        null,
                        System.Globalization.DateTimeStyles.RoundtripKind,
                        out var parsed))
                {
                    return Results.BadRequest(new { error = "Invalid scheduledAt datetime" });
                }

                scheduleUtc = parsed.Kind switch
                {
                    DateTimeKind.Utc => parsed,
                    DateTimeKind.Local => parsed.ToUniversalTime(),
                    _ => DateTime.SpecifyKind(parsed, DateTimeKind.Utc)
                };
            }

            string? imageUrl = null;
            if (image != null && image.Length > 0)
            {
                var saved = await SaveImageAsync(httpContext, environment, image);
                if (saved.Error != null)
                    return Results.BadRequest(new { error = saved.Error });
                imageUrl = saved.AbsoluteUrl;
            }

            var now = DateTime.UtcNow;
            var sendImmediately = scheduleUtc == null || scheduleUtc <= now.AddSeconds(30);

            var notification = new PlatformNotification
            {
                Type = parsedType,
                Title = title,
                Body = body,
                ImageUrl = imageUrl,
                ScheduledAt = scheduleUtc ?? now,
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
                imageUrl = notification.ImageUrl,
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
        .DisableAntiforgery()
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

    private static async Task<(string? AbsoluteUrl, string? Error)> SaveImageAsync(
        HttpContext httpContext,
        IWebHostEnvironment environment,
        IFormFile image)
    {
        if (image.Length > MaxImageBytes)
            return (null, "Image exceeds 5MB limit");

        var ext = Path.GetExtension(image.FileName);
        if (string.IsNullOrWhiteSpace(ext) || !AllowedImageExtensions.Contains(ext))
            return (null, "Only JPG, PNG, WEBP, or GIF images are allowed");

        var contentType = image.ContentType?.ToLowerInvariant() ?? "";
        if (!string.IsNullOrEmpty(contentType) &&
            !contentType.StartsWith("image/", StringComparison.OrdinalIgnoreCase))
        {
            return (null, "File must be an image");
        }

        var folder = Path.Combine(environment.ContentRootPath, "uploads", "platform-notifications");
        Directory.CreateDirectory(folder);

        var fileName = $"{Guid.NewGuid():N}{ext.ToLowerInvariant()}";
        var filePath = Path.Combine(folder, fileName);
        await using (var stream = File.Create(filePath))
        {
            await image.CopyToAsync(stream);
        }

        var relative = $"/uploads/platform-notifications/{fileName}";
        var absolute = $"{httpContext.Request.Scheme}://{httpContext.Request.Host}{relative}";
        return (absolute, null);
    }

    private static string? ResolvePublicImageUrl(HttpContext httpContext, string? stored)
    {
        if (string.IsNullOrWhiteSpace(stored))
            return null;
        if (stored.StartsWith("http://", StringComparison.OrdinalIgnoreCase) ||
            stored.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
            return stored;
        if (stored.StartsWith('/'))
            return $"{httpContext.Request.Scheme}://{httpContext.Request.Host}{stored}";
        return stored;
    }

    private static Guid? TryGetUserId(ClaimsPrincipal user)
    {
        var raw = user.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? user.FindFirstValue("sub");
        return Guid.TryParse(raw, out var id) ? id : null;
    }
}
