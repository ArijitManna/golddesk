using GoldDesk.Domain.Common;
using GoldDesk.Domain.Enums;

namespace GoldDesk.Domain.Entities;

/// <summary>
/// Platform-wide announcements created by SuperAdmin (push for now; more channels later).
/// </summary>
public class PlatformNotification : BaseEntity
{
    public PlatformNotificationType Type { get; set; } = PlatformNotificationType.Push;
    public string Title { get; set; } = string.Empty;
    public string Body { get; set; } = string.Empty;
    /// <summary>Public absolute URL used by FCM rich notifications.</summary>
    public string? ImageUrl { get; set; }
    /// <summary>Comma-separated audiences: Shop, Showroom, Karigar.</summary>
    public string TargetAudiences { get; set; } = "Shop,Showroom,Karigar";
    public DateTime? ScheduledAt { get; set; }
    public PlatformNotificationStatus Status { get; set; } = PlatformNotificationStatus.Scheduled;
    public DateTime? SentAt { get; set; }
    public int TargetCount { get; set; }
    public string? ErrorMessage { get; set; }
}
