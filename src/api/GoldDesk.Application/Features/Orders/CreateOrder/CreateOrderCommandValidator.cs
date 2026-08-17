using FluentValidation;

namespace GoldDesk.Application.Features.Orders.CreateOrder;

public class CreateOrderCommandValidator : AbstractValidator<CreateOrderCommand>
{
    public CreateOrderCommandValidator()
    {
        RuleFor(x => x)
            .Must(x => x.OrderFromBusinessId.HasValue != x.OrderFromExternalBusinessId.HasValue)
            .WithMessage("Specify exactly one Order From business.");

        RuleFor(x => x.Items)
            .NotEmpty().WithMessage("At least one item is required");

        RuleFor(x => x.AdvancePaid)
            .GreaterThanOrEqualTo(0).WithMessage("Advance paid cannot be negative");

        RuleForEach(x => x.Items).ChildRules(item =>
        {
            item.RuleFor(i => i.ItemName)
                .NotEmpty().WithMessage("Item name is required");

            item.RuleFor(i => i.Weight)
                .GreaterThanOrEqualTo(0).WithMessage("Weight cannot be negative");

            item.RuleFor(i => i.Quantity)
                .GreaterThan(0).WithMessage("Quantity must be at least 1");

            item.RuleFor(i => i.Amount)
                .GreaterThanOrEqualTo(0).WithMessage("Amount cannot be negative");
        });
    }
}
