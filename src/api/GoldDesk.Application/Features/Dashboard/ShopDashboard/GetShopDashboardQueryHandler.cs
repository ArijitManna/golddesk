using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Orders.Dtos;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Dashboard.ShopDashboard;

public class GetShopDashboardQueryHandler : IRequestHandler<GetShopDashboardQuery, Result<ShopDashboardDto>>
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;

    public GetShopDashboardQueryHandler(IApplicationDbContext context, ICurrentUserService currentUser)
    {
        _context = context;
        _currentUser = currentUser;
    }

    public async Task<Result<ShopDashboardDto>> Handle(GetShopDashboardQuery request, CancellationToken cancellationToken)
    {
        if (!_currentUser.TenantId.HasValue)
            return Result<ShopDashboardDto>.Unauthorized();

        var business = await _context.Tenants
            .AsNoTracking()
            .FirstOrDefaultAsync(t => t.Id == _currentUser.TenantId.Value, cancellationToken);
        if (business == null)
            return Result<ShopDashboardDto>.NotFound("Business profile not found");

        var today = DateOnly.FromDateTime(DateTime.Today);
        var threeDaysLater = today.AddDays(3);

        // Active statuses (not delivered/closed/cancelled)
        var activeStatuses = new[]
        {
            OrderStatus.Pending, OrderStatus.Assigned, OrderStatus.InProgress, OrderStatus.Ready
        };

        var orders = await _context.Orders
            .IgnoreQueryFilters()
            .Include(o => o.CreatedByBusiness)
            .Include(o => o.OrderFromBusiness)
            .Include(o => o.OrderFromExternalBusiness)
            .Include(o => o.Tenant)
            .Include(o => o.Items)
            .Include(o => o.Assignments.Where(a => a.IsActive))
                .ThenInclude(a => a.Karigar)
            .Where(o => activeStatuses.Contains(o.Status) &&
                        (o.TenantId == business.Id ||
                         o.CreatedByBusinessId == business.Id ||
                         o.OrderFromBusinessId == business.Id))
            .ToListAsync(cancellationToken);

        var totalOrders = orders.Count;
        var pending = orders.Count(o => o.Status == OrderStatus.Pending);
        var assigned = orders.Count(o => o.Status == OrderStatus.Assigned);
        var inProgress = orders.Count(o => o.Status == OrderStatus.InProgress);
        var ready = orders.Count(o => o.Status == OrderStatus.Ready);
        var fromShowrooms = orders.Count(o => o.Source == OrderSource.Showroom && o.TenantId == business.Id);
        var directOrders = orders.Count(o => o.Source == OrderSource.Direct && o.TenantId == business.Id);

        // Unassigned = Pending (no active assignment)
        var unassigned = orders.Count(o => o.Status == OrderStatus.Pending && !o.Assignments.Any(a => a.IsActive));

        // Due date calculations from assignments
        var assignedOrders = orders.Where(o => o.Assignments.Any(a => a.IsActive)).ToList();

        var dueToday = assignedOrders.Count(o =>
            o.Assignments.Any(a => a.IsActive && a.DueDate == today) &&
            o.Status != OrderStatus.Ready);

        var dueNext3Days = assignedOrders.Count(o =>
            o.Assignments.Any(a => a.IsActive && a.DueDate > today && a.DueDate <= threeDaysLater) &&
            o.Status != OrderStatus.Ready);

        var overdue = assignedOrders.Count(o =>
            o.Assignments.Any(a => a.IsActive && a.DueDate < today) &&
            o.Status != OrderStatus.Ready);

        // Active Karigars count
        var activeKarigars = business.BusinessType == BusinessType.Shop
            ? await _context.Karigars
                .IgnoreQueryFilters()
                .CountAsync(k => k.TenantId == business.Id && k.Status == KarigarStatus.Active, cancellationToken)
            : 0;

        var connectedShops = business.BusinessType == BusinessType.Showroom
            ? orders
                .Where(o => o.TenantId != business.Id)
                .GroupBy(o => new { o.TenantId, o.Tenant.ShopName })
                .OrderByDescending(g => g.Count())
                .Select(g => new BusinessOrderCountDto
                {
                    BusinessId = g.Key.TenantId,
                    BusinessName = g.Key.ShopName,
                    OrderCount = g.Count()
                })
                .ToList()
            : new List<BusinessOrderCountDto>();

        var isShowroomViewer = business.BusinessType == BusinessType.Showroom;

        // Recent orders (last 5)
        var recentOrders = orders
            .OrderByDescending(o => o.CreatedAt)
            .Take(5)
            .Select(o => MapToDto(o, today, isShowroomViewer))
            .ToList();

        // Overdue orders
        var overdueOrders = assignedOrders
            .Where(o => o.Assignments.Any(a => a.IsActive && a.DueDate < today) && o.Status != OrderStatus.Ready)
            .OrderBy(o => o.Assignments.Where(a => a.IsActive).Min(a => a.DueDate))
            .Take(10)
            .Select(o => MapToDto(o, today, isShowroomViewer))
            .ToList();

        return Result<ShopDashboardDto>.Success(new ShopDashboardDto
        {
            TotalOrders = totalOrders,
            FromShowrooms = fromShowrooms,
            DirectOrders = directOrders,
            Pending = pending,
            Assigned = assigned,
            InProgress = inProgress,
            DueToday = dueToday,
            DueNext3Days = dueNext3Days,
            Overdue = overdue,
            Ready = ready,
            Unassigned = unassigned,
            ActiveKarigars = activeKarigars,
            BusinessType = business.BusinessType.ToString(),
            ConnectedShops = connectedShops,
            RecentOrders = recentOrders,
            OverdueOrders = overdueOrders
        });
    }

    private static OrderDto MapToDto(Domain.Entities.Order o, DateOnly today, bool isShowroomViewer)
    {
        var activeAssignment = o.Assignments.FirstOrDefault(a => a.IsActive);
        return new OrderDto
        {
            Id = o.Id,
            OrderNo = o.OrderNo,
            OrderFromBusinessId = o.OrderFromBusinessId,
            OrderFromExternalBusinessId = o.OrderFromExternalBusinessId,
            OrderFromBusinessName = o.OrderFromBusiness?.ShopName ??
                                    o.OrderFromExternalBusiness?.Name ??
                                    string.Empty,
            OrderDate = o.OrderDate.ToString("yyyy-MM-dd"),
            DeliveryDate = o.DeliveryDate?.ToString("yyyy-MM-dd"),
            Status = o.Status.ToString(),
            AcceptanceStatus = o.AcceptanceStatus.ToString(),
            AcceptanceNote = o.AcceptanceNote,
            TotalWeight = o.TotalWeight,
            MakingCharges = o.MakingCharges,
            AdvancePaid = o.AdvancePaid,
            EstimatedAmount = o.EstimatedAmount,
            Notes = o.Notes,
            KarigarName = isShowroomViewer ? null : activeAssignment?.Karigar?.Name,
            DueDate = isShowroomViewer ? null : activeAssignment?.DueDate.ToString("yyyy-MM-dd"),
            FirstItemImage = o.Items.Select(i => i.ImagePath).FirstOrDefault(p => p != null),
            Source = o.Source.ToString(),
            CreatedByBusinessId = o.CreatedByBusinessId,
            CreatedByBusinessName = o.CreatedByBusiness.ShopName,
            CreatedForBusinessId = o.TenantId,
            CreatedForBusinessName = o.Tenant.ShopName,
            CreatedAt = o.CreatedAt
        };
    }
}
