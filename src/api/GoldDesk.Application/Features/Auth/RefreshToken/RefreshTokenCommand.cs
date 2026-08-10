using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Auth.Login;
using MediatR;

namespace GoldDesk.Application.Features.Auth.RefreshToken;

public record RefreshTokenCommand : IRequest<Result<LoginResponse>>
{
    public string RefreshToken { get; init; } = string.Empty;
}
