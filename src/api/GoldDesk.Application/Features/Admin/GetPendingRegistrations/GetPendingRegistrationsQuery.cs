using GoldDesk.Application.Common.Models;
using MediatR;

namespace GoldDesk.Application.Features.Admin.GetPendingRegistrations;

public record GetPendingRegistrationsQuery : IRequest<Result<List<PendingRegistrationDto>>>
{
    public string? Search { get; init; }
    public string? BusinessType { get; init; }
}

public record PendingRegistrationDto
{
    public Guid TenantId { get; init; }
    public string ShopName { get; init; } = string.Empty;
    public string OwnerName { get; init; } = string.Empty;
    public string Mobile { get; init; } = string.Empty;
    public string Email { get; init; } = string.Empty;
    public string? Address { get; init; }
    public string BusinessType { get; init; } = string.Empty;
    public DateTime RegisteredAt { get; init; }
}
