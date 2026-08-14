using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Orders.Dtos;
using MediatR;

namespace GoldDesk.Application.Features.Orders.UpdateOrder;

public record UpdateOrderCommand : IRequest<Result<OrderDto>>
{
    public Guid OrderId { get; init; }
    public Guid CustomerId { get; init; }
    public string? OrderDate { get; init; }
    public string? DeliveryDate { get; init; }
    public string? Notes { get; init; }
    public decimal AdvancePaid { get; init; }
    public List<UpdateOrderItemDto> Items { get; init; } = new();
}

public record UpdateOrderItemDto
{
    public Guid? Id { get; init; }
    public Guid? ItemMasterId { get; init; }
    public string ItemName { get; init; } = string.Empty;
    public decimal Weight { get; init; }
    public int Quantity { get; init; } = 1;
    public string? Purity { get; init; }
    public decimal Rate { get; init; }
    public decimal MakingCharge { get; init; }
    public decimal Amount { get; init; }
    public string? Size { get; init; }
}
