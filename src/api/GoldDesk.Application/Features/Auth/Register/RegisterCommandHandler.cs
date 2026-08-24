using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Common.Services;
using GoldDesk.Domain.Entities;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Auth.Register;

public class RegisterCommandHandler : IRequestHandler<RegisterCommand, Result<RegisterResponse>>
{
    private readonly IApplicationDbContext _context;
    private readonly IAuthProvider _authProvider;
    private readonly INotificationService _notificationService;

    public RegisterCommandHandler(
        IApplicationDbContext context,
        IAuthProvider authProvider,
        INotificationService notificationService)
    {
        _context = context;
        _authProvider = authProvider;
        _notificationService = notificationService;
    }

    public async Task<Result<RegisterResponse>> Handle(RegisterCommand request, CancellationToken cancellationToken)
    {
        var existingUser = await _context.Users
            .IgnoreQueryFilters()
            .FirstOrDefaultAsync(u => u.Email == request.Email, cancellationToken);

        if (existingUser != null &&
            !_authProvider.VerifyPassword(request.Password, existingUser.PasswordHash))
            return Result<RegisterResponse>.Conflict(
                "This email is already linked to another business. Use the same account password to add this profile.");

        var alreadyHasBusinessType = await _context.Users
            .IgnoreQueryFilters()
            .Include(u => u.Tenant)
            .AnyAsync(u => u.Email == request.Email &&
                           u.Tenant.BusinessType == request.BusinessType, cancellationToken);

        if (alreadyHasBusinessType)
            return Result<RegisterResponse>.Conflict(
                $"This email already has a {request.BusinessType} profile. Switch business after login instead.");

        var mobileExists = await _context.Tenants
            .AnyAsync(t => t.Mobile == request.Mobile, cancellationToken);

        if (mobileExists)
            return Result<RegisterResponse>.Conflict("An account with this mobile number already exists. Use a different mobile for the new business profile.");

        var goldDeskId = await GoldDeskIdGenerator.GenerateAsync(_context, request.BusinessType, cancellationToken);

        var tenant = new Tenant
        {
            ShopName = request.ShopName,
            OwnerName = request.OwnerName,
            Mobile = request.Mobile,
            Email = request.Email,
            Address = request.Address,
            BusinessType = request.BusinessType,
            GoldDeskId = goldDeskId,
            Status = TenantStatus.PendingApproval
        };

        _context.Tenants.Add(tenant);

        var user = new User
        {
            TenantId = tenant.Id,
            Email = request.Email,
            PasswordHash = existingUser?.PasswordHash ?? _authProvider.HashPassword(request.Password),
            FullName = request.OwnerName,
            Mobile = request.Mobile,
            Role = request.BusinessType == BusinessType.Karigar
                ? UserRole.Karigar
                : UserRole.ShopOwner,
            Status = UserStatus.Inactive
        };

        _context.Users.Add(user);
        if (request.BusinessType == BusinessType.Karigar)
        {
            _context.Karigars.Add(new Karigar
            {
                TenantId = tenant.Id,
                UserId = user.Id,
                Name = request.OwnerName,
                Mobile = request.Mobile,
                Email = request.Email,
                Address = request.Address,
                Status = KarigarStatus.Active
            });
        }
        await _context.SaveChangesAsync(cancellationToken);

        await NotifySuperAdminsAsync(tenant, cancellationToken);

        return Result<RegisterResponse>.Created(new RegisterResponse
        {
            TenantId = tenant.Id,
            UserId = user.Id,
            GoldDeskId = tenant.GoldDeskId,
            Message = "Registration successful. Your account is pending approval."
        });
    }

    private async Task NotifySuperAdminsAsync(Tenant tenant, CancellationToken cancellationToken)
    {
        var superAdmins = await _context.Users
            .IgnoreQueryFilters()
            .Where(u => u.Role == UserRole.SuperAdmin)
            .ToListAsync(cancellationToken);

        var businessLabel = tenant.BusinessType.ToString();
        var title = $"New {businessLabel} registration";
        var message = $"{tenant.ShopName} ({tenant.OwnerName}) is waiting for approval.";

        foreach (var admin in superAdmins)
        {
            await _notificationService.CreateAndPushAsync(
                admin.TenantId,
                admin.Id,
                null,
                NotificationType.RegistrationRequested,
                title,
                message,
                cancellationToken);
        }
    }
}
