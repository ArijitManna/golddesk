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

    public GetShopDashboardQueryHandler(IApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<Result<ShopDashboardDto>> Handle(GetShopDashboardQuery request, CancellationToken cancellationToken)
    {
        var today = DateOnly.FromDateTime(DateTime.Today);
        var threeDaysLater = today.AddDays(3);

        // Active statuses (not delivered/closed/cancelled)
        var activeStatuses = new[]
        {
            OrderStatus.Pending, OrderStatus.Assigned, OrderStatus.InProgress, OrderStatus.Ready
        };

        var orders = await _context.Orders
            .Include(o => o.Customer)
            .Include(o => o.Items)
            .Include(o => o.Assignments.Where(a => a.IsActive))
                .ThenInclude(a => a.Karigar)
            .Where(o => activeStatuses.Contains(o.Status))
            .ToListAsync(cancellationToken);

        var totalOrders = orders.Count;
        var pending = orders.Count(o => o.Status == OrderStatus.Pending);
        var assigned = orders.Count(o => o.Status == OrderStatus.Assigned);
        var inProgress = orders.Count(o => o.Status == OrderStatus.InProgress);
        var ready = orders.Count(o => o.Status == OrderStatus.Ready);

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
        var activeKarigars = await _context.Karigars
            .CountAsync(k => k.Status == KarigarStatus.Active, cancellationToken);

        // Recent orders (last 5)
        var recentOrders = orders
            .OrderByDescending(o => o.CreatedAt)
            .Take(5)
            .Select(o => MapToDto(o, today))
            .ToList();

        // Overdue orders
        var overdueOrders = assignedOrders
            .Where(o => o.Assignments.Any(a => a.IsActive && a.DueDate < today) && o.Status != OrderStatus.Ready)
            .OrderBy(o => o.Assignments.Where(a => a.IsActive).Min(a => a.DueDate))
            .Take(10)
            .Select(o => MapToDto(o, today))
            .ToList();

        return Result<ShopDashboardDto>.Success(new ShopDashboardDto
        {
            TotalOrders = totalOrders,
            Pending = pending,
            Assigned = assigned,
            InProgress = inProgress,
            DueToday = dueToday,
            DueNext3Days = dueNext3Days,
            Overdue = overdue,
            Ready = ready,
            Unassigned = unassigned,
            ActiveKarigars = activeKarigars,
            RecentOrders = recentOrders,
            OverdueOrders = overdueOrders
        });
    }

    private static OrderDto MapToDto(Domain.Entities.Order o, DateOnly today)
    {
        var activeAssignment = o.Assignments.FirstOrDefault(a => a.IsActive);
        return new OrderDto
        {
            Id = o.Id,
            OrderNo = o.OrderNo,
            CustomerName = o.Customer.Name,
            CustomerId = o.CustomerId,
            OrderDate = o.OrderDate.ToString("yyyy-MM-dd"),
            DeliveryDate = o.DeliveryDate?.ToString("yyyy-MM-dd"),
            Status = o.Status.ToString(),
            TotalWeight = o.TotalWeight,
            MakingCharges = o.MakingCharges,
            AdvancePaid = o.AdvancePaid,
            EstimatedAmount = o.EstimatedAmount,
            Notes = o.Notes,
            KarigarName = activeAssignment?.Karigar.Name,
            DueDate = activeAssignment?.DueDate.ToString("yyyy-MM-dd"),
            FirstItemImage = o.Items.Select(i => i.ImagePath).FirstOrDefault(p => p != null),
            CreatedAt = o.CreatedAt
        };
    }
}
