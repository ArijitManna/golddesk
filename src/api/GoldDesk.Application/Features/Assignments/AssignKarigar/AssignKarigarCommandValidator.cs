using FluentValidation;

namespace GoldDesk.Application.Features.Assignments.AssignKarigar;

public class AssignKarigarCommandValidator : AbstractValidator<AssignKarigarCommand>
{
    public AssignKarigarCommandValidator()
    {
        RuleFor(x => x.OrderId).NotEmpty().WithMessage("Order is required");
        RuleFor(x => x.KarigarId).NotEmpty().WithMessage("Karigar is required");
        RuleFor(x => x.GivenDate).NotEmpty().WithMessage("Given date is required");
    }
}
