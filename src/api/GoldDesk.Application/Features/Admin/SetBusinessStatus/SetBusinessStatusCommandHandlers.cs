using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Admin.SetBusinessStatus;

public class DeactivateBusinessCommandHandler
    : IRequestHandler<DeactivateBusinessCommand, Result<BusinessStatusResponse>>
{
    private static readonly Guid PlatformTenantId = Guid.Parse("00000000-0000-0000-0000-000000000001");
    private readonly IApplicationDbContext _context;

    public DeactivateBusinessCommandHandler(IApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<Result<BusinessStatusResponse>> Handle(
        DeactivateBusinessCommand request,
        CancellationToken cancellationToken)
    {
        var tenant = await _context.Tenants
            .IgnoreQueryFilters()
            .FirstOrDefaultAsync(t => t.Id == request.TenantId, cancellationToken);

        if (tenant == null || tenant.Id == PlatformTenantId)
            return Result<BusinessStatusResponse>.NotFound("Business not found");

        if (tenant.Status != TenantStatus.Active)
            return Result<BusinessStatusResponse>.Failure(
                $"Only active businesses can be inactivated. Current status: {tenant.Status}");

        tenant.Status = TenantStatus.Suspended;

        var users = await _context.Users
            .IgnoreQueryFilters()
            .Where(u => u.TenantId == tenant.Id && u.Status == UserStatus.Active)
            .ToListAsync(cancellationToken);

        foreach (var user in users)
            user.Status = UserStatus.Inactive;

        await _context.SaveChangesAsync(cancellationToken);

        return Result<BusinessStatusResponse>.Success(new BusinessStatusResponse
        {
            TenantId = tenant.Id,
            ShopName = tenant.ShopName,
            Status = tenant.Status.ToString(),
            Message = $"{tenant.BusinessType} '{tenant.ShopName}' has been inactivated"
        });
    }
}

public class ActivateBusinessCommandHandler
    : IRequestHandler<ActivateBusinessCommand, Result<BusinessStatusResponse>>
{
    private static readonly Guid PlatformTenantId = Guid.Parse("00000000-0000-0000-0000-000000000001");
    private readonly IApplicationDbContext _context;

    public ActivateBusinessCommandHandler(IApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<Result<BusinessStatusResponse>> Handle(
        ActivateBusinessCommand request,
        CancellationToken cancellationToken)
    {
        var tenant = await _context.Tenants
            .IgnoreQueryFilters()
            .FirstOrDefaultAsync(t => t.Id == request.TenantId, cancellationToken);

        if (tenant == null || tenant.Id == PlatformTenantId)
            return Result<BusinessStatusResponse>.NotFound("Business not found");

        if (tenant.Status != TenantStatus.Suspended)
            return Result<BusinessStatusResponse>.Failure(
                $"Only inactive businesses can be reactivated. Current status: {tenant.Status}");

        tenant.Status = TenantStatus.Active;

        var users = await _context.Users
            .IgnoreQueryFilters()
            .Where(u => u.TenantId == tenant.Id &&
                        (u.Role == UserRole.ShopOwner || u.Role == UserRole.Karigar) &&
                        u.Status == UserStatus.Inactive)
            .ToListAsync(cancellationToken);

        foreach (var user in users)
            user.Status = UserStatus.Active;

        await _context.SaveChangesAsync(cancellationToken);

        return Result<BusinessStatusResponse>.Success(new BusinessStatusResponse
        {
            TenantId = tenant.Id,
            ShopName = tenant.ShopName,
            Status = tenant.Status.ToString(),
            Message = $"{tenant.BusinessType} '{tenant.ShopName}' has been activated"
        });
    }
}
