using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.TeamUsers.Dtos;
using GoldDesk.Domain.Entities;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.TeamUsers.CreateTeamUser;

public class CreateTeamUserCommandHandler : IRequestHandler<CreateTeamUserCommand, Result<TeamUserDto>>
{
    private readonly IApplicationDbContext _context;
    private readonly IAuthProvider _authProvider;
    private readonly ICurrentUserService _currentUser;

    public CreateTeamUserCommandHandler(
        IApplicationDbContext context,
        IAuthProvider authProvider,
        ICurrentUserService currentUser)
    {
        _context = context;
        _authProvider = authProvider;
        _currentUser = currentUser;
    }

    public async Task<Result<TeamUserDto>> Handle(CreateTeamUserCommand request, CancellationToken cancellationToken)
    {
        if (_currentUser.Role != UserRole.ShopOwner || !_currentUser.TenantId.HasValue)
            return Result<TeamUserDto>.Forbidden("Only shop owners can add team users");

        var email = request.Email.Trim().ToLowerInvariant();

        var emailExists = await _context.Users
            .IgnoreQueryFilters()
            .AnyAsync(u => u.Email == email, cancellationToken);

        if (emailExists)
            return Result<TeamUserDto>.Conflict("A user with this email already exists");

        var user = new User
        {
            TenantId = _currentUser.TenantId.Value,
            Email = email,
            PasswordHash = _authProvider.HashPassword(request.Password),
            FullName = request.FullName.Trim(),
            Mobile = request.Mobile.Trim(),
            Role = UserRole.ShopOwner,
            Status = UserStatus.Active
        };

        _context.Users.Add(user);
        await _context.SaveChangesAsync(cancellationToken);

        return Result<TeamUserDto>.Created(new TeamUserDto
        {
            Id = user.Id,
            FullName = user.FullName,
            Email = user.Email,
            Mobile = user.Mobile,
            Role = user.Role.ToString(),
            Status = user.Status.ToString(),
            IsCurrentUser = false,
            LastLoginAt = null,
            CreatedAt = user.CreatedAt
        });
    }
}
