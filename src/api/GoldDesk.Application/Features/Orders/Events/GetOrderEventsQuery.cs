using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Orders.Events;

public record GetOrderEventsQuery(Guid OrderId) : IRequest<Result<List<OrderEventDto>>>;

public record OrderEventDto
{
    public string EventType { get; init; } = string.Empty;
    public string Description { get; init; } = string.Empty;
    public string BusinessName { get; init; } = string.Empty;
    public DateTime OccurredAt { get; init; }
}

public class GetOrderEventsQueryHandler
    : IRequestHandler<GetOrderEventsQuery, Result<List<OrderEventDto>>>
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;

    public GetOrderEventsQueryHandler(IApplicationDbContext context, ICurrentUserService currentUser)
    {
        _context = context;
        _currentUser = currentUser;
    }

    public async Task<Result<List<OrderEventDto>>> Handle(GetOrderEventsQuery request, CancellationToken cancellationToken)
    {
        if (!_currentUser.TenantId.HasValue) return Result<List<OrderEventDto>>.Unauthorized();
        var businessId = _currentUser.TenantId.Value;
        var order = await _context.Orders.IgnoreQueryFilters()
            .AsNoTracking()
            .FirstOrDefaultAsync(o =>
                o.Id == request.OrderId &&
                (o.TenantId == businessId || o.OrderFromBusinessId == businessId ||
                 o.CreatedByBusinessId == businessId), cancellationToken);
        if (order == null) return Result<List<OrderEventDto>>.NotFound("Order not found.");

        var isShop = order.TenantId == businessId;
        var showroomVisibleEvents = new[]
        {
            "OrderCreated",
            "OrderAccepted",
            "OrderRejected",
            "WorkReady"
        };

        IQueryable<Domain.Entities.OrderEvent> eventsQuery = _context.OrderEvents.AsNoTracking()
            .Where(e => e.OrderId == request.OrderId)
            .OrderBy(e => e.CreatedAt);

        if (!isShop)
            eventsQuery = eventsQuery.Where(e => showroomVisibleEvents.Contains(e.EventType));

        var events = await eventsQuery
            .Select(e => new OrderEventDto
            {
                EventType = e.EventType,
                Description = !isShop && e.EventType == "WorkReady"
                    ? "Work is ready"
                    : e.Description,
                BusinessName = !isShop && e.EventType == "WorkReady"
                    ? "Shop"
                    : e.Business.ShopName,
                OccurredAt = e.CreatedAt
            }).ToListAsync(cancellationToken);
        return Result<List<OrderEventDto>>.Success(events);
    }
}
