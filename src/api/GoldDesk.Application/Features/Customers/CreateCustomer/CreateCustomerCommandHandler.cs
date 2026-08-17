using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Domain.Entities;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Customers.CreateCustomer;

public class CreateCustomerCommandHandler : IRequestHandler<CreateCustomerCommand, Result<CustomerDto>>
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;

    public CreateCustomerCommandHandler(IApplicationDbContext context, ICurrentUserService currentUser)
    {
        _context = context;
        _currentUser = currentUser;
    }

    public async Task<Result<CustomerDto>> Handle(CreateCustomerCommand request, CancellationToken cancellationToken)
    {
        if (!_currentUser.TenantId.HasValue)
            return Result<CustomerDto>.Unauthorized();

        var ownerBusinessId = _currentUser.TenantId.Value;

        if (request.BusinessId.HasValue && request.BusinessId.Value != ownerBusinessId)
        {
            var currentBusiness = await _context.Tenants
                .AsNoTracking()
                .FirstOrDefaultAsync(t => t.Id == ownerBusinessId, cancellationToken);

            var connected = await _context.BusinessConnections.AnyAsync(c =>
                c.ConnectionType == ConnectionType.ShowroomShop &&
                c.Status == ConnectionStatus.Accepted &&
                ((c.FromBusinessId == ownerBusinessId && c.ToBusinessId == request.BusinessId) ||
                 (c.FromBusinessId == request.BusinessId && c.ToBusinessId == ownerBusinessId)),
                cancellationToken);

            var shop = await _context.Tenants
                .AsNoTracking()
                .FirstOrDefaultAsync(t => t.Id == request.BusinessId.Value, cancellationToken);

            if (currentBusiness?.BusinessType != BusinessType.Showroom ||
                shop?.BusinessType != BusinessType.Shop ||
                !connected)
            {
                return Result<CustomerDto>.Forbidden(
                    "You can only add customers for a connected Shop");
            }

            ownerBusinessId = request.BusinessId.Value;
        }

        var customer = new Customer
        {
            TenantId = ownerBusinessId,
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
