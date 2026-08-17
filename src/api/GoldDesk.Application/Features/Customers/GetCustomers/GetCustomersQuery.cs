using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Customers.CreateCustomer;
using MediatR;

namespace GoldDesk.Application.Features.Customers.GetCustomers;

public record GetCustomersQuery : IRequest<Result<PagedResult<CustomerDto>>>
{
    /// <summary>
    /// Reads a connected Shop's customers for Showroom→Shop order creation.
    /// Omit for the current business's customers.
    /// </summary>
    public Guid? BusinessId { get; init; }
    public string? Search { get; init; }
    public int Page { get; init; } = 1;
    public int PageSize { get; init; } = 20;
}
