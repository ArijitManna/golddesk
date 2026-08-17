using GoldDesk.Application.Common.Models;
using MediatR;

namespace GoldDesk.Application.Features.Auth.Login;

public record LoginCommand : IRequest<Result<LoginResponse>>
{
    public string Email { get; init; } = string.Empty;
    public string Password { get; init; } = string.Empty;
    public string? FcmToken { get; init; }
}

public record LoginResponse
{
    public string AccessToken { get; init; } = string.Empty;
    public string RefreshToken { get; init; } = string.Empty;
    public DateTime ExpiresAt { get; init; }
    public UserInfo User { get; init; } = null!;
}

public record UserInfo
{
    public Guid UserId { get; init; }
    public Guid TenantId { get; init; }
    public string Email { get; init; } = string.Empty;
    public string FullName { get; init; } = string.Empty;
    public string Role { get; init; } = string.Empty;
    public string ShopName { get; init; } = string.Empty;
    public string BusinessType { get; init; } = string.Empty;
    public string GoldDeskId { get; init; } = string.Empty;
}
