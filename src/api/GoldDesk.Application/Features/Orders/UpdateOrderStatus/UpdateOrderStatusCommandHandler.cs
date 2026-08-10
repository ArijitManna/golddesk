using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Domain.Entities;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Orders.UpdateOrderStatus;

public class UpdateOrderStatusCommandHandler : IRequestHandler<UpdateOrderStatusCommand, Result<bool>>
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;

    public UpdateOrderStatusCommandHandler(IApplicationDbContext context, ICurrentUserService currentUser)
    {
        _context = context;
        _currentUser = currentUser;
    }

    public async Task<Result<bool>> Handle(UpdateOrderStatusCommand request, CancellationToken cancellationToken)
    {
        if (!Enum.TryParse<OrderStatus>(request.Status, true, out var newStatus))
            return Result<bool>.Failure($"Invalid status: {request.Status}");

        var order = await _context.Orders
            .FirstOrDefaultAsync(o => o.Id == request.OrderId, cancellationToken);

        if (order == null)
            return Result<bool>.NotFound("Order not found");

        // Validate status transitions
        var validTransition = IsValidTransition(order.Status, newStatus);
        if (!validTransition)
            return Result<bool>.Failure($"Cannot change status from '{order.Status}' to '{newStatus}'");

        var previousStatus = order.Status;
        order.Status = newStatus;

        _context.OrderStatusHistory.Add(new OrderStatusHistory
        {
            OrderId = order.Id,
            FromStatus = previousStatus,
            ToStatus = newStatus,
            ChangedBy = _currentUser.UserId ?? Guid.Empty,
            Remarks = request.Remarks
        });

        await _context.SaveChangesAsync(cancellationToken);

        return Result<bool>.Success(true);
    }

    private static bool IsValidTransition(OrderStatus current, OrderStatus next)
    {
        return (current, next) switch
        {
            (OrderStatus.Pending, OrderStatus.Assigned) => true,
            (OrderStatus.Pending, OrderStatus.Cancelled) => true,
            (OrderStatus.Assigned, OrderStatus.InProgress) => true,
            (OrderStatus.Assigned, OrderStatus.Cancelled) => true,
            (OrderStatus.InProgress, OrderStatus.Ready) => true,
            (OrderStatus.InProgress, OrderStatus.Cancelled) => true,
            (OrderStatus.Ready, OrderStatus.Delivered) => true,
            (OrderStatus.Delivered, OrderStatus.Closed) => true,
            _ => false
        };
    }
}
