using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.TeamUsers.Dtos;
using MediatR;

namespace GoldDesk.Application.Features.TeamUsers.CreateTeamUser;

public record CreateTeamUserCommand : IRequest<Result<TeamUserDto>>
{
    public string FullName { get; init; } = string.Empty;
    public string Email { get; init; } = string.Empty;
    public string Mobile { get; init; } = string.Empty;
    public string Password { get; init; } = string.Empty;
}
