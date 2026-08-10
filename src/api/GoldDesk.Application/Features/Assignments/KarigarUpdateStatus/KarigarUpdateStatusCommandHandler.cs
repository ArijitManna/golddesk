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

    public KarigarUpdateStatusCommandHandler(IApplicationDbContext context, ICurrentUserService currentUser, IMediator mediator)
    {
        _context = context;
        _currentUser = currentUser;
        _mediator = mediator;
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
            .FirstOrDefaultAsync(k => k.UserId == _currentUser.UserId, cancellationToken);

        if (karigar == null)
            return Result<bool>.Forbidden("You are not registered as a Karigar");

        var assignment = await _context.OrderAssignments
            .Include(a => a.Order)
            .FirstOrDefaultAsync(a =>
                a.OrderId == request.OrderId &&
                a.KarigarId == karigar.Id &&
                a.IsActive,
                cancellationToken);

        if (assignment == null)
            return Result<bool>.NotFound("No active assignment found for this order");

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

        await _context.SaveChangesAsync(cancellationToken);

        // Publish Ready notification event
        if (newStatus == OrderStatus.Ready)
        {
            var customer = await _context.Customers
                .IgnoreQueryFilters()
                .FirstOrDefaultAsync(c => c.Id == order.CustomerId, cancellationToken);

            await _mediator.Publish(new OrderStatusReadyEvent
            {
                TenantId = order.TenantId,
                OrderId = order.Id,
                OrderNo = order.OrderNo,
                CustomerName = customer?.Name ?? "Customer",
                KarigarName = karigar.Name
            }, cancellationToken);
        }

        return Result<bool>.Success(true);
    }
}
