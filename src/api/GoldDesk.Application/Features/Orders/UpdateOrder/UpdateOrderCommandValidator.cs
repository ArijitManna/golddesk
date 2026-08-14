using FluentValidation;

namespace GoldDesk.Application.Features.Orders.UpdateOrder;

public class UpdateOrderCommandValidator : AbstractValidator<UpdateOrderCommand>
{
    public UpdateOrderCommandValidator()
    {
        RuleFor(x => x.CustomerId)
            .NotEmpty().WithMessage("Customer is required");

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
