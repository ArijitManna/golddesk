using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Domain.Entities;
using GoldDesk.Domain.Enums;
using GoldDesk.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace GoldDesk.Infrastructure.Services;

public class PlatformNotificationDispatcher
{
    private readonly ApplicationDbContext _db;
    private readonly INotificationSender _pushSender;
    private readonly ILogger<PlatformNotificationDispatcher> _logger;

    public PlatformNotificationDispatcher(
        ApplicationDbContext db,
        INotificationSender pushSender,
        ILogger<PlatformNotificationDispatcher> logger)
    {
        _db = db;
        _pushSender = pushSender;
        _logger = logger;
    }

    public async Task DispatchDueAsync(CancellationToken cancellationToken = default)
    {
        var now = DateTime.UtcNow;
        var due = await _db.PlatformNotifications
            .Where(n =>
                n.Status == PlatformNotificationStatus.Scheduled &&
                n.Type == PlatformNotificationType.Push &&
                (n.ScheduledAt == null || n.ScheduledAt <= now))
            .OrderBy(n => n.ScheduledAt ?? n.CreatedAt)
            .Take(20)
            .ToListAsync(cancellationToken);

        foreach (var notification in due)
        {
            await SendPushAsync(notification, cancellationToken);
        }
    }

    public async Task SendPushAsync(
        PlatformNotification notification,
        CancellationToken cancellationToken = default)
    {
        notification.Status = PlatformNotificationStatus.Sending;
        notification.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync(cancellationToken);

        try
        {
            var tokens = await _db.Users
                .IgnoreQueryFilters()
                .Where(u => u.FcmToken != null && u.FcmToken != "")
                .Select(u => u.FcmToken!)
                .Distinct()
                .ToListAsync(cancellationToken);

            notification.TargetCount = tokens.Count;

            if (tokens.Count > 0)
            {
                var data = new Dictionary<string, string>
                {
                    ["type"] = "PlatformAnnouncement",
                    ["platformNotificationId"] = notification.Id.ToString()
                };

                await _pushSender.SendPushToMultipleAsync(
                    tokens,
                    notification.Title,
                    notification.Body,
                    data,
                    cancellationToken);
            }

            notification.Status = PlatformNotificationStatus.Sent;
            notification.SentAt = DateTime.UtcNow;
            notification.ErrorMessage = null;
            notification.UpdatedAt = DateTime.UtcNow;
            await _db.SaveChangesAsync(cancellationToken);

            _logger.LogInformation(
                "Platform push {Id} sent to {Count} device(s)",
                notification.Id,
                notification.TargetCount);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send platform push {Id}", notification.Id);
            notification.Status = PlatformNotificationStatus.Failed;
            notification.ErrorMessage = ex.Message.Length > 1000
                ? ex.Message[..1000]
                : ex.Message;
            notification.UpdatedAt = DateTime.UtcNow;
            await _db.SaveChangesAsync(cancellationToken);
        }
    }
}
