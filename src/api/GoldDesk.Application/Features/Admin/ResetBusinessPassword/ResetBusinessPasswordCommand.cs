using FluentValidation;
using GoldDesk.Application.Common.Models;
using MediatR;

namespace GoldDesk.Application.Features.Admin.ResetBusinessPassword;

public record ResetBusinessPasswordCommand : IRequest<Result<ResetBusinessPasswordResponse>>
{
    public Guid TenantId { get; init; }
    public string NewPassword { get; init; } = string.Empty;
}

public record ResetBusinessPasswordResponse
{
    public Guid TenantId { get; init; }
    public string Email { get; init; } = string.Empty;
    public int UpdatedLogins { get; init; }
    public string Message { get; init; } = string.Empty;
}

public class ResetBusinessPasswordCommandValidator : AbstractValidator<ResetBusinessPasswordCommand>
{
    public ResetBusinessPasswordCommandValidator()
    {
        RuleFor(x => x.TenantId).NotEmpty();
        RuleFor(x => x.NewPassword)
            .NotEmpty().WithMessage("New password is required")
            .MinimumLength(6).WithMessage("New password must be at least 6 characters");
    }
}
