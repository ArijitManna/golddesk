using FluentValidation;

namespace GoldDesk.Application.Features.TeamUsers.CreateTeamUser;

public class CreateTeamUserCommandValidator : AbstractValidator<CreateTeamUserCommand>
{
    public CreateTeamUserCommandValidator()
    {
        RuleFor(x => x.FullName)
            .NotEmpty().WithMessage("Name is required")
            .MaximumLength(200);

        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email is required")
            .EmailAddress().WithMessage("Invalid email format")
            .MaximumLength(200);

        RuleFor(x => x.Mobile)
            .NotEmpty().WithMessage("Mobile number is required")
            .Matches(@"^\d{10}$").WithMessage("Mobile must be a 10-digit number");

        RuleFor(x => x.Password)
            .NotEmpty().WithMessage("Password is required")
            .MinimumLength(6).WithMessage("Password must be at least 6 characters");
    }
}
