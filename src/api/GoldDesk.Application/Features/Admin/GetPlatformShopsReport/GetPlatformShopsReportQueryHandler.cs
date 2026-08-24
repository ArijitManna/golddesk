using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Admin.GetPlatformShopsReport;

public class GetPlatformShopsReportQueryHandler
    : IRequestHandler<GetPlatformShopsReportQuery, Result<PlatformShopsReportDto>>
{
    private static readonly Guid PlatformTenantId = Guid.Parse("00000000-0000-0000-0000-000000000001");
    private readonly IApplicationDbContext _context;

    public GetPlatformShopsReportQueryHandler(IApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<Result<PlatformShopsReportDto>> Handle(
        GetPlatformShopsReportQuery request,
        CancellationToken cancellationToken)
    {
        var query = _context.Tenants
            .IgnoreQueryFilters()
            .Where(t => t.Id != PlatformTenantId)
            .Where(t => t.Status != TenantStatus.Rejected && t.Status != TenantStatus.Closed);

        if (!string.IsNullOrWhiteSpace(request.BusinessType) &&
            Enum.TryParse<BusinessType>(request.BusinessType, true, out var businessType))
        {
            query = query.Where(t => t.BusinessType == businessType);
        }

        var tenants = await query
            .OrderByDescending(t => t.CreatedAt)
            .Select(t => new
            {
                t.Id,
                t.ShopName,
                t.OwnerName,
                t.Mobile,
                t.Email,
                BusinessType = t.BusinessType.ToString(),
                Status = t.Status.ToString(),
                t.CreatedAt
            })
            .ToListAsync(cancellationToken);

        var allTenants = await _context.Tenants
            .IgnoreQueryFilters()
            .Where(t => t.Id != PlatformTenantId)
            .Where(t => t.Status != TenantStatus.Rejected && t.Status != TenantStatus.Closed)
            .Select(t => new { t.BusinessType, t.Status })
            .ToListAsync(cancellationToken);

        var karigarStats = await _context.Karigars
            .IgnoreQueryFilters()
            .GroupBy(k => k.TenantId)
            .Select(g => new
            {
                TenantId = g.Key,
                Total = g.Count(),
                Active = g.Count(k => k.Status == KarigarStatus.Active)
            })
            .ToDictionaryAsync(x => x.TenantId, cancellationToken);

        var businesses = tenants.Select(t =>
        {
            karigarStats.TryGetValue(t.Id, out var stats);
            return new PlatformShopSummaryDto
            {
                TenantId = t.Id,
                ShopName = t.ShopName,
                OwnerName = t.OwnerName,
                Mobile = t.Mobile,
                Email = t.Email,
                BusinessType = t.BusinessType,
                Status = t.Status,
                KarigarCount = stats?.Total ?? 0,
                ActiveKarigarCount = stats?.Active ?? 0,
                RegisteredAt = t.CreatedAt
            };
        }).ToList();

        var pending = await _context.Tenants
            .IgnoreQueryFilters()
            .Where(t => t.Id != PlatformTenantId && t.Status == TenantStatus.PendingApproval)
            .Select(t => t.BusinessType)
            .ToListAsync(cancellationToken);

        var report = new PlatformShopsReportDto
        {
            PendingApprovals = pending.Count,
            PendingShopCount = pending.Count(t => t == BusinessType.Shop),
            PendingShowroomCount = pending.Count(t => t == BusinessType.Showroom),
            PendingKarigarCount = pending.Count(t => t == BusinessType.Karigar),
            ShowroomCount = allTenants.Count(t => t.BusinessType == BusinessType.Showroom),
            ShopCount = allTenants.Count(t => t.BusinessType == BusinessType.Shop),
            KarigarCount = allTenants.Count(t => t.BusinessType == BusinessType.Karigar),
            TotalShops = businesses.Count,
            ActiveShops = businesses.Count(s => s.Status == TenantStatus.Active.ToString()),
            PendingShops = businesses.Count(s => s.Status == TenantStatus.PendingApproval.ToString()),
            TotalKarigars = businesses.Sum(s => s.KarigarCount),
            Shops = businesses
        };

        return Result<PlatformShopsReportDto>.Success(report);
    }
}
