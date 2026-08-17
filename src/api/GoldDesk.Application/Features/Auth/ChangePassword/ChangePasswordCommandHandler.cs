using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Auth.ChangePassword;

public class ChangePasswordCommandHandler : IRequestHandler<ChangePasswordCommand, Result<bool>>
{
    private readonly IApplicationDbContext _context;
    private readonly IAuthProvider _authProvider;
    private readonly ICurrentUserService _currentUser;

    public ChangePasswordCommandHandler(
        IApplicationDbContext context,
        IAuthProvider authProvider,
        ICurrentUserService currentUser)
    {
        _context = context;
        _authProvider = authProvider;
        _currentUser = currentUser;
    }

    public async Task<Result<bool>> Handle(ChangePasswordCommand request, CancellationToken cancellationToken)
    {
        if (!_currentUser.UserId.HasValue)
            return Result<bool>.Unauthorized();

        var user = await _context.Users
            .FirstOrDefaultAsync(u => u.Id == _currentUser.UserId.Value, cancellationToken);

        if (user == null)
            return Result<bool>.NotFound("User not found");

        if (!_authProvider.VerifyPassword(request.CurrentPassword, user.PasswordHash))
            return Result<bool>.Failure("Current password is incorrect");

        if (request.CurrentPassword == request.NewPassword)
            return Result<bool>.Failure("New password must be different from current password");

        var passwordHash = _authProvider.HashPassword(request.NewPassword);
        var linkedProfiles = await _context.Users
            .IgnoreQueryFilters()
            .Where(u => u.Email == user.Email)
            .ToListAsync(cancellationToken);
        foreach (var profile in linkedProfiles)
            profile.PasswordHash = passwordHash;

        await _context.SaveChangesAsync(cancellationToken);

        return Result<bool>.Success(true);
    }
}
