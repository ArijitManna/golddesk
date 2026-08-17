using FluentValidation;
using GoldDesk.Domain.Enums;

namespace GoldDesk.Application.Features.Auth.Register;

public class RegisterCommandValidator : AbstractValidator<RegisterCommand>
{
    public RegisterCommandValidator()
    {
        RuleFor(x => x.ShopName)
            .NotEmpty().WithMessage("Shop name is required")
            .MaximumLength(200);

        RuleFor(x => x.OwnerName)
            .NotEmpty().WithMessage("Owner name is required")
            .MaximumLength(200);

        RuleFor(x => x.Mobile)
            .NotEmpty().WithMessage("Mobile number is required")
            .Matches(@"^\d{10}$").WithMessage("Mobile must be a 10-digit number");

        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email is required")
            .EmailAddress().WithMessage("Invalid email format")
            .MaximumLength(200);

        RuleFor(x => x.Password)
            .NotEmpty().WithMessage("Password is required")
            .MinimumLength(6).WithMessage("Password must be at least 6 characters")
            .MaximumLength(100);

        RuleFor(x => x.Address)
            .MaximumLength(500);

        RuleFor(x => x.BusinessType)
            .IsInEnum().WithMessage("Choose Showroom, Shop, or Karigar.");
    }
}
