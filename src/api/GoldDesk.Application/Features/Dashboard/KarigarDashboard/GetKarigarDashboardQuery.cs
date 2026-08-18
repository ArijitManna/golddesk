using GoldDesk.Application.Common.Models;
using MediatR;

namespace GoldDesk.Application.Features.Dashboard.KarigarDashboard;

public record GetKarigarDashboardQuery : IRequest<Result<KarigarDashboardDto>>;

public record KarigarDashboardDto
{
    public int TotalAssigned { get; init; }
    public int NewWork { get; init; }
    public int WorkAccepted { get; init; }
    public int InProgress { get; init; }
    public int DueToday { get; init; }
    public int DueSoon { get; init; } // Next 3 days
    public int Overdue { get; init; }
    public int Ready { get; init; }
    public List<KarigarOrderDto> DueSoonOrders { get; init; } = new();
    public List<KarigarOrderDto> RecentOrders { get; init; } = new();
    public List<KarigarShopCountDto> Shops { get; init; } = new();
}

public record KarigarShopCountDto
{
    public Guid BusinessId { get; init; }
    public string BusinessName { get; init; } = string.Empty;
    public string? Code { get; init; }
    public int OrderCount { get; init; }
}

public record KarigarOrderDto
{
    public Guid OrderId { get; init; }
    public string OrderNo { get; init; } = string.Empty;
    public string OrderFromBusinessName { get; init; } = string.Empty;
    public string SourceShopName { get; init; } = string.Empty;
    public string Status { get; init; } = string.Empty;
    public string AssignmentStatus { get; init; } = string.Empty;
    public string DueDate { get; init; } = string.Empty;
    public int DaysLeft { get; init; }
    public string? Notes { get; init; }
    public decimal TotalWeight { get; init; }
}
