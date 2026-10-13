using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.TeamUsers.ResetTeamUserPassword;

public class ResetTeamUserPasswordCommandHandler : IRequestHandler<ResetTeamUserPasswordCommand, Result<bool>>
{
    private readonly IApplicationDbContext _context;
    private readonly IAuthProvider _authProvider;
    private readonly ICurrentUserService _currentUser;

    public ResetTeamUserPasswordCommandHandler(
        IApplicationDbContext context,
        IAuthProvider authProvider,
        ICurrentUserService currentUser)
    {
        _context = context;
        _authProvider = authProvider;
        _currentUser = currentUser;
    }

    public async Task<Result<bool>> Handle(ResetTeamUserPasswordCommand request, CancellationToken cancellationToken)
    {
        if (_currentUser.Role != UserRole.ShopOwner)
            return Result<bool>.Forbidden("Only shop owners can reset team user passwords");

        if (!_currentUser.TenantId.HasValue || !_currentUser.UserId.HasValue)
            return Result<bool>.Unauthorized();

        if (_currentUser.UserId == request.UserId)
            return Result<bool>.Failure("Use Change Password in Settings to change your own password");

        var owner = await _context.Users
            .FirstOrDefaultAsync(u => u.Id == _currentUser.UserId.Value, cancellationToken);

        if (owner == null)
            return Result<bool>.Unauthorized();

        if (!_authProvider.VerifyPassword(request.OwnerPassword, owner.PasswordHash))
            return Result<bool>.Failure("Your password is incorrect");

        var user = await _context.Users
            .FirstOrDefaultAsync(u => u.Id == request.UserId &&
                                      u.TenantId == _currentUser.TenantId.Value &&
                                      u.Role == UserRole.ShopOwner, cancellationToken);

        if (user == null)
            return Result<bool>.NotFound("Team user not found");

        // A login shared with another business must only be changed by its owner.
        var sharedWithOtherBusiness = await _context.Users
            .IgnoreQueryFilters()
            .AnyAsync(u => u.Email == user.Email &&
                           u.Id != user.Id &&
                           u.TenantId != _currentUser.TenantId.Value, cancellationToken);

        if (sharedWithOtherBusiness)
            return Result<bool>.Failure(
                "This login is also used for another business. Ask the user to change it from their own account.");

        user.PasswordHash = _authProvider.HashPassword(request.NewPassword);
        user.RefreshToken = null;
        user.RefreshTokenExpiryTime = null;

        await _context.SaveChangesAsync(cancellationToken);

        return Result<bool>.Success(true);
    }
}
