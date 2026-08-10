using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Domain.Entities;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Auth.Register;

public class RegisterCommandHandler : IRequestHandler<RegisterCommand, Result<RegisterResponse>>
{
    private readonly IApplicationDbContext _context;
    private readonly IAuthProvider _authProvider;

    public RegisterCommandHandler(IApplicationDbContext context, IAuthProvider authProvider)
    {
        _context = context;
        _authProvider = authProvider;
    }

    public async Task<Result<RegisterResponse>> Handle(RegisterCommand request, CancellationToken cancellationToken)
    {
        // Check if email already exists
        var emailExists = await _context.Users
            .IgnoreQueryFilters()
            .AnyAsync(u => u.Email == request.Email, cancellationToken);

        if (emailExists)
            return Result<RegisterResponse>.Conflict("An account with this email already exists");

        // Check if mobile already exists in tenants
        var mobileExists = await _context.Tenants
            .AnyAsync(t => t.Mobile == request.Mobile, cancellationToken);

        if (mobileExists)
            return Result<RegisterResponse>.Conflict("An account with this mobile number already exists");

        // Create tenant
        var tenant = new Tenant
        {
            ShopName = request.ShopName,
            OwnerName = request.OwnerName,
            Mobile = request.Mobile,
            Email = request.Email,
            Address = request.Address,
            Status = TenantStatus.PendingApproval
        };

        _context.Tenants.Add(tenant);

        // Create user
        var user = new User
        {
            TenantId = tenant.Id,
            Email = request.Email,
            PasswordHash = _authProvider.HashPassword(request.Password),
            FullName = request.OwnerName,
            Mobile = request.Mobile,
            Role = UserRole.ShopOwner,
            Status = UserStatus.Inactive // Will become Active when admin approves
        };

        _context.Users.Add(user);
        await _context.SaveChangesAsync(cancellationToken);

        return Result<RegisterResponse>.Created(new RegisterResponse
        {
            TenantId = tenant.Id,
            UserId = user.Id,
            Message = "Registration successful. Your account is pending approval."
        });
    }
}
