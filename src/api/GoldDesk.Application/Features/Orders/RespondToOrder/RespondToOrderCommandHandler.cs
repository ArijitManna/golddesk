using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Orders.Dtos;
using GoldDesk.Domain.Entities;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Orders.RespondToOrder;

public class RespondToOrderCommandHandler : IRequestHandler<RespondToOrderCommand, Result<OrderDto>>
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;
    private readonly INotificationService _notifications;

    public RespondToOrderCommandHandler(
        IApplicationDbContext context,
        ICurrentUserService currentUser,
        INotificationService notifications)
    {
        _context = context;
        _currentUser = currentUser;
        _notifications = notifications;
    }

    public async Task<Result<OrderDto>> Handle(RespondToOrderCommand request, CancellationToken cancellationToken)
    {
        if (!_currentUser.TenantId.HasValue)
            return Result<OrderDto>.Unauthorized();

        var order = await _context.Orders
            .Include(o => o.CreatedByBusiness)
            .Include(o => o.OrderFromBusiness)
            .Include(o => o.OrderFromExternalBusiness)
            .Include(o => o.Tenant)
            .FirstOrDefaultAsync(o => o.Id == request.OrderId, cancellationToken);

        if (order == null)
            return Result<OrderDto>.NotFound("Order not found.");

        if (order.TenantId != _currentUser.TenantId.Value)
            return Result<OrderDto>.Forbidden("Only the receiving Shop can accept or reject this order.");

        if (order.AcceptanceStatus != OrderAcceptanceStatus.Pending)
            return Result<OrderDto>.Failure($"This order has already been {order.AcceptanceStatus.ToString().ToLowerInvariant()}.");

        order.AcceptanceStatus = request.Accept
            ? OrderAcceptanceStatus.Accepted
            : OrderAcceptanceStatus.Rejected;
        order.AcceptanceNote = request.Note;

        if (request.Accept)
            order.AcceptedAt = DateTime.UtcNow;
        else
        {
            order.RejectedAt = DateTime.UtcNow;
            order.Status = OrderStatus.Cancelled;
        }

        _context.OrderEvents.Add(new OrderEvent
        {
            OrderId = order.Id,
            BusinessId = _currentUser.TenantId.Value,
            UserId = _currentUser.UserId,
            EventType = request.Accept ? "OrderAccepted" : "OrderRejected",
            Description = request.Accept
                ? "Receiving Shop accepted the order"
                : "Receiving Shop rejected the order"
        });
        await _context.SaveChangesAsync(cancellationToken);

        await NotifyCreatorAsync(order, request.Accept, cancellationToken);

        return Result<OrderDto>.Success(new OrderDto
        {
            Id = order.Id,
            OrderNo = order.OrderNo,
            OrderFromBusinessId = order.OrderFromBusinessId,
            OrderFromExternalBusinessId = order.OrderFromExternalBusinessId,
            OrderFromBusinessName = order.OrderFromBusiness?.ShopName ??
                                    order.OrderFromExternalBusiness?.Name ??
                                    string.Empty,
            OrderDate = order.OrderDate.ToString("yyyy-MM-dd"),
            DeliveryDate = order.DeliveryDate?.ToString("yyyy-MM-dd"),
            Status = order.Status.ToString(),
            AcceptanceStatus = order.AcceptanceStatus.ToString(),
            AcceptanceNote = order.AcceptanceNote,
            TotalWeight = order.TotalWeight,
            MakingCharges = order.MakingCharges,
            AdvancePaid = order.AdvancePaid,
            EstimatedAmount = order.EstimatedAmount,
            Notes = order.Notes,
            Source = order.Source.ToString(),
            CreatedByBusinessId = order.CreatedByBusinessId,
            CreatedByBusinessName = order.CreatedByBusiness.ShopName,
            CreatedForBusinessId = order.TenantId,
            CreatedForBusinessName = order.Tenant.ShopName,
            CreatedAt = order.CreatedAt
        });
    }

    private async Task NotifyCreatorAsync(Order order, bool accepted, CancellationToken cancellationToken)
    {
        // Notify the business that created the order (usually Showroom), not the Shop itself.
        if (order.CreatedByBusinessId == order.TenantId)
            return;

        var recipientIds = await _context.Users
            .IgnoreQueryFilters()
            .Where(u => u.TenantId == order.CreatedByBusinessId && u.Status == UserStatus.Active)
            .Select(u => u.Id)
            .ToListAsync(cancellationToken);

        var shopName = order.Tenant.ShopName;
        var title = accepted ? "Order accepted" : "Order rejected";
        var message = accepted
            ? $"{shopName} accepted order {order.OrderNo}."
            : $"{shopName} rejected order {order.OrderNo}.";
        var type = accepted ? NotificationType.OrderAccepted : NotificationType.OrderRejected;

        foreach (var recipientId in recipientIds)
        {
            await _notifications.CreateAndPushAsync(
                order.CreatedByBusinessId,
                recipientId,
                order.Id,
                type,
                title,
                message,
                cancellationToken);
        }
    }
}
