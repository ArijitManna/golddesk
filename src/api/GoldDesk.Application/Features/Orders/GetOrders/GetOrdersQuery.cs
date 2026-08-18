using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Orders.Dtos;
using MediatR;

namespace GoldDesk.Application.Features.Orders.GetOrders;

public record GetOrdersQuery : IRequest<Result<PagedResult<OrderDto>>>
{
    public string? Status { get; init; }
    /// <summary>Due filter: today | overdue | next3</summary>
    public string? Due { get; init; }
    public string? Search { get; init; }
    public string? Source { get; init; }
    public Guid? ShopId { get; init; }
    public Guid? ShowroomId { get; init; }
    public Guid? ExternalCustomerId { get; init; }
    public int Page { get; init; } = 1;
    public int PageSize { get; init; } = 20;
}
