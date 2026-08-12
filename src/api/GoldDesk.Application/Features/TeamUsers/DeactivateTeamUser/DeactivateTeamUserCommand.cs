using GoldDesk.Application.Common.Models;
using MediatR;

namespace GoldDesk.Application.Features.TeamUsers.DeactivateTeamUser;

public record DeactivateTeamUserCommand(Guid UserId) : IRequest<Result<bool>>;
