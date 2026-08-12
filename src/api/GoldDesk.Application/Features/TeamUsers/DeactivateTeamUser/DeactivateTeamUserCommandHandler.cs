using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.TeamUsers.DeactivateTeamUser;

public class DeactivateTeamUserCommandHandler : IRequestHandler<DeactivateTeamUserCommand, Result<bool>>
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;

    public DeactivateTeamUserCommandHandler(IApplicationDbContext context, ICurrentUserService currentUser)
    {
        _context = context;
        _currentUser = currentUser;
    }

    public async Task<Result<bool>> Handle(DeactivateTeamUserCommand request, CancellationToken cancellationToken)
    {
        if (_currentUser.Role != UserRole.ShopOwner)
            return Result<bool>.Forbidden("Only shop owners can deactivate team users");

        if (_currentUser.UserId == request.UserId)
            return Result<bool>.Failure("You cannot deactivate your own account");

        var user = await _context.Users
            .FirstOrDefaultAsync(u => u.Id == request.UserId && u.Role == UserRole.ShopOwner, cancellationToken);

        if (user == null)
            return Result<bool>.NotFound("Team user not found");

        if (user.Status == UserStatus.Inactive)
            return Result<bool>.Failure("User is already inactive");

        var activeOwners = await _context.Users
            .CountAsync(u => u.Role == UserRole.ShopOwner && u.Status == UserStatus.Active, cancellationToken);

        if (activeOwners <= 1)
            return Result<bool>.Failure("Cannot deactivate the last active shop owner");

        user.Status = UserStatus.Inactive;
        user.RefreshToken = null;
        user.RefreshTokenExpiryTime = null;

        await _context.SaveChangesAsync(cancellationToken);

        return Result<bool>.Success(true);
    }
}
