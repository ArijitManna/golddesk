using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Orders.Dtos;
using GoldDesk.Domain.Entities;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Orders.UpdateOrder;

public class UpdateOrderCommandHandler : IRequestHandler<UpdateOrderCommand, Result<OrderDto>>
{
    private readonly IApplicationDbContext _context;

    public UpdateOrderCommandHandler(IApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<Result<OrderDto>> Handle(UpdateOrderCommand request, CancellationToken cancellationToken)
    {
        var order = await _context.Orders
            .Include(o => o.Customer)
            .Include(o => o.Items)
            .FirstOrDefaultAsync(o => o.Id == request.OrderId, cancellationToken);

        if (order == null)
            return Result<OrderDto>.NotFound("Order not found");

        if (order.Status != OrderStatus.Pending)
            return Result<OrderDto>.Failure("Only unassigned (pending) orders can be edited");

        var customer = await _context.Customers
            .FirstOrDefaultAsync(c => c.Id == request.CustomerId, cancellationToken);

        if (customer == null)
            return Result<OrderDto>.NotFound("Customer not found");

        var orderDate = string.IsNullOrEmpty(request.OrderDate)
            ? order.OrderDate
            : DateOnly.Parse(request.OrderDate);

        DateOnly? deliveryDate = string.IsNullOrEmpty(request.DeliveryDate)
            ? null
            : DateOnly.Parse(request.DeliveryDate);

        order.CustomerId = request.CustomerId;
        order.OrderDate = orderDate;
        order.DeliveryDate = deliveryDate;
        order.Notes = request.Notes;
        order.AdvancePaid = request.AdvancePaid;

        var incomingIds = request.Items
            .Where(i => i.Id.HasValue)
            .Select(i => i.Id!.Value)
            .ToHashSet();

        var existingItems = order.Items.ToList();
        foreach (var existing in existingItems)
        {
            if (!incomingIds.Contains(existing.Id))
                _context.OrderItems.Remove(existing);
        }

        decimal totalWeight = 0;
        decimal totalMakingCharges = 0;
        decimal totalAmount = 0;

        foreach (var itemDto in request.Items)
        {
            var orderItem = itemDto.Id.HasValue
                ? existingItems.FirstOrDefault(i => i.Id == itemDto.Id.Value)
                : null;

            if (orderItem != null)
            {
                orderItem.ItemMasterId = itemDto.ItemMasterId;
                orderItem.ItemName = itemDto.ItemName;
                orderItem.Weight = itemDto.Weight;
                orderItem.Quantity = itemDto.Quantity;
                orderItem.Purity = itemDto.Purity;
                orderItem.Rate = itemDto.Rate;
                orderItem.MakingCharge = itemDto.MakingCharge;
                orderItem.Amount = itemDto.Amount;
                orderItem.Size = itemDto.Size;
            }
            else
            {
                order.Items.Add(new OrderItem
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
                });
            }

            totalWeight += itemDto.Weight * Math.Max(itemDto.Quantity, 1);
            totalMakingCharges += itemDto.MakingCharge;
            totalAmount += itemDto.Amount;
        }

        order.TotalWeight = totalWeight;
        order.MakingCharges = totalMakingCharges;
        order.EstimatedAmount = totalAmount;

        await _context.SaveChangesAsync(cancellationToken);

        return Result<OrderDto>.Success(new OrderDto
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
}
