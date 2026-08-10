using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Domain.Entities;
using GoldDesk.Domain.Enums;
using GoldDesk.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace GoldDesk.Infrastructure.Services;

public class NotificationService : INotificationService
{
    private readonly ApplicationDbContext _context;
    private readonly INotificationSender _pushSender;
    private readonly ILogger<NotificationService> _logger;

    public NotificationService(
        ApplicationDbContext context,
        INotificationSender pushSender,
        ILogger<NotificationService> logger)
    {
        _context = context;
        _pushSender = pushSender;
        _logger = logger;
    }

    public async Task CreateNotificationAsync(
        Guid tenantId,
        Guid userId,
        Guid? orderId,
        NotificationType type,
        string title,
        string message,
        CancellationToken cancellationToken = default)
    {
        var notification = new Notification
        {
            TenantId = tenantId,
            UserId = userId,
            OrderId = orderId,
            Type = type,
            Title = title,
            Message = message,
            IsRead = false
        };

        _context.Notifications.Add(notification);
        await _context.SaveChangesAsync(cancellationToken);
    }

    public async Task CreateAndPushAsync(
        Guid tenantId,
        Guid userId,
        Guid? orderId,
        NotificationType type,
        string title,
        string message,
        CancellationToken cancellationToken = default)
    {
        // Save in-app notification
        await CreateNotificationAsync(tenantId, userId, orderId, type, title, message, cancellationToken);

        // Send push notification
        try
        {
            var user = await _context.Users
                .IgnoreQueryFilters()
                .FirstOrDefaultAsync(u => u.Id == userId, cancellationToken);

            if (user?.FcmToken != null)
            {
                var data = new Dictionary<string, string>
                {
                    { "orderId", orderId?.ToString() ?? "" },
                    { "type", type.ToString() }
                };

                await _pushSender.SendPushNotificationAsync(user.FcmToken, title, message, data, cancellationToken);
                _logger.LogInformation("Push notification sent to user {UserId} for {Type}", userId, type);
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to send push notification to user {UserId}", userId);
            // Don't fail the operation if push fails
        }
    }
}
