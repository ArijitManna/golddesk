using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.ShopProfile.Dtos;
using GoldDesk.Application.Features.ShopProfile.GetTenantProfile;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.ShopProfile.UpdateNotificationPreferences;

public class UpdateNotificationPreferencesCommandHandler
    : IRequestHandler<UpdateNotificationPreferencesCommand, Result<TenantProfileDto>>
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;

    public UpdateNotificationPreferencesCommandHandler(
        IApplicationDbContext context,
        ICurrentUserService currentUser)
    {
        _context = context;
        _currentUser = currentUser;
    }

    public async Task<Result<TenantProfileDto>> Handle(
        UpdateNotificationPreferencesCommand request,
        CancellationToken cancellationToken)
    {
        if (_currentUser.Role != UserRole.ShopOwner || !_currentUser.TenantId.HasValue)
            return Result<TenantProfileDto>.Forbidden("Only shop owners can update notification preferences");

        var tenant = await _context.Tenants
            .FirstOrDefaultAsync(t => t.Id == _currentUser.TenantId.Value, cancellationToken);

        if (tenant == null)
            return Result<TenantProfileDto>.NotFound("Shop profile not found");

        tenant.NotifyDueSoon3Days = request.NotifyDueSoon3Days;
        tenant.NotifyDueSoon2Days = request.NotifyDueSoon2Days;
        tenant.NotifyDueSoon1Day = request.NotifyDueSoon1Day;
        tenant.NotifyDueToday = request.NotifyDueToday;
        tenant.NotifyOverdue = request.NotifyOverdue;

        await _context.SaveChangesAsync(cancellationToken);

        return Result<TenantProfileDto>.Success(GetTenantProfileQueryHandler.Map(tenant));
    }
}
