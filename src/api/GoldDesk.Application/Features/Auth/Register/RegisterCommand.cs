using GoldDesk.Application.Common.Models;
using MediatR;

namespace GoldDesk.Application.Features.Auth.Register;

public record RegisterCommand : IRequest<Result<RegisterResponse>>
{
    public string ShopName { get; init; } = string.Empty;
    public string OwnerName { get; init; } = string.Empty;
    public string Mobile { get; init; } = string.Empty;
    public string Email { get; init; } = string.Empty;
    public string Password { get; init; } = string.Empty;
    public string? Address { get; init; }
}

public record RegisterResponse
{
    public Guid TenantId { get; init; }
    public Guid UserId { get; init; }
    public string Message { get; init; } = string.Empty;
}
