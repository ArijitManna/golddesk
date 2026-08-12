using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.TeamUsers.Dtos;
using MediatR;

namespace GoldDesk.Application.Features.TeamUsers.GetTeamUsers;

public record GetTeamUsersQuery : IRequest<Result<List<TeamUserDto>>>;
