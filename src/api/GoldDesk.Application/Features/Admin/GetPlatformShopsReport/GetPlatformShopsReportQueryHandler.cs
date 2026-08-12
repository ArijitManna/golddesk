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
        var tenants = await _context.Tenants
            .IgnoreQueryFilters()
            .Where(t => t.Id != PlatformTenantId)
            .Where(t => t.Status != TenantStatus.Rejected && t.Status != TenantStatus.Closed)
            .OrderBy(t => t.ShopName)
            .Select(t => new
            {
                t.Id,
                t.ShopName,
                t.OwnerName,
                t.Mobile,
                t.Email,
                Status = t.Status.ToString(),
                t.CreatedAt
            })
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

        var shops = tenants.Select(t =>
        {
            karigarStats.TryGetValue(t.Id, out var stats);
            return new PlatformShopSummaryDto
            {
                TenantId = t.Id,
                ShopName = t.ShopName,
                OwnerName = t.OwnerName,
                Mobile = t.Mobile,
                Email = t.Email,
                Status = t.Status,
                KarigarCount = stats?.Total ?? 0,
                ActiveKarigarCount = stats?.Active ?? 0,
                RegisteredAt = t.CreatedAt
            };
        }).ToList();

        var report = new PlatformShopsReportDto
        {
            TotalShops = shops.Count,
            ActiveShops = shops.Count(s => s.Status == TenantStatus.Active.ToString()),
            PendingShops = shops.Count(s => s.Status == TenantStatus.PendingApproval.ToString()),
            TotalKarigars = shops.Sum(s => s.KarigarCount),
            Shops = shops
        };

        return Result<PlatformShopsReportDto>.Success(report);
    }
}
