using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Customers.CreateCustomer;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Customers.GetCustomers;

public class GetCustomersQueryHandler : IRequestHandler<GetCustomersQuery, Result<PagedResult<CustomerDto>>>
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;

    public GetCustomersQueryHandler(IApplicationDbContext context, ICurrentUserService currentUser)
    {
        _context = context;
        _currentUser = currentUser;
    }

    public async Task<Result<PagedResult<CustomerDto>>> Handle(GetCustomersQuery request, CancellationToken cancellationToken)
    {
        if (!_currentUser.TenantId.HasValue)
            return Result<PagedResult<CustomerDto>>.Unauthorized();

        var businessId = request.BusinessId ?? _currentUser.TenantId.Value;
        if (businessId != _currentUser.TenantId.Value)
        {
            var currentBusiness = await _context.Tenants
                .AsNoTracking()
                .FirstOrDefaultAsync(t => t.Id == _currentUser.TenantId.Value, cancellationToken);

            var connected = await _context.BusinessConnections.AnyAsync(c =>
                c.ConnectionType == ConnectionType.ShowroomShop &&
                c.Status == ConnectionStatus.Accepted &&
                ((c.FromBusinessId == _currentUser.TenantId.Value && c.ToBusinessId == businessId) ||
                 (c.FromBusinessId == businessId && c.ToBusinessId == _currentUser.TenantId.Value)),
                cancellationToken);

            if (currentBusiness?.BusinessType != BusinessType.Showroom || !connected)
                return Result<PagedResult<CustomerDto>>.Forbidden("You can only view customers for a connected Shop");
        }

        var query = _context.Customers
            .IgnoreQueryFilters()
            .Where(c => c.TenantId == businessId && c.IsActive);

        if (!string.IsNullOrWhiteSpace(request.Search))
        {
            var search = request.Search.ToLower();
            query = query.Where(c =>
                c.Name.ToLower().Contains(search) ||
                (c.Mobile != null && c.Mobile.Contains(search)) ||
                (c.Email != null && c.Email.ToLower().Contains(search)));
        }

        var totalCount = await query.CountAsync(cancellationToken);

        var items = await query
            .OrderBy(c => c.Name)
            .Skip((request.Page - 1) * request.PageSize)
            .Take(request.PageSize)
            .Select(c => new CustomerDto
            {
                Id = c.Id,
                Name = c.Name,
                Mobile = c.Mobile,
                Email = c.Email,
                Address = c.Address,
                Notes = c.Notes,
                IsActive = c.IsActive,
                CreatedAt = c.CreatedAt
            })
            .ToListAsync(cancellationToken);

        return Result<PagedResult<CustomerDto>>.Success(
            new PagedResult<CustomerDto>(items, totalCount, request.Page, request.PageSize));
    }
}
