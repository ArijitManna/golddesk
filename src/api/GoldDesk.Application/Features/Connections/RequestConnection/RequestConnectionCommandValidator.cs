using FluentValidation;

namespace GoldDesk.Application.Features.Connections.RequestConnection;

public class RequestConnectionCommandValidator : AbstractValidator<RequestConnectionCommand>
{
    public RequestConnectionCommandValidator()
    {
        RuleFor(x => x.TargetGoldDeskId)
            .NotEmpty().WithMessage("GoldDesk ID is required")
            .MaximumLength(30);
        RuleFor(x => x.Notes).MaximumLength(1000);
    }
}
