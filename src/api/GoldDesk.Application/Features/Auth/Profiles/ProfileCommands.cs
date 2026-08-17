using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Auth.Login;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace GoldDesk.Application.Features.Auth.Profiles;

public record GetProfilesQuery : IRequest<Result<List<UserInfo>>>;

public record SwitchProfileCommand : IRequest<Result<LoginResponse>>
{
    public Guid TenantId { get; init; }
    public string? FcmToken { get; init; }
}

public record UpdateFcmTokenCommand : IRequest<Result<bool>>
{
    public string FcmToken { get; init; } = string.Empty;
}

public class UpdateFcmTokenCommandHandler : IRequestHandler<UpdateFcmTokenCommand, Result<bool>>
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;

    public UpdateFcmTokenCommandHandler(
        IApplicationDbContext context,
        ICurrentUserService currentUser)
    {
        _context = context;
        _currentUser = currentUser;
    }

    public async Task<Result<bool>> Handle(
        UpdateFcmTokenCommand request,
        CancellationToken cancellationToken)
    {
        if (!_currentUser.UserId.HasValue)
            return Result<bool>.Unauthorized();

        if (string.IsNullOrWhiteSpace(request.FcmToken))
            return Result<bool>.Failure("FCM token is required.");

        var user = await _context.Users
            .IgnoreQueryFilters()
            .FirstOrDefaultAsync(u => u.Id == _currentUser.UserId.Value, cancellationToken);

        if (user == null)
            return Result<bool>.NotFound("User not found.");

        user.FcmToken = request.FcmToken;
        await _context.SaveChangesAsync(cancellationToken);

        return Result<bool>.Success(true);
    }
}

public class GetProfilesQueryHandler : IRequestHandler<GetProfilesQuery, Result<List<UserInfo>>>
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;

    public GetProfilesQueryHandler(IApplicationDbContext context, ICurrentUserService currentUser)
    {
        _context = context;
        _currentUser = currentUser;
    }

    public async Task<Result<List<UserInfo>>> Handle(GetProfilesQuery request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(_currentUser.Email))
            return Result<List<UserInfo>>.Unauthorized();

        var users = await _context.Users
            .IgnoreQueryFilters()
            .Include(u => u.Tenant)
            .Where(u => u.Email == _currentUser.Email &&
                        u.Status == UserStatus.Active &&
                        u.Tenant.Status == TenantStatus.Active)
            .OrderBy(u => u.Tenant.ShopName)
            .ToListAsync(cancellationToken);

        return Result<List<UserInfo>>.Success(users.Select(u => new UserInfo
        {
            UserId = u.Id,
            TenantId = u.TenantId,
            Email = u.Email,
            FullName = u.FullName,
            Role = u.Role.ToString(),
            ShopName = u.Tenant.ShopName,
            BusinessType = u.Tenant.BusinessType.ToString(),
            GoldDeskId = u.Tenant.GoldDeskId
        }).ToList());
    }
}

public class SwitchProfileCommandHandler : IRequestHandler<SwitchProfileCommand, Result<LoginResponse>>
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;
    private readonly IAuthProvider _authProvider;
    private readonly IConfiguration _configuration;

    public SwitchProfileCommandHandler(
        IApplicationDbContext context,
        ICurrentUserService currentUser,
        IAuthProvider authProvider,
        IConfiguration configuration)
    {
        _context = context;
        _currentUser = currentUser;
        _authProvider = authProvider;
        _configuration = configuration;
    }

    public async Task<Result<LoginResponse>> Handle(SwitchProfileCommand request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(_currentUser.Email))
            return Result<LoginResponse>.Unauthorized();

        var user = await _context.Users
            .IgnoreQueryFilters()
            .Include(u => u.Tenant)
            .FirstOrDefaultAsync(u => u.Email == _currentUser.Email &&
                                      u.TenantId == request.TenantId &&
                                      u.Status == UserStatus.Active &&
                                      u.Tenant.Status == TenantStatus.Active,
                cancellationToken);

        if (user == null)
            return Result<LoginResponse>.Forbidden("You do not have access to this business profile.");

        var refreshToken = _authProvider.GenerateRefreshToken();
        var expiryDays = int.Parse(_configuration["Jwt:RefreshTokenExpiryDays"] ?? "7");
        user.RefreshToken = refreshToken;
        user.RefreshTokenExpiryTime = DateTime.UtcNow.AddDays(expiryDays);
        user.LastLoginAt = DateTime.UtcNow;
        if (!string.IsNullOrWhiteSpace(request.FcmToken))
            user.FcmToken = request.FcmToken;

        await _context.SaveChangesAsync(cancellationToken);

        return Result<LoginResponse>.Success(new LoginResponse
        {
            AccessToken = _authProvider.GenerateAccessToken(user.Id, user.TenantId, user.Email, user.Role.ToString()),
            RefreshToken = refreshToken,
            ExpiresAt = DateTime.UtcNow.AddMinutes(int.Parse(_configuration["Jwt:ExpiryMinutes"] ?? "60")),
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
