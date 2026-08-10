using FluentValidation;

namespace GoldDesk.Application.Features.Karigars.CreateKarigar;

public class CreateKarigarCommandValidator : AbstractValidator<CreateKarigarCommand>
{
    public CreateKarigarCommandValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Karigar name is required")
            .MaximumLength(200);

        RuleFor(x => x.Mobile)
            .NotEmpty().WithMessage("Mobile number is required")
            .Matches(@"^\d{10}$").WithMessage("Mobile must be a 10-digit number");

        RuleFor(x => x.Email)
            .MaximumLength(200)
            .EmailAddress().When(x => !string.IsNullOrEmpty(x.Email))
            .WithMessage("Invalid email format");

        RuleFor(x => x.Address).MaximumLength(500);
        RuleFor(x => x.Specialization).MaximumLength(200);

        RuleFor(x => x.Password)
            .NotEmpty().When(x => x.CreateLogin)
            .WithMessage("Password is required when creating login access")
            .MinimumLength(6).When(x => x.CreateLogin)
            .WithMessage("Password must be at least 6 characters");
    }
}
