using FluentValidation;

namespace GoldDesk.Application.Features.Items.CreateItem;

public class CreateItemCommandValidator : AbstractValidator<CreateItemCommand>
{
    public CreateItemCommandValidator()
    {
        RuleFor(x => x.ItemCode)
            .NotEmpty().WithMessage("Item code is required")
            .MaximumLength(50);

        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Item name is required")
            .MaximumLength(200);

        RuleFor(x => x.Category).MaximumLength(100);
        RuleFor(x => x.Purity).MaximumLength(20);

        RuleFor(x => x.DefaultRate)
            .GreaterThanOrEqualTo(0).When(x => x.DefaultRate.HasValue)
            .WithMessage("Default rate cannot be negative");

        RuleFor(x => x.DefaultMakingCharge)
            .GreaterThanOrEqualTo(0).When(x => x.DefaultMakingCharge.HasValue)
            .WithMessage("Default making charge cannot be negative");
    }
}
