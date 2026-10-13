using FluentValidation;
using GoldDesk.Application.Common.Models;
using MediatR;

namespace GoldDesk.Application.Features.TeamUsers.ResetTeamUserPassword;

public record ResetTeamUserPasswordCommand(Guid UserId, string OwnerPassword, string NewPassword)
    : IRequest<Result<bool>>;

public record ResetTeamUserPasswordRequest(string OwnerPassword, string NewPassword);

public class ResetTeamUserPasswordCommandValidator : AbstractValidator<ResetTeamUserPasswordCommand>
{
    public ResetTeamUserPasswordCommandValidator()
    {
        RuleFor(x => x.OwnerPassword)
            .NotEmpty().WithMessage("Your password is required");

        RuleFor(x => x.NewPassword)
            .NotEmpty().WithMessage("New password is required")
            .MinimumLength(6).WithMessage("Password must be at least 6 characters");
    }
}
