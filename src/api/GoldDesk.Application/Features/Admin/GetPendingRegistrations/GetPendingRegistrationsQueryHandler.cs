using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Admin.GetPendingRegistrations;

public class GetPendingRegistrationsQueryHandler
    : IRequestHandler<GetPendingRegistrationsQuery, Result<List<PendingRegistrationDto>>>
{
    private readonly IApplicationDbContext _context;

    public GetPendingRegistrationsQueryHandler(IApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<Result<List<PendingRegistrationDto>>> Handle(
        GetPendingRegistrationsQuery request,
        CancellationToken cancellationToken)
    {
        var query = _context.Tenants
            .IgnoreQueryFilters()
            .Where(t => t.Status == TenantStatus.PendingApproval);

        if (!string.IsNullOrWhiteSpace(request.Search))
        {
            var search = request.Search.ToLower();
            query = query.Where(t =>
                t.ShopName.ToLower().Contains(search) ||
                t.OwnerName.ToLower().Contains(search) ||
                t.Mobile.Contains(search) ||
                t.Email.ToLower().Contains(search));
        }

        var results = await query
            .OrderByDescending(t => t.CreatedAt)
            .Select(t => new PendingRegistrationDto
            {
                TenantId = t.Id,
                ShopName = t.ShopName,
                OwnerName = t.OwnerName,
                Mobile = t.Mobile,
                Email = t.Email,
                Address = t.Address,
                RegisteredAt = t.CreatedAt
            })
            .ToListAsync(cancellationToken);

        return Result<List<PendingRegistrationDto>>.Success(results);
    }
}
