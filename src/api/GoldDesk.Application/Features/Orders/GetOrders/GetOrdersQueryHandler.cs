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
    private readonly ICurrentUserService _currentUser;

    public GetOrdersQueryHandler(IApplicationDbContext context, ICurrentUserService currentUser)
    {
        _context = context;
        _currentUser = currentUser;
    }

    public async Task<Result<PagedResult<OrderDto>>> Handle(GetOrdersQuery request, CancellationToken cancellationToken)
    {
        if (!_currentUser.TenantId.HasValue)
            return Result<PagedResult<OrderDto>>.Unauthorized();

        var tenantId = _currentUser.TenantId.Value;
        var viewer = await _context.Tenants
            .AsNoTracking()
            .FirstOrDefaultAsync(t => t.Id == tenantId, cancellationToken);
        if (viewer == null)
            return Result<PagedResult<OrderDto>>.NotFound("Business profile not found");

        var isShowroomViewer = viewer.BusinessType == BusinessType.Showroom;

        // Ignore related tenant filters so connected business orders remain visible.
        var query = _context.Orders
            .IgnoreQueryFilters()
            .Include(o => o.CreatedByBusiness)
            .Include(o => o.OrderFromBusiness)
            .Include(o => o.OrderFromExternalBusiness)
            .Include(o => o.Tenant)
            .Include(o => o.Items)
            .Include(o => o.Assignments)
                .ThenInclude(a => a.Karigar)
            .Where(o => o.TenantId == tenantId ||
                        o.CreatedByBusinessId == tenantId ||
                        o.OrderFromBusinessId == tenantId);

        // Filter by status
        if (!string.IsNullOrWhiteSpace(request.Status) &&
            Enum.TryParse<OrderStatus>(request.Status, true, out var status))
        {
            query = query.Where(o => o.Status == status);
        }

        // Filter by due date (active assignment, not Ready/Delivered/Cancelled)
        if (!string.IsNullOrWhiteSpace(request.Due))
        {
            var today = DateOnly.FromDateTime(DateTime.Today);
            var threeDaysLater = today.AddDays(3);
            var dueKey = request.Due.Trim().ToLowerInvariant();

            query = query.Where(o =>
                o.Status != OrderStatus.Ready &&
                o.Status != OrderStatus.Delivered &&
                o.Status != OrderStatus.Cancelled &&
                o.Assignments.Any(a => a.IsActive));

            query = dueKey switch
            {
                "today" => query.Where(o =>
                    o.Assignments.Any(a => a.IsActive && a.DueDate == today)),
                "overdue" => query.Where(o =>
                    o.Assignments.Any(a => a.IsActive && a.DueDate < today)),
                "next3" => query.Where(o =>
                    o.Assignments.Any(a => a.IsActive && a.DueDate > today && a.DueDate <= threeDaysLater)),
                _ => query
            };
        }

        if (!string.IsNullOrWhiteSpace(request.Source) &&
            Enum.TryParse<OrderSource>(request.Source, true, out var source))
        {
            query = query.Where(o => o.Source == source);
        }

        if (request.ShopId.HasValue)
        {
            query = query.Where(o => o.TenantId == request.ShopId.Value);
        }

        if (request.ShowroomId.HasValue)
        {
            query = query.Where(o => o.CreatedByBusinessId == request.ShowroomId.Value);
        }

        if (request.ExternalCustomerId.HasValue)
        {
            query = query.Where(o => o.OrderFromExternalBusinessId == request.ExternalCustomerId.Value);
        }

        // Search by order number or order-from business.
        if (!string.IsNullOrWhiteSpace(request.Search))
        {
            var search = request.Search.ToLower();
            query = query.Where(o =>
                o.OrderNo.ToLower().Contains(search) ||
                (o.OrderFromBusiness != null && o.OrderFromBusiness.ShopName.ToLower().Contains(search)) ||
                (o.OrderFromExternalBusiness != null && o.OrderFromExternalBusiness.Name.ToLower().Contains(search)));
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
                OrderFromBusinessId = o.OrderFromBusinessId,
                OrderFromExternalBusinessId = o.OrderFromExternalBusinessId,
                OrderFromBusinessName = o.OrderFromBusiness != null
                    ? o.OrderFromBusiness.ShopName
                    : o.OrderFromExternalBusiness != null
                        ? o.OrderFromExternalBusiness.Name
                        : string.Empty,
                OrderDate = o.OrderDate.ToString("yyyy-MM-dd"),
                DeliveryDate = o.DeliveryDate != null ? o.DeliveryDate.Value.ToString("yyyy-MM-dd") : null,
                Status = o.Status.ToString(),
                AcceptanceStatus = o.AcceptanceStatus.ToString(),
                AcceptanceNote = o.AcceptanceNote,
                TotalWeight = o.TotalWeight,
                MakingCharges = o.MakingCharges,
                AdvancePaid = o.AdvancePaid,
                EstimatedAmount = o.EstimatedAmount,
                Notes = o.Notes,
                // Showrooms only participate through the fulfilling Shop.
                // Karigar identities and work-assignment details are Shop-private.
                KarigarName = isShowroomViewer
                    ? null
                    : o.Assignments
                        .OrderByDescending(a => a.IsActive)
                        .ThenByDescending(a => a.CreatedAt)
                        .Select(a => a.Karigar != null ? a.Karigar.Name : null)
                        .FirstOrDefault(),
                AssignmentStatus = isShowroomViewer
                    ? null
                    : o.Assignments
                        .Where(a => a.IsActive)
                        .Select(a => a.Status.ToString())
                        .FirstOrDefault(),
                DueDate = isShowroomViewer
                    ? (o.DeliveryDate != null ? o.DeliveryDate.Value.ToString("yyyy-MM-dd") : null)
                    : o.Assignments
                        .Where(a => a.IsActive)
                        .Select(a => a.DueDate.ToString("yyyy-MM-dd"))
                        .FirstOrDefault()
                        ?? o.Assignments
                            .OrderByDescending(a => a.CreatedAt)
                            .Select(a => a.DueDate.ToString("yyyy-MM-dd"))
                            .FirstOrDefault()
                        ?? (o.DeliveryDate != null ? o.DeliveryDate.Value.ToString("yyyy-MM-dd") : null),
                FirstItemImage = o.Items.Select(i => i.ImagePath).FirstOrDefault(p => p != null),
                FirstItemSize = o.Items
                    .Where(i => i.Size != null && i.Size != "")
                    .Select(i => i.Size)
                    .FirstOrDefault(),
                Source = o.Source.ToString(),
                CreatedByBusinessId = o.CreatedByBusinessId,
                CreatedByBusinessName = o.CreatedByBusiness.ShopName,
                CreatedForBusinessId = o.TenantId,
                CreatedForBusinessName = o.Tenant.ShopName,
                CreatedAt = o.CreatedAt
            })
            .ToListAsync(cancellationToken);

        return Result<PagedResult<OrderDto>>.Success(
            new PagedResult<OrderDto>(items, totalCount, request.Page, request.PageSize));
    }
}
