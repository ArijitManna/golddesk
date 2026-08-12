using FluentValidation;

namespace GoldDesk.Application.Features.ShopProfile.UpdateTenantProfile;

public class UpdateTenantProfileCommandValidator : AbstractValidator<UpdateTenantProfileCommand>
{
    public UpdateTenantProfileCommandValidator()
    {
        RuleFor(x => x.ShopName)
            .NotEmpty().WithMessage("Shop name is required")
            .MaximumLength(200);

        RuleFor(x => x.OwnerName)
            .NotEmpty().WithMessage("Owner name is required")
            .MaximumLength(200);

        RuleFor(x => x.Mobile)
            .NotEmpty().WithMessage("Mobile is required")
            .Matches(@"^\d{10}$").WithMessage("Mobile must be a 10-digit number");

        RuleFor(x => x.Address).MaximumLength(500);
        RuleFor(x => x.GstNumber).MaximumLength(50);
    }
}
