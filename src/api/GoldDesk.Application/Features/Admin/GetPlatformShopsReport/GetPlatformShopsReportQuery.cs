using GoldDesk.Application.Common.Models;
using MediatR;

namespace GoldDesk.Application.Features.Admin.GetPlatformShopsReport;

public record GetPlatformShopsReportQuery : IRequest<Result<PlatformShopsReportDto>>
{
    public string? BusinessType { get; init; }
    public bool IncludeInactive { get; init; }
}

public class PlatformShopsReportDto
{
    public int PendingApprovals { get; init; }
    public int PendingShopCount { get; init; }
    public int PendingShowroomCount { get; init; }
    public int PendingKarigarCount { get; init; }
    public int ShowroomCount { get; init; }
    public int ShopCount { get; init; }
    public int KarigarCount { get; init; }
    public int TotalShops { get; init; }
    public int ActiveShops { get; init; }
    public int PendingShops { get; init; }
    public int TotalKarigars { get; init; }
    public List<PlatformShopSummaryDto> Shops { get; init; } = [];
}

public class PlatformShopSummaryDto
{
    public Guid TenantId { get; init; }
    public string ShopName { get; init; } = string.Empty;
    public string OwnerName { get; init; } = string.Empty;
    public string Mobile { get; init; } = string.Empty;
    public string Email { get; init; } = string.Empty;
    public string BusinessType { get; init; } = string.Empty;
    public string Status { get; init; } = string.Empty;
    public int KarigarCount { get; init; }
    public int ActiveKarigarCount { get; init; }
    public DateTime RegisteredAt { get; init; }
}
