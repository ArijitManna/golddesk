using GoldDesk.Application.Common.Models;
using MediatR;

namespace GoldDesk.Application.Features.Orders.CancelOrder;

public record CancelOrderCommand : IRequest<Result<bool>>
{
    public Guid OrderId { get; init; }
    public string? Reason { get; init; }
}
