using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Orders.Dtos;
using MediatR;

namespace GoldDesk.Application.Features.Dashboard.ShopDashboard;

public record GetShopDashboardQuery : IRequest<Result<ShopDashboardDto>>;

public record ShopDashboardDto
{
    public int TotalOrders { get; init; }
    public int FromShowrooms { get; init; }
    public int DirectOrders { get; init; }
    public int Pending { get; init; }
    public int Assigned { get; init; }
    public int InProgress { get; init; }
    public int DueToday { get; init; }
    public int DueNext3Days { get; init; }
    public int Overdue { get; init; }
    public int Ready { get; init; }
    public int Unassigned { get; init; }
    public int ActiveKarigars { get; init; }
    public string BusinessType { get; init; } = "Shop";
    public List<BusinessOrderCountDto> ConnectedShops { get; init; } = new();
    public List<BusinessOrderCountDto> ConnectedShowrooms { get; init; } = new();
    public List<BusinessOrderCountDto> ExternalCustomers { get; init; } = new();
    public List<OrderDto> RecentOrders { get; init; } = new();
    public List<OrderDto> OverdueOrders { get; init; } = new();
}

public record BusinessOrderCountDto
{
    public Guid BusinessId { get; init; }
    public string BusinessName { get; init; } = string.Empty;
    public string? Code { get; init; }
    public int OrderCount { get; init; }
}
