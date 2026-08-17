using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace GoldDesk.Application.Features.Auth.Login;

public class LoginCommandHandler : IRequestHandler<LoginCommand, Result<LoginResponse>>
{
    private readonly IApplicationDbContext _context;
    private readonly IAuthProvider _authProvider;
    private readonly IConfiguration _configuration;

    public LoginCommandHandler(
        IApplicationDbContext context,
        IAuthProvider authProvider,
        IConfiguration configuration)
    {
        _context = context;
        _authProvider = authProvider;
        _configuration = configuration;
    }

    public async Task<Result<LoginResponse>> Handle(LoginCommand request, CancellationToken cancellationToken)
    {
        // Find user by email (ignore tenant filter for login)
        var user = await _context.Users
            .IgnoreQueryFilters()
            .Include(u => u.Tenant)
            .Where(u => u.Email == request.Email)
            .OrderByDescending(u => u.Status == UserStatus.Active &&
                                  u.Tenant.Status == TenantStatus.Active)
            .ThenByDescending(u => u.LastLoginAt)
            .FirstOrDefaultAsync(cancellationToken);

        if (user == null)
            return Result<LoginResponse>.Unauthorized("Invalid email or password");

        // Verify password
        if (!_authProvider.VerifyPassword(request.Password, user.PasswordHash))
            return Result<LoginResponse>.Unauthorized("Invalid email or password");

        // Check user status
        if (user.Status == UserStatus.Locked)
            return Result<LoginResponse>.Forbidden("Your account has been locked. Contact support.");

        if (user.Status == UserStatus.Suspended)
            return Result<LoginResponse>.Forbidden("Your account has been suspended.");

        // Check tenant status
        if (user.Tenant.Status == TenantStatus.PendingApproval)
            return Result<LoginResponse>.Failure("Your account is pending approval. Please wait for admin approval.", 403);

        if (user.Tenant.Status == TenantStatus.Rejected)
            return Result<LoginResponse>.Failure("Your registration was rejected. Contact support for details.", 403);

        if (user.Tenant.Status == TenantStatus.Suspended)
            return Result<LoginResponse>.Forbidden("Your shop account has been suspended.");

        if (user.Status == UserStatus.Inactive)
            return Result<LoginResponse>.Forbidden("Your account is not active.");

        // Generate tokens
        var accessToken = _authProvider.GenerateAccessToken(
            user.Id, user.TenantId, user.Email, user.Role.ToString());

        var refreshToken = _authProvider.GenerateRefreshToken();
        var refreshExpiryDays = int.Parse(_configuration["Jwt:RefreshTokenExpiryDays"] ?? "7");

        // Update user with refresh token and FCM token
        user.RefreshToken = refreshToken;
        user.RefreshTokenExpiryTime = DateTime.UtcNow.AddDays(refreshExpiryDays);
        user.LastLoginAt = DateTime.UtcNow;

        if (!string.IsNullOrEmpty(request.FcmToken))
            user.FcmToken = request.FcmToken;

        await _context.SaveChangesAsync(cancellationToken);

        var expiryMinutes = int.Parse(_configuration["Jwt:ExpiryMinutes"] ?? "60");

        return Result<LoginResponse>.Success(new LoginResponse
        {
            AccessToken = accessToken,
            RefreshToken = refreshToken,
            ExpiresAt = DateTime.UtcNow.AddMinutes(expiryMinutes),
            User = new UserInfo
            {
                UserId = user.Id,
                TenantId = user.TenantId,
                Email = user.Email,
                FullName = user.FullName,
                Role = user.Role.ToString(),
                ShopName = user.Tenant.ShopName,
                BusinessType = user.Tenant.BusinessType.ToString(),
                GoldDeskId = user.Tenant.GoldDeskId
            }
        });
    }
}
