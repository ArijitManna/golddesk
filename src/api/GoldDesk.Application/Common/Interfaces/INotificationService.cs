using GoldDesk.Domain.Enums;

namespace GoldDesk.Application.Common.Interfaces;

public interface INotificationService
{
    Task CreateNotificationAsync(
        Guid tenantId,
        Guid userId,
        Guid? orderId,
        NotificationType type,
        string title,
        string message,
        CancellationToken cancellationToken = default);

    Task CreateAndPushAsync(
        Guid tenantId,
        Guid userId,
        Guid? orderId,
        NotificationType type,
        string title,
        string message,
        CancellationToken cancellationToken = default);
}
