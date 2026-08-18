using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Karigars.Dtos;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Karigars.GetKarigars;

public class GetKarigarsQueryHandler : IRequestHandler<GetKarigarsQuery, Result<PagedResult<KarigarDto>>>
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;

    public GetKarigarsQueryHandler(IApplicationDbContext context, ICurrentUserService currentUser)
    {
        _context = context;
        _currentUser = currentUser;
    }

    public async Task<Result<PagedResult<KarigarDto>>> Handle(GetKarigarsQuery request, CancellationToken cancellationToken)
    {
        if (!_currentUser.TenantId.HasValue)
            return Result<PagedResult<KarigarDto>>.Unauthorized();

        var shopId = _currentUser.TenantId.Value;
        var viewer = await _context.Tenants
            .AsNoTracking()
            .FirstOrDefaultAsync(t => t.Id == shopId, cancellationToken);

        if (viewer == null)
            return Result<PagedResult<KarigarDto>>.NotFound("Business profile not found");

        if (viewer.BusinessType != BusinessType.Shop)
            return Result<PagedResult<KarigarDto>>.Forbidden("Connected Karigars are available to shops only");

        var connectedKarigarBusinessIds = await _context.BusinessConnections
            .Where(c => c.ConnectionType == ConnectionType.ShopKarigar &&
                        c.Status == ConnectionStatus.Accepted &&
                        (c.FromBusinessId == shopId || c.ToBusinessId == shopId))
            .Select(c => c.FromBusinessId == shopId ? c.ToBusinessId : c.FromBusinessId)
            .ToListAsync(cancellationToken);

        var karigars = connectedKarigarBusinessIds.Count == 0
            ? Enumerable.Empty<Domain.Entities.Karigar>()
            : (await _context.Karigars
                .IgnoreQueryFilters()
                .Where(k => connectedKarigarBusinessIds.Contains(k.TenantId))
                .ToListAsync(cancellationToken))
                .AsEnumerable();

        if (request.ActiveOnly == true)
        {
            karigars = karigars.Where(k => k.Status == KarigarStatus.Active);
        }

        if (!string.IsNullOrWhiteSpace(request.Search))
        {
            var search = request.Search.ToLower();
            karigars = karigars.Where(k =>
                k.Name.ToLower().Contains(search) ||
                k.Mobile.Contains(search) ||
                (k.Specialization != null && k.Specialization.ToLower().Contains(search)));
        }

        var totalCount = karigars.Count();

        var items = karigars
            .OrderBy(k => k.Name)
            .Skip((request.Page - 1) * request.PageSize)
            .Take(request.PageSize)
            .Select(k => new KarigarDto
            {
                Id = k.Id,
                Name = k.Name,
                Mobile = k.Mobile,
                Email = k.Email,
                Address = k.Address,
                Specialization = k.Specialization,
                Status = k.Status.ToString(),
                HasLoginAccess = k.UserId != null,
                CreatedAt = k.CreatedAt
            })
            .ToList();

        return Result<PagedResult<KarigarDto>>.Success(
            new PagedResult<KarigarDto>(items, totalCount, request.Page, request.PageSize));
    }
}
