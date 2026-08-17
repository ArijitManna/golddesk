using GoldDesk.Application.Common.Events;
using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Domain.Entities;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Assignments.KarigarUpdateStatus;

public class KarigarUpdateStatusCommandHandler : IRequestHandler<KarigarUpdateStatusCommand, Result<bool>>
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;
    private readonly IMediator _mediator;
    private readonly INotificationService _notifications;

    public KarigarUpdateStatusCommandHandler(
        IApplicationDbContext context,
        ICurrentUserService currentUser,
        IMediator mediator,
        INotificationService notifications)
    {
        _context = context;
        _currentUser = currentUser;
        _mediator = mediator;
        _notifications = notifications;
    }

    public async Task<Result<bool>> Handle(KarigarUpdateStatusCommand request, CancellationToken cancellationToken)
    {
        if (!Enum.TryParse<OrderStatus>(request.Status, true, out var newStatus))
            return Result<bool>.Failure($"Invalid status: {request.Status}");

        // Karigar can only set InProgress or Ready
        if (newStatus != OrderStatus.InProgress && newStatus != OrderStatus.Ready)
            return Result<bool>.Failure("Karigar can only update status to 'InProgress' or 'Ready'");

        // Find the active assignment for this order belonging to this Karigar
        var karigar = await _context.Karigars
            .IgnoreQueryFilters()
            .FirstOrDefaultAsync(k => k.UserId == _currentUser.UserId, cancellationToken);

        if (karigar == null)
            return Result<bool>.Forbidden("You are not registered as a Karigar");

        var assignment = await _context.OrderAssignments
            .IgnoreQueryFilters()
            .Include(a => a.Order)
                .ThenInclude(o => o.OrderFromBusiness)
            .Include(a => a.Order)
                .ThenInclude(o => o.OrderFromExternalBusiness)
            .FirstOrDefaultAsync(a =>
                a.OrderId == request.OrderId &&
                a.KarigarId == karigar.Id &&
                a.IsActive,
                cancellationToken);

        if (assignment == null)
            return Result<bool>.NotFound("No active assignment found for this order");

        if (assignment.Status == AssignmentStatus.PendingAcceptance)
            return Result<bool>.Failure("Accept this work before updating its progress.");

        var order = assignment.Order;
        var previousStatus = order.Status;

        // Validate transition
        if (newStatus == OrderStatus.InProgress && order.Status != OrderStatus.Assigned && order.Status != OrderStatus.InProgress)
            return Result<bool>.Failure("Can only mark 'In Progress' when order is Assigned");

        if (newStatus == OrderStatus.Ready && order.Status != OrderStatus.InProgress)
            return Result<bool>.Failure("Can only mark 'Ready' when order is In Progress");

        order.Status = newStatus;

        // Update assignment status if Ready
        if (newStatus == OrderStatus.Ready)
        {
            assignment.Status = AssignmentStatus.Completed;
        }

        _context.OrderStatusHistory.Add(new OrderStatusHistory
        {
            OrderId = order.Id,
            FromStatus = previousStatus,
            ToStatus = newStatus,
            ChangedBy = _currentUser.UserId ?? Guid.Empty,
            Remarks = request.ProgressNotes ?? $"Status updated to {newStatus} by Karigar"
        });
        _context.OrderEvents.Add(new OrderEvent
        {
            OrderId = order.Id,
            BusinessId = karigar.TenantId,
            UserId = _currentUser.UserId,
            EventType = newStatus == OrderStatus.Ready ? "WorkReady" : "MakingStarted",
            Description = request.ProgressNotes ??
                          (newStatus == OrderStatus.Ready
                              ? "Karigar marked work ready"
                              : "Karigar started making")
        });

        await _context.SaveChangesAsync(cancellationToken);

        if (newStatus == OrderStatus.InProgress)
        {
            var shopOwnerIds = await _context.Users
                .IgnoreQueryFilters()
                .Where(u => u.TenantId == order.TenantId &&
                            u.Role == UserRole.ShopOwner &&
                            u.Status == UserStatus.Active)
                .Select(u => u.Id)
                .ToListAsync(cancellationToken);

            foreach (var shopOwnerId in shopOwnerIds)
            {
                await _notifications.CreateAndPushAsync(
                    order.TenantId,
                    shopOwnerId,
                    order.Id,
                    NotificationType.WorkStarted,
                    "Work started",
                    $"{karigar.Name} started work on order {order.OrderNo}.",
                    cancellationToken);
            }
        }

        // Publish Ready notification event
        if (newStatus == OrderStatus.Ready)
        {
            await _mediator.Publish(new OrderStatusReadyEvent
            {
                TenantId = order.TenantId,
                OrderId = order.Id,
                OrderNo = order.OrderNo,
                OrderFromBusinessName = order.OrderFromBusiness?.ShopName ??
                                        order.OrderFromExternalBusiness?.Name ??
                                        "business order",
                KarigarName = karigar.Name
            }, cancellationToken);
        }

        return Result<bool>.Success(true);
    }
}
