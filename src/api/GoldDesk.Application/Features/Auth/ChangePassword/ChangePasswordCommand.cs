using GoldDesk.Application.Common.Models;
using MediatR;

namespace GoldDesk.Application.Features.Auth.ChangePassword;

public record ChangePasswordCommand : IRequest<Result<bool>>
{
    public string CurrentPassword { get; init; } = string.Empty;
    public string NewPassword { get; init; } = string.Empty;
}
