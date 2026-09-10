using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Domain.Entities;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Orders.CancelOrder;

public class CancelOrderCommandHandler : IRequestHandler<CancelOrderCommand, Result<bool>>
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;
    private readonly INotificationService _notifications;

    public CancelOrderCommandHandler(
        IApplicationDbContext context,
        ICurrentUserService currentUser,
        INotificationService notifications)
    {
        _context = context;
        _currentUser = currentUser;
        _notifications = notifications;
    }

    public async Task<Result<bool>> Handle(CancelOrderCommand request, CancellationToken cancellationToken)
    {
        var reason = request.Reason?.Trim();
        if (string.IsNullOrWhiteSpace(reason))
            return Result<bool>.Failure("Cancellation comment is required");

        // Do not ThenInclude Karigar here — Karigar tenant filter can hide
        // independent-Karigar assignments and leave them active after cancel.
        var order = await _context.Orders
            .FirstOrDefaultAsync(o => o.Id == request.OrderId, cancellationToken);

        if (order == null)
            return Result<bool>.NotFound("Order not found");

        if (_currentUser.TenantId != order.TenantId)
            return Result<bool>.Forbidden("Only the fulfilling Shop can cancel this order");

        if (order.Status == OrderStatus.Delivered || order.Status == OrderStatus.Closed)
            return Result<bool>.Failure("Cannot cancel a delivered or closed order");

        if (order.Status == OrderStatus.Cancelled)
            return Result<bool>.Failure("Order is already cancelled");

        var activeAssignments = await _context.OrderAssignments
            .IgnoreQueryFilters()
            .Include(a => a.Karigar)
            .Where(a => a.OrderId == order.Id && a.IsActive)
            .ToListAsync(cancellationToken);

        var previousStatus = order.Status;
        order.Status = OrderStatus.Cancelled;

        var karigarUserIds = activeAssignments
            .Where(a => a.Karigar.UserId.HasValue)
            .Select(a => a.Karigar.UserId!.Value)
            .Distinct()
            .ToList();

        foreach (var assignment in activeAssignments)
        {
            assignment.IsActive = false;
            assignment.Status = AssignmentStatus.Cancelled;
        }

        _context.OrderStatusHistory.Add(new OrderStatusHistory
        {
            OrderId = order.Id,
            FromStatus = previousStatus,
            ToStatus = OrderStatus.Cancelled,
            ChangedBy = _currentUser.UserId ?? Guid.Empty,
            Remarks = reason
        });

        _context.OrderEvents.Add(new OrderEvent
        {
            OrderId = order.Id,
            BusinessId = order.TenantId,
            UserId = _currentUser.UserId,
            EventType = "OrderCancelled",
            Description = $"Order cancelled: {reason}"
        });

        await _context.SaveChangesAsync(cancellationToken);

        foreach (var karigarUserId in karigarUserIds)
        {
            await _notifications.CreateAndPushAsync(
                order.TenantId,
                karigarUserId,
                order.Id,
                NotificationType.OrderCancelled,
                "Order cancelled",
                $"Order {order.OrderNo} was cancelled by the shop. Reason: {reason}",
                cancellationToken);
        }

        return Result<bool>.Success(true);
    }
}
