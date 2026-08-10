using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Auth.Login;
using MediatR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace GoldDesk.Application.Features.Auth.RefreshToken;

public class RefreshTokenCommandHandler : IRequestHandler<RefreshTokenCommand, Result<LoginResponse>>
{
    private readonly IApplicationDbContext _context;
    private readonly IAuthProvider _authProvider;
    private readonly IConfiguration _configuration;

    public RefreshTokenCommandHandler(
        IApplicationDbContext context,
        IAuthProvider authProvider,
        IConfiguration configuration)
    {
        _context = context;
        _authProvider = authProvider;
        _configuration = configuration;
    }

    public async Task<Result<LoginResponse>> Handle(RefreshTokenCommand request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrEmpty(request.RefreshToken))
            return Result<LoginResponse>.Unauthorized("Refresh token is required");

        var user = await _context.Users
            .IgnoreQueryFilters()
            .Include(u => u.Tenant)
            .FirstOrDefaultAsync(u =>
                u.RefreshToken == request.RefreshToken &&
                u.RefreshTokenExpiryTime > DateTime.UtcNow,
                cancellationToken);

        if (user == null)
            return Result<LoginResponse>.Unauthorized("Invalid or expired refresh token");

        // Generate new tokens
        var accessToken = _authProvider.GenerateAccessToken(
            user.Id, user.TenantId, user.Email, user.Role.ToString());

        var newRefreshToken = _authProvider.GenerateRefreshToken();
        var refreshExpiryDays = int.Parse(_configuration["Jwt:RefreshTokenExpiryDays"] ?? "7");

        user.RefreshToken = newRefreshToken;
        user.RefreshTokenExpiryTime = DateTime.UtcNow.AddDays(refreshExpiryDays);

        await _context.SaveChangesAsync(cancellationToken);

        var expiryMinutes = int.Parse(_configuration["Jwt:ExpiryMinutes"] ?? "60");

        return Result<LoginResponse>.Success(new LoginResponse
        {
            AccessToken = accessToken,
            RefreshToken = newRefreshToken,
            ExpiresAt = DateTime.UtcNow.AddMinutes(expiryMinutes),
            User = new UserInfo
            {
                UserId = user.Id,
                TenantId = user.TenantId,
                Email = user.Email,
                FullName = user.FullName,
                Role = user.Role.ToString(),
                ShopName = user.Tenant.ShopName
            }
        });
    }
}
