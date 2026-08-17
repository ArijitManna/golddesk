using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Orders.Dtos;
using GoldDesk.Domain.Entities;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Orders.CreateOrder;

public class CreateOrderCommandHandler : IRequestHandler<CreateOrderCommand, Result<OrderDto>>
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;

    public CreateOrderCommandHandler(IApplicationDbContext context, ICurrentUserService currentUser)
    {
        _context = context;
        _currentUser = currentUser;
    }

    public async Task<Result<OrderDto>> Handle(CreateOrderCommand request, CancellationToken cancellationToken)
    {
        if (!_currentUser.TenantId.HasValue)
            return Result<OrderDto>.Unauthorized();

        var creatorBusinessId = _currentUser.TenantId.Value;
        var creator = await _context.Tenants
            .AsNoTracking()
            .FirstOrDefaultAsync(t => t.Id == creatorBusinessId, cancellationToken);

        if (creator == null)
            return Result<OrderDto>.NotFound("Business profile not found");

        if (request.OrderFromBusinessId.HasValue == request.OrderFromExternalBusinessId.HasValue)
            return Result<OrderDto>.Failure("Specify exactly one Order From business.");

        var orderToBusinessId = request.OrderToBusinessId ?? creatorBusinessId;
        var orderTo = await _context.Tenants
            .AsNoTracking()
            .FirstOrDefaultAsync(t => t.Id == orderToBusinessId, cancellationToken);

        if (orderTo?.BusinessType != BusinessType.Shop)
            return Result<OrderDto>.Failure("Order To must be an active Shop.");

        Tenant? orderFrom = null;
        ExternalBusiness? orderFromExternal = null;
        var isIncomingConnectedOrder = false;

        if (request.OrderFromBusinessId.HasValue)
        {
            orderFrom = await _context.Tenants
                .AsNoTracking()
                .FirstOrDefaultAsync(t => t.Id == request.OrderFromBusinessId.Value, cancellationToken);
            if (orderFrom == null)
                return Result<OrderDto>.NotFound("Order From business not found.");

            if (orderFrom.Id != orderToBusinessId)
            {
                var connected = await _context.BusinessConnections.AnyAsync(c =>
                    c.ConnectionType == ConnectionType.ShowroomShop &&
                    c.Status == ConnectionStatus.Accepted &&
                    ((c.FromBusinessId == orderFrom.Id && c.ToBusinessId == orderToBusinessId) ||
                     (c.FromBusinessId == orderToBusinessId && c.ToBusinessId == orderFrom.Id)),
                    cancellationToken);

                if (!connected)
                    return Result<OrderDto>.Forbidden("Order From must be connected to the receiving Shop.");
            }

            isIncomingConnectedOrder = creatorBusinessId == orderFrom.Id && orderFrom.Id != orderToBusinessId;
            if (creator.BusinessType == BusinessType.Showroom &&
                (orderFrom.Id != creatorBusinessId || orderToBusinessId == creatorBusinessId))
            {
                return Result<OrderDto>.Forbidden("A Showroom can create orders only from itself to a connected Shop.");
            }
        }
        else
        {
            if (creator.BusinessType != BusinessType.Shop || orderToBusinessId != creatorBusinessId)
                return Result<OrderDto>.Forbidden("Only the receiving Shop can enter an external business order.");

            orderFromExternal = await _context.ExternalBusinesses
                .FirstOrDefaultAsync(b => b.Id == request.OrderFromExternalBusinessId.Value, cancellationToken);
            if (orderFromExternal == null)
                return Result<OrderDto>.NotFound("External business not found.");
        }

        // Order numbers are scoped to the receiving/fulfilling Shop.
        var orderNo = await GenerateOrderNumber(orderToBusinessId, cancellationToken);

        // Parse dates
        var orderDate = string.IsNullOrEmpty(request.OrderDate)
            ? DateOnly.FromDateTime(DateTime.Today)
            : DateOnly.Parse(request.OrderDate);

        DateOnly? deliveryDate = string.IsNullOrEmpty(request.DeliveryDate)
            ? null
            : DateOnly.Parse(request.DeliveryDate);

        // Create order
        var order = new Order
        {
            OrderNo = orderNo,
            TenantId = orderToBusinessId,
            CreatedByBusinessId = creatorBusinessId,
            OrderFromBusinessId = orderFrom?.Id,
            OrderFromExternalBusinessId = orderFromExternal?.Id,
            Source = orderFromExternal != null ? OrderSource.External :
                orderFrom!.BusinessType == BusinessType.Showroom ? OrderSource.Showroom : OrderSource.Direct,
            AcceptanceStatus = isIncomingConnectedOrder
                ? OrderAcceptanceStatus.Pending
                : OrderAcceptanceStatus.Accepted,
            AcceptedAt = isIncomingConnectedOrder ? null : DateTime.UtcNow,
            OrderDate = orderDate,
            DeliveryDate = deliveryDate,
            Status = OrderStatus.Pending,
            Notes = request.Notes,
            AdvancePaid = request.AdvancePaid
        };

        // Add items
        decimal totalWeight = 0;
        decimal totalMakingCharges = 0;
        decimal totalAmount = 0;

        foreach (var itemDto in request.Items)
        {
            var orderItem = new OrderItem
            {
                OrderId = order.Id,
                ItemMasterId = itemDto.ItemMasterId,
                ItemName = itemDto.ItemName,
                Weight = itemDto.Weight,
                Quantity = itemDto.Quantity,
                Purity = itemDto.Purity,
                Rate = itemDto.Rate,
                MakingCharge = itemDto.MakingCharge,
                Amount = itemDto.Amount,
                Size = itemDto.Size
            };

            order.Items.Add(orderItem);
            totalWeight += itemDto.Weight * Math.Max(itemDto.Quantity, 1);
            totalMakingCharges += itemDto.MakingCharge;
            totalAmount += itemDto.Amount;
        }

        order.TotalWeight = totalWeight;
        order.MakingCharges = totalMakingCharges;
        order.EstimatedAmount = totalAmount;

        _context.Orders.Add(order);

        // Add status history
        var history = new OrderStatusHistory
        {
            OrderId = order.Id,
            FromStatus = OrderStatus.Pending,
            ToStatus = OrderStatus.Pending,
            ChangedBy = _currentUser.UserId ?? Guid.Empty,
            Remarks = "Order created"
        };
        _context.OrderStatusHistory.Add(history);
        _context.OrderEvents.Add(new OrderEvent
        {
            OrderId = order.Id,
            BusinessId = creatorBusinessId,
            UserId = _currentUser.UserId,
            EventType = "OrderCreated",
            Description = $"Order created from {orderFrom?.ShopName ?? orderFromExternal?.Name} to {orderTo.ShopName}"
        });

        await _context.SaveChangesAsync(cancellationToken);

        return Result<OrderDto>.Created(new OrderDto
        {
            Id = order.Id,
            OrderNo = order.OrderNo,
            OrderFromBusinessName = orderFrom?.ShopName ?? orderFromExternal?.Name ?? string.Empty,
            OrderFromBusinessId = order.OrderFromBusinessId,
            OrderFromExternalBusinessId = order.OrderFromExternalBusinessId,
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
            CreatedByBusinessName = creator.ShopName,
            CreatedForBusinessId = order.TenantId,
            CreatedForBusinessName = orderTo.ShopName,
            CreatedAt = order.CreatedAt
        });
    }

    private async Task<string> GenerateOrderNumber(Guid businessId, CancellationToken cancellationToken)
    {
        var lastOrder = await _context.Orders
            .IgnoreQueryFilters()
            .Where(o => o.TenantId == businessId)
            .OrderByDescending(o => o.OrderNo)
            .Select(o => o.OrderNo)
            .FirstOrDefaultAsync(cancellationToken);

        int nextNumber = 1;
        if (!string.IsNullOrEmpty(lastOrder) && lastOrder.StartsWith("ORD-"))
        {
            var numPart = lastOrder.Replace("ORD-", "");
            if (int.TryParse(numPart, out var lastNum))
                nextNumber = lastNum + 1;
        }

        return $"ORD-{nextNumber:D6}";
    }
}
