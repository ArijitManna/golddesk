using GoldDesk.Application.Common.Models;
using MediatR;

namespace GoldDesk.Application.Features.Customers.DeleteCustomer;

public record DeleteCustomerCommand(Guid Id) : IRequest<Result<bool>>;
