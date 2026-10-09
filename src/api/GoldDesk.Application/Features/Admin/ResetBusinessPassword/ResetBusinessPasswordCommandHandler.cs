using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Admin.ResetBusinessPassword;

public class ResetBusinessPasswordCommandHandler
    : IRequestHandler<ResetBusinessPasswordCommand, Result<ResetBusinessPasswordResponse>>
{
    private static readonly Guid PlatformTenantId = Guid.Parse("00000000-0000-0000-0000-000000000001");
    private readonly IApplicationDbContext _context;
    private readonly IAuthProvider _authProvider;

    public ResetBusinessPasswordCommandHandler(IApplicationDbContext context, IAuthProvider authProvider)
    {
        _context = context;
        _authProvider = authProvider;
    }

    public async Task<Result<ResetBusinessPasswordResponse>> Handle(
        ResetBusinessPasswordCommand request,
        CancellationToken cancellationToken)
    {
        var tenant = await _context.Tenants
            .IgnoreQueryFilters()
            .FirstOrDefaultAsync(t => t.Id == request.TenantId, cancellationToken);

        if (tenant == null || tenant.Id == PlatformTenantId)
            return Result<ResetBusinessPasswordResponse>.NotFound("Business not found");

        var owner = await _context.Users
            .IgnoreQueryFilters()
            .Where(u => u.TenantId == tenant.Id &&
                        (u.Role == UserRole.ShopOwner || u.Role == UserRole.Karigar))
            .OrderBy(u => u.CreatedAt)
            .FirstOrDefaultAsync(cancellationToken);

        if (owner == null)
            return Result<ResetBusinessPasswordResponse>.NotFound("No login found for this business");

        // Linked profiles share one login (same email), so they must share the password.
        var logins = await _context.Users
            .IgnoreQueryFilters()
            .Where(u => u.Email == owner.Email && u.Role != UserRole.SuperAdmin)
            .ToListAsync(cancellationToken);

        var passwordHash = _authProvider.HashPassword(request.NewPassword);
        foreach (var login in logins)
        {
            login.PasswordHash = passwordHash;
            login.RefreshToken = null;
            login.RefreshTokenExpiryTime = null;
        }

        await _context.SaveChangesAsync(cancellationToken);

        return Result<ResetBusinessPasswordResponse>.Success(new ResetBusinessPasswordResponse
        {
            TenantId = tenant.Id,
            Email = owner.Email,
            UpdatedLogins = logins.Count,
            Message = $"Password reset for {owner.Email}"
        });
    }
}
