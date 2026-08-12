using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.TeamUsers.Dtos;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.TeamUsers.GetTeamUsers;

public class GetTeamUsersQueryHandler : IRequestHandler<GetTeamUsersQuery, Result<List<TeamUserDto>>>
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;

    public GetTeamUsersQueryHandler(IApplicationDbContext context, ICurrentUserService currentUser)
    {
        _context = context;
        _currentUser = currentUser;
    }

    public async Task<Result<List<TeamUserDto>>> Handle(GetTeamUsersQuery request, CancellationToken cancellationToken)
    {
        if (_currentUser.Role != UserRole.ShopOwner)
            return Result<List<TeamUserDto>>.Forbidden("Only shop owners can manage team users");

        var currentUserId = _currentUser.UserId;

        var users = await _context.Users
            .Where(u => u.Role == UserRole.ShopOwner)
            .OrderBy(u => u.CreatedAt)
            .Select(u => new TeamUserDto
            {
                Id = u.Id,
                FullName = u.FullName,
                Email = u.Email,
                Mobile = u.Mobile,
                Role = u.Role.ToString(),
                Status = u.Status.ToString(),
                IsCurrentUser = currentUserId.HasValue && u.Id == currentUserId.Value,
                LastLoginAt = u.LastLoginAt,
                CreatedAt = u.CreatedAt
            })
            .ToListAsync(cancellationToken);

        return Result<List<TeamUserDto>>.Success(users);
    }
}
