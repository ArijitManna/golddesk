using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Customers.CreateCustomer;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Customers.UpdateCustomer;

public class UpdateCustomerCommandHandler : IRequestHandler<UpdateCustomerCommand, Result<CustomerDto>>
{
    private readonly IApplicationDbContext _context;

    public UpdateCustomerCommandHandler(IApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<Result<CustomerDto>> Handle(UpdateCustomerCommand request, CancellationToken cancellationToken)
    {
        var customer = await _context.Customers
            .FirstOrDefaultAsync(c => c.Id == request.Id, cancellationToken);

        if (customer == null)
            return Result<CustomerDto>.NotFound("Customer not found");

        customer.Name = request.Name;
        customer.Mobile = request.Mobile;
        customer.Email = request.Email;
        customer.Address = request.Address;
        customer.Notes = request.Notes;

        await _context.SaveChangesAsync(cancellationToken);

        return Result<CustomerDto>.Success(new CustomerDto
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
