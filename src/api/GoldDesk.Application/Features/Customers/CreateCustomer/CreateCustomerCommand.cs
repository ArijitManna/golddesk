using GoldDesk.Application.Common.Models;
using MediatR;

namespace GoldDesk.Application.Features.Customers.CreateCustomer;

public record CreateCustomerCommand : IRequest<Result<CustomerDto>>
{
    public string Name { get; init; } = string.Empty;
    public string? Mobile { get; init; }
    public string? Email { get; init; }
    public string? Address { get; init; }
    public string? Notes { get; init; }
    /// <summary>When set by a Showroom, creates the customer under a connected Shop.</summary>
    public Guid? BusinessId { get; init; }
}

public record CustomerDto
{
    public Guid Id { get; init; }
    public string Name { get; init; } = string.Empty;
    public string? Mobile { get; init; }
    public string? Email { get; init; }
    public string? Address { get; init; }
    public string? Notes { get; init; }
    public bool IsActive { get; init; }
    public DateTime CreatedAt { get; init; }
}
