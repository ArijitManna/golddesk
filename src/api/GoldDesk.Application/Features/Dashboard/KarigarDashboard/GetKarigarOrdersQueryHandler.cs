using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Dashboard.KarigarDashboard;

public class GetKarigarOrdersQueryHandler : IRequestHandler<GetKarigarOrdersQuery, Result<PagedResult<KarigarOrderDto>>>
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;

    public GetKarigarOrdersQueryHandler(IApplicationDbContext context, ICurrentUserService currentUser)
    {
        _context = context;
        _currentUser = currentUser;
    }

    public async Task<Result<PagedResult<KarigarOrderDto>>> Handle(GetKarigarOrdersQuery request, CancellationToken cancellationToken)
    {
        var karigar = await _context.Karigars
            .FirstOrDefaultAsync(k => k.UserId == _currentUser.UserId, cancellationToken);

        if (karigar == null)
            return Result<PagedResult<KarigarOrderDto>>.Forbidden("You are not registered as a Karigar");

        var today = DateOnly.FromDateTime(DateTime.Today);

        var query = _context.OrderAssignments
            .Include(a => a.Order)
                .ThenInclude(o => o.Customer)
            .Where(a => a.KarigarId == karigar.Id && a.IsActive);

        // Filter by order status
        if (!string.IsNullOrWhiteSpace(request.Status) &&
            Enum.TryParse<OrderStatus>(request.Status, true, out var status))
        {
            query = query.Where(a => a.Order.Status == status);
        }

        var totalCount = await query.CountAsync(cancellationToken);

        var items = await query
            .OrderBy(a => a.DueDate)
            .Skip((request.Page - 1) * request.PageSize)
            .Take(request.PageSize)
            .Select(a => new KarigarOrderDto
            {
                OrderId = a.OrderId,
                OrderNo = a.Order.OrderNo,
                CustomerName = a.Order.Customer.Name,
                Status = a.Order.Status.ToString(),
                DueDate = a.DueDate.ToString("yyyy-MM-dd"),
                DaysLeft = a.DueDate.DayNumber - today.DayNumber,
                Notes = a.Notes,
                TotalWeight = a.Order.TotalWeight
            })
            .ToListAsync(cancellationToken);

        return Result<PagedResult<KarigarOrderDto>>.Success(
            new PagedResult<KarigarOrderDto>(items, totalCount, request.Page, request.PageSize));
    }
}
