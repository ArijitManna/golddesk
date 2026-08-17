using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Admin.ApproveShop;

public class ApproveShopCommandHandler : IRequestHandler<ApproveShopCommand, Result<ApproveShopResponse>>
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;

    public ApproveShopCommandHandler(IApplicationDbContext context, ICurrentUserService currentUser)
    {
        _context = context;
        _currentUser = currentUser;
    }

    public async Task<Result<ApproveShopResponse>> Handle(ApproveShopCommand request, CancellationToken cancellationToken)
    {
        var tenant = await _context.Tenants
            .IgnoreQueryFilters()
            .FirstOrDefaultAsync(t => t.Id == request.TenantId, cancellationToken);

        if (tenant == null)
            return Result<ApproveShopResponse>.NotFound("Shop not found");

        if (tenant.Status != TenantStatus.PendingApproval)
            return Result<ApproveShopResponse>.Failure($"Shop is already in '{tenant.Status}' status and cannot be approved");

        // Approve tenant
        tenant.Status = TenantStatus.Active;
        tenant.AdminNote = request.AdminNote;
        tenant.ApprovedBy = _currentUser.UserId;
        tenant.ApprovedAt = DateTime.UtcNow;

        // Activate primary login users for this business (ShopOwner or Karigar owner)
        var businessUsers = await _context.Users
            .IgnoreQueryFilters()
            .Where(u => u.TenantId == tenant.Id &&
                        (u.Role == UserRole.ShopOwner || u.Role == UserRole.Karigar) &&
                        u.Status == UserStatus.Inactive)
            .ToListAsync(cancellationToken);

        foreach (var businessUser in businessUsers)
            businessUser.Status = UserStatus.Active;

        await _context.SaveChangesAsync(cancellationToken);

        return Result<ApproveShopResponse>.Success(new ApproveShopResponse
        {
            TenantId = tenant.Id,
            ShopName = tenant.ShopName,
            Message = $"{tenant.BusinessType} '{tenant.ShopName}' has been approved successfully"
        });
    }
}
