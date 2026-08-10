using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Orders.Dtos;
using MediatR;

namespace GoldDesk.Application.Features.Dashboard.ShopDashboard;

public record GetShopDashboardQuery : IRequest<Result<ShopDashboardDto>>;

public record ShopDashboardDto
{
    public int TotalOrders { get; init; }
    public int Pending { get; init; }
    public int Assigned { get; init; }
    public int InProgress { get; init; }
    public int DueToday { get; init; }
    public int DueNext3Days { get; init; }
    public int Overdue { get; init; }
    public int Ready { get; init; }
    public int Unassigned { get; init; }
    public int ActiveKarigars { get; init; }
    public List<OrderDto> RecentOrders { get; init; } = new();
    public List<OrderDto> OverdueOrders { get; init; } = new();
}
