using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Orders.Dtos;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Orders.GetOrders;

public class GetOrdersQueryHandler : IRequestHandler<GetOrdersQuery, Result<PagedResult<OrderDto>>>
{
    private readonly IApplicationDbContext _context;

    public GetOrdersQueryHandler(IApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<Result<PagedResult<OrderDto>>> Handle(GetOrdersQuery request, CancellationToken cancellationToken)
    {
        var query = _context.Orders
            .Include(o => o.Customer)
            .Include(o => o.Assignments.Where(a => a.IsActive))
                .ThenInclude(a => a.Karigar)
            .AsQueryable();

        // Filter by status
        if (!string.IsNullOrWhiteSpace(request.Status) &&
            Enum.TryParse<OrderStatus>(request.Status, true, out var status))
        {
            query = query.Where(o => o.Status == status);
        }

        // Search by order number or customer name
        if (!string.IsNullOrWhiteSpace(request.Search))
        {
            var search = request.Search.ToLower();
            query = query.Where(o =>
                o.OrderNo.ToLower().Contains(search) ||
                o.Customer.Name.ToLower().Contains(search));
        }

        var totalCount = await query.CountAsync(cancellationToken);

        var items = await query
            .OrderByDescending(o => o.CreatedAt)
            .Skip((request.Page - 1) * request.PageSize)
            .Take(request.PageSize)
            .Select(o => new OrderDto
            {
                Id = o.Id,
                OrderNo = o.OrderNo,
                CustomerName = o.Customer.Name,
                CustomerId = o.CustomerId,
                OrderDate = o.OrderDate.ToString("yyyy-MM-dd"),
                DeliveryDate = o.DeliveryDate != null ? o.DeliveryDate.Value.ToString("yyyy-MM-dd") : null,
                Status = o.Status.ToString(),
                TotalWeight = o.TotalWeight,
                MakingCharges = o.MakingCharges,
                AdvancePaid = o.AdvancePaid,
                EstimatedAmount = o.EstimatedAmount,
                Notes = o.Notes,
                KarigarName = o.Assignments.Where(a => a.IsActive).Select(a => a.Karigar.Name).FirstOrDefault(),
                DueDate = o.Assignments.Where(a => a.IsActive).Select(a => a.DueDate.ToString("yyyy-MM-dd")).FirstOrDefault(),
                FirstItemImage = o.Items.Select(i => i.ImagePath).FirstOrDefault(p => p != null),
                CreatedAt = o.CreatedAt
            })
            .ToListAsync(cancellationToken);

        return Result<PagedResult<OrderDto>>.Success(
            new PagedResult<OrderDto>(items, totalCount, request.Page, request.PageSize));
    }
}
