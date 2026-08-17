using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Connections.Dtos;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Connections.SearchBusiness;

public class SearchBusinessQueryHandler : IRequestHandler<SearchBusinessQuery, Result<BusinessSummaryDto>>
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;

    public SearchBusinessQueryHandler(IApplicationDbContext context, ICurrentUserService currentUser)
    {
        _context = context;
        _currentUser = currentUser;
    }

    public async Task<Result<BusinessSummaryDto>> Handle(SearchBusinessQuery request, CancellationToken cancellationToken)
    {
        if (!_currentUser.TenantId.HasValue)
            return Result<BusinessSummaryDto>.Unauthorized();

        var code = request.GoldDeskId.Trim().ToUpperInvariant();
        if (string.IsNullOrWhiteSpace(code))
            return Result<BusinessSummaryDto>.Failure("GoldDesk ID is required");

        var business = await _context.Tenants
            .AsNoTracking()
            .FirstOrDefaultAsync(t => t.GoldDeskId == code, cancellationToken);

        if (business == null || business.Status != TenantStatus.Active)
            return Result<BusinessSummaryDto>.NotFound("No active business found with that GoldDesk ID");

        return Result<BusinessSummaryDto>.Success(new BusinessSummaryDto
        {
            Id = business.Id,
            Name = business.ShopName,
            GoldDeskId = business.GoldDeskId,
            BusinessType = business.BusinessType.ToString(),
            Mobile = business.Mobile,
            Address = business.Address
        });
    }
}
