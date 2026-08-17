using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Connections.Dtos;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Connections.GetConnections;

public class GetConnectionsQueryHandler : IRequestHandler<GetConnectionsQuery, Result<List<BusinessConnectionDto>>>
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;

    public GetConnectionsQueryHandler(IApplicationDbContext context, ICurrentUserService currentUser)
    {
        _context = context;
        _currentUser = currentUser;
    }

    public async Task<Result<List<BusinessConnectionDto>>> Handle(GetConnectionsQuery request, CancellationToken cancellationToken)
    {
        if (!_currentUser.TenantId.HasValue)
            return Result<List<BusinessConnectionDto>>.Unauthorized();

        var myId = _currentUser.TenantId.Value;
        var query = _context.BusinessConnections
            .AsNoTracking()
            .Include(c => c.FromBusiness)
            .Include(c => c.ToBusiness)
            .Where(c => c.FromBusinessId == myId || c.ToBusinessId == myId);

        if (!string.IsNullOrWhiteSpace(request.Status) &&
            Enum.TryParse<ConnectionStatus>(request.Status, true, out var status))
        {
            query = query.Where(c => c.Status == status);
        }

        if (!string.IsNullOrWhiteSpace(request.ConnectionType) &&
            Enum.TryParse<ConnectionType>(request.ConnectionType, true, out var type))
        {
            query = query.Where(c => c.ConnectionType == type);
        }

        var rows = await query
            .OrderByDescending(c => c.CreatedAt)
            .ToListAsync(cancellationToken);

        var result = rows.Select(c =>
        {
            var isIncoming = c.ToBusinessId == myId;
            var counterparty = isIncoming ? c.FromBusiness : c.ToBusiness;
            return new BusinessConnectionDto
            {
                Id = c.Id,
                CounterpartyBusinessId = counterparty.Id,
                CounterpartyName = counterparty.ShopName,
                CounterpartyGoldDeskId = counterparty.GoldDeskId,
                CounterpartyBusinessType = counterparty.BusinessType.ToString(),
                ConnectionType = c.ConnectionType.ToString(),
                Status = c.Status.ToString(),
                IsIncoming = isIncoming,
                CreatedAt = c.CreatedAt,
                AcceptedAt = c.AcceptedAt
            };
        }).ToList();

        return Result<List<BusinessConnectionDto>>.Success(result);
    }
}
