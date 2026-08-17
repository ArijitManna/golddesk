using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Orders.Dtos;
using MediatR;

namespace GoldDesk.Application.Features.Orders.RespondToOrder;

public record RespondToOrderCommand : IRequest<Result<OrderDto>>
{
    public Guid OrderId { get; init; }
    public bool Accept { get; init; }
    public string? Note { get; init; }
}
