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

    public CancelOrderCommandHandler(IApplicationDbContext context, ICurrentUserService currentUser)
    {
        _context = context;
        _currentUser = currentUser;
    }

    public async Task<Result<bool>> Handle(CancelOrderCommand request, CancellationToken cancellationToken)
    {
        var order = await _context.Orders
            .Include(o => o.Assignments.Where(a => a.IsActive))
            .FirstOrDefaultAsync(o => o.Id == request.OrderId, cancellationToken);

        if (order == null)
            return Result<bool>.NotFound("Order not found");

        if (_currentUser.TenantId != order.TenantId)
            return Result<bool>.Forbidden("Only the fulfilling Shop can cancel this order");

        if (order.Status == OrderStatus.Delivered || order.Status == OrderStatus.Closed)
            return Result<bool>.Failure("Cannot cancel a delivered or closed order");

        if (order.Status == OrderStatus.Cancelled)
            return Result<bool>.Failure("Order is already cancelled");

        var previousStatus = order.Status;
        order.Status = OrderStatus.Cancelled;

        // Deactivate any active assignments
        foreach (var assignment in order.Assignments.Where(a => a.IsActive))
        {
            assignment.IsActive = false;
            assignment.Status = AssignmentStatus.Cancelled;
        }

        // Record status history
        _context.OrderStatusHistory.Add(new OrderStatusHistory
        {
            OrderId = order.Id,
            FromStatus = previousStatus,
            ToStatus = OrderStatus.Cancelled,
            ChangedBy = _currentUser.UserId ?? Guid.Empty,
            Remarks = request.Reason ?? "Order cancelled"
        });

        await _context.SaveChangesAsync(cancellationToken);

        return Result<bool>.Success(true);
    }
}
