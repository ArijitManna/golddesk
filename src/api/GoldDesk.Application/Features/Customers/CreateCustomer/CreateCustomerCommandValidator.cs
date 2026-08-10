using FluentValidation;

namespace GoldDesk.Application.Features.Customers.CreateCustomer;

public class CreateCustomerCommandValidator : AbstractValidator<CreateCustomerCommand>
{
    public CreateCustomerCommandValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Customer name is required")
            .MaximumLength(200);

        RuleFor(x => x.Mobile)
            .MaximumLength(20)
            .Matches(@"^\d{10}$").When(x => !string.IsNullOrEmpty(x.Mobile))
            .WithMessage("Mobile must be a 10-digit number");

        RuleFor(x => x.Email)
            .MaximumLength(200)
            .EmailAddress().When(x => !string.IsNullOrEmpty(x.Email))
            .WithMessage("Invalid email format");

        RuleFor(x => x.Address).MaximumLength(500);
        RuleFor(x => x.Notes).MaximumLength(1000);
    }
}
