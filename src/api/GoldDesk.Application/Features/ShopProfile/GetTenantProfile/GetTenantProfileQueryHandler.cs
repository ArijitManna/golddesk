using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.ShopProfile.Dtos;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.ShopProfile.GetTenantProfile;

public class GetTenantProfileQueryHandler : IRequestHandler<GetTenantProfileQuery, Result<TenantProfileDto>>
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;

    public GetTenantProfileQueryHandler(IApplicationDbContext context, ICurrentUserService currentUser)
    {
        _context = context;
        _currentUser = currentUser;
    }

    public async Task<Result<TenantProfileDto>> Handle(GetTenantProfileQuery request, CancellationToken cancellationToken)
    {
        if (!_currentUser.TenantId.HasValue)
            return Result<TenantProfileDto>.Unauthorized();

        var tenant = await _context.Tenants
            .AsNoTracking()
            .FirstOrDefaultAsync(t => t.Id == _currentUser.TenantId.Value, cancellationToken);

        if (tenant == null)
            return Result<TenantProfileDto>.NotFound("Shop profile not found");

        return Result<TenantProfileDto>.Success(Map(tenant));
    }

    internal static TenantProfileDto Map(Domain.Entities.Tenant tenant) => new()
    {
        Id = tenant.Id,
        ShopName = tenant.ShopName,
        OwnerName = tenant.OwnerName,
        Mobile = tenant.Mobile,
        Email = tenant.Email,
        Address = tenant.Address,
        GstNumber = tenant.GstNumber,
        LogoPath = tenant.LogoPath,
        NotifyDueSoon3Days = tenant.NotifyDueSoon3Days,
        NotifyDueSoon2Days = tenant.NotifyDueSoon2Days,
        NotifyDueSoon1Day = tenant.NotifyDueSoon1Day,
        NotifyDueToday = tenant.NotifyDueToday,
        NotifyOverdue = tenant.NotifyOverdue
    };
}
