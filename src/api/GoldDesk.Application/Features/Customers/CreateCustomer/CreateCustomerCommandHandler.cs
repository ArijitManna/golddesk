using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Domain.Entities;
using MediatR;

namespace GoldDesk.Application.Features.Customers.CreateCustomer;

public class CreateCustomerCommandHandler : IRequestHandler<CreateCustomerCommand, Result<CustomerDto>>
{
    private readonly IApplicationDbContext _context;

    public CreateCustomerCommandHandler(IApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<Result<CustomerDto>> Handle(CreateCustomerCommand request, CancellationToken cancellationToken)
    {
        var customer = new Customer
        {
            Name = request.Name,
            Mobile = request.Mobile,
            Email = request.Email,
            Address = request.Address,
            Notes = request.Notes,
            IsActive = true
        };

        _context.Customers.Add(customer);
        await _context.SaveChangesAsync(cancellationToken);

        return Result<CustomerDto>.Created(new CustomerDto
        {
            Id = customer.Id,
            Name = customer.Name,
            Mobile = customer.Mobile,
            Email = customer.Email,
            Address = customer.Address,
            Notes = customer.Notes,
            IsActive = customer.IsActive,
            CreatedAt = customer.CreatedAt
        });
    }
}
