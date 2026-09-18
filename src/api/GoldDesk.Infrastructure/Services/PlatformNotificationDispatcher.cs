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
            var audiences = ParseAudiences(notification.TargetAudiences);
            var tokens = await ResolveTokensAsync(audiences, cancellationToken);

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
                    notification.ImageUrl,
                    cancellationToken);
            }

            notification.Status = PlatformNotificationStatus.Sent;
            notification.SentAt = DateTime.UtcNow;
            notification.ErrorMessage = null;
            notification.UpdatedAt = DateTime.UtcNow;
            await _db.SaveChangesAsync(cancellationToken);

            _logger.LogInformation(
                "Platform push {Id} sent to {Count} device(s) for audiences [{Audiences}]",
                notification.Id,
                notification.TargetCount,
                notification.TargetAudiences);
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

    private async Task<List<string>> ResolveTokensAsync(
        HashSet<string> audiences,
        CancellationToken cancellationToken)
    {
        if (audiences.Count == 0)
            return [];

        var targetShop = audiences.Contains("Shop");
        var targetShowroom = audiences.Contains("Showroom");
        var targetKarigar = audiences.Contains("Karigar");

        var query = _db.Users
            .IgnoreQueryFilters()
            .AsNoTracking()
            .Where(u =>
                u.FcmToken != null &&
                u.FcmToken != "" &&
                u.Role != UserRole.SuperAdmin &&
                u.Status == UserStatus.Active);

        query = query.Where(u =>
            (targetKarigar &&
             (u.Role == UserRole.Karigar || u.Tenant.BusinessType == BusinessType.Karigar))
            ||
            (targetShop &&
             u.Role != UserRole.Karigar &&
             u.Tenant.BusinessType == BusinessType.Shop)
            ||
            (targetShowroom &&
             u.Role != UserRole.Karigar &&
             u.Tenant.BusinessType == BusinessType.Showroom));

        return await query
            .Select(u => u.FcmToken!)
            .Distinct()
            .ToListAsync(cancellationToken);
    }

    public static HashSet<string> ParseAudiences(string? raw)
    {
        var canonical = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
        {
            ["Shop"] = "Shop",
            ["Showroom"] = "Showroom",
            ["Karigar"] = "Karigar"
        };

        if (string.IsNullOrWhiteSpace(raw))
            return new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        var result = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (var part in raw.Split(
                     [',', ';', '|'],
                     StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
        {
            if (canonical.TryGetValue(part, out var name))
                result.Add(name);
        }

        return result;
    }

    public static string NormalizeAudiences(IEnumerable<string> audiences)
    {
        var set = ParseAudiences(string.Join(",", audiences));
        var ordered = new[] { "Shop", "Showroom", "Karigar" }
            .Where(a => set.Contains(a));
        return string.Join(",", ordered);
    }
}
