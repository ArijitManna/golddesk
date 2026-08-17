using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.ShopProfile.Dtos;
using GoldDesk.Application.Features.ShopProfile.GetTenantProfile;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.ShopProfile.UpdateTenantProfile;

public class UpdateTenantProfileCommandHandler : IRequestHandler<UpdateTenantProfileCommand, Result<TenantProfileDto>>
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;

    public UpdateTenantProfileCommandHandler(IApplicationDbContext context, ICurrentUserService currentUser)
    {
        _context = context;
        _currentUser = currentUser;
    }

    public async Task<Result<TenantProfileDto>> Handle(UpdateTenantProfileCommand request, CancellationToken cancellationToken)
    {
        if ((_currentUser.Role != UserRole.ShopOwner &&
             _currentUser.Role != UserRole.Karigar) ||
            !_currentUser.TenantId.HasValue)
        {
            return Result<TenantProfileDto>.Forbidden("Only business owners can update their profile");
        }

        var tenant = await _context.Tenants
            .FirstOrDefaultAsync(t => t.Id == _currentUser.TenantId.Value, cancellationToken);

        if (tenant == null)
            return Result<TenantProfileDto>.NotFound("Business profile not found");

        var mobile = request.Mobile.Trim();
        var mobileTaken = await _context.Tenants
            .AnyAsync(t => t.Mobile == mobile && t.Id != tenant.Id, cancellationToken);
        if (mobileTaken)
            return Result<TenantProfileDto>.Conflict("Another business already uses this mobile number");

        tenant.ShopName = request.ShopName.Trim();
        tenant.OwnerName = request.OwnerName.Trim();
        tenant.Mobile = mobile;
        tenant.Address = string.IsNullOrWhiteSpace(request.Address) ? null : request.Address.Trim();
        tenant.GstNumber = string.IsNullOrWhiteSpace(request.GstNumber) ? null : request.GstNumber.Trim();

        await _context.SaveChangesAsync(cancellationToken);

        return Result<TenantProfileDto>.Success(GetTenantProfileQueryHandler.Map(tenant));
    }
}
