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
        // Verify customer exists
        var customer = await _context.Customers
            .FirstOrDefaultAsync(c => c.Id == request.CustomerId, cancellationToken);

        if (customer == null)
            return Result<OrderDto>.NotFound("Customer not found");

        // Generate order number
        var orderNo = await GenerateOrderNumber(cancellationToken);

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
            CustomerId = request.CustomerId,
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

        await _context.SaveChangesAsync(cancellationToken);

        return Result<OrderDto>.Created(new OrderDto
        {
            Id = order.Id,
            OrderNo = order.OrderNo,
            CustomerName = customer.Name,
            CustomerId = order.CustomerId,
            OrderDate = order.OrderDate.ToString("yyyy-MM-dd"),
            DeliveryDate = order.DeliveryDate?.ToString("yyyy-MM-dd"),
            Status = order.Status.ToString(),
            TotalWeight = order.TotalWeight,
            MakingCharges = order.MakingCharges,
            AdvancePaid = order.AdvancePaid,
            EstimatedAmount = order.EstimatedAmount,
            Notes = order.Notes,
            CreatedAt = order.CreatedAt
        });
    }

    private async Task<string> GenerateOrderNumber(CancellationToken cancellationToken)
    {
        var tenantId = _currentUser.TenantId;

        var lastOrder = await _context.Orders
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
