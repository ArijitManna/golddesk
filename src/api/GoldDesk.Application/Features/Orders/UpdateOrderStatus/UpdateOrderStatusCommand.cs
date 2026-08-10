using GoldDesk.Application.Common.Models;
using MediatR;

namespace GoldDesk.Application.Features.Orders.UpdateOrderStatus;

public record UpdateOrderStatusCommand : IRequest<Result<bool>>
{
    public Guid OrderId { get; init; }
    public string Status { get; init; } = string.Empty;
    public string? Remarks { get; init; }
}
