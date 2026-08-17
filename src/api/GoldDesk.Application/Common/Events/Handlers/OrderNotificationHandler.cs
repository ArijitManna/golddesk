using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Common.Events.Handlers;

public class OrderAssignedNotificationHandler : INotificationHandler<OrderAssignedEvent>
{
    private readonly INotificationService _notificationService;

    public OrderAssignedNotificationHandler(INotificationService notificationService)
    {
        _notificationService = notificationService;
    }

    public async Task Handle(OrderAssignedEvent notification, CancellationToken cancellationToken)
    {
        await _notificationService.CreateAndPushAsync(
            notification.TenantId,
            notification.KarigarUserId,
            notification.OrderId,
            NotificationType.AssignmentCreated,
            "New Order Assigned",
            $"Order {notification.OrderNo} has been assigned to you. Due: {notification.DueDate}",
            cancellationToken);
    }
}

public class OrderStatusReadyNotificationHandler : INotificationHandler<OrderStatusReadyEvent>
{
    private readonly INotificationService _notificationService;
    private readonly IApplicationDbContext _context;

    public OrderStatusReadyNotificationHandler(INotificationService notificationService, IApplicationDbContext context)
    {
        _notificationService = notificationService;
        _context = context;
    }

    public async Task Handle(OrderStatusReadyEvent notification, CancellationToken cancellationToken)
    {
        // Notify shop owner(s) that order is ready
        var shopOwners = await _context.Users
            .IgnoreQueryFilters()
            .Where(u => u.TenantId == notification.TenantId &&
                u.Role == UserRole.ShopOwner &&
                u.Status == UserStatus.Active)
            .ToListAsync(cancellationToken);

        foreach (var owner in shopOwners)
        {
            await _notificationService.CreateAndPushAsync(
                notification.TenantId,
                owner.Id,
                notification.OrderId,
                NotificationType.StatusChangedToReady,
                "Order Ready",
                $"Order {notification.OrderNo} from {notification.OrderFromBusinessName} is marked work ready",
                cancellationToken);
        }
    }
}

public class OrderReassignedNotificationHandler : INotificationHandler<OrderReassignedEvent>
{
    private readonly INotificationService _notificationService;

    public OrderReassignedNotificationHandler(INotificationService notificationService)
    {
        _notificationService = notificationService;
    }

    public async Task Handle(OrderReassignedEvent notification, CancellationToken cancellationToken)
    {
        await _notificationService.CreateAndPushAsync(
            notification.TenantId,
            notification.NewKarigarUserId,
            notification.OrderId,
            NotificationType.OrderReassigned,
            "Order Assigned to You",
            $"Order {notification.OrderNo} has been reassigned to you",
            cancellationToken);
    }
}
