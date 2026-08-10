using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Customers.CreateCustomer;
using MediatR;

namespace GoldDesk.Application.Features.Customers.UpdateCustomer;

public record UpdateCustomerCommand : IRequest<Result<CustomerDto>>
{
    public Guid Id { get; init; }
    public string Name { get; init; } = string.Empty;
    public string? Mobile { get; init; }
    public string? Email { get; init; }
    public string? Address { get; init; }
    public string? Notes { get; init; }
}
