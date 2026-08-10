using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Orders.Dtos;
using MediatR;

namespace GoldDesk.Application.Features.Orders.CreateOrder;

public record CreateOrderCommand : IRequest<Result<OrderDto>>
{
    public Guid CustomerId { get; init; }
    public string? OrderDate { get; init; }
    public string? DeliveryDate { get; init; }
    public string? Notes { get; init; }
    public decimal AdvancePaid { get; init; }
    public List<CreateOrderItemDto> Items { get; init; } = new();
}

public record CreateOrderItemDto
{
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
