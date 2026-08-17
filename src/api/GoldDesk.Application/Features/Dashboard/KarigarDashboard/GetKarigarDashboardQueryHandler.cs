using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Dashboard.KarigarDashboard;

public class GetKarigarDashboardQueryHandler : IRequestHandler<GetKarigarDashboardQuery, Result<KarigarDashboardDto>>
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;

    public GetKarigarDashboardQueryHandler(IApplicationDbContext context, ICurrentUserService currentUser)
    {
        _context = context;
        _currentUser = currentUser;
    }

    public async Task<Result<KarigarDashboardDto>> Handle(GetKarigarDashboardQuery request, CancellationToken cancellationToken)
    {
        // Find Karigar by current user
        var karigar = await _context.Karigars
            .FirstOrDefaultAsync(k => k.UserId == _currentUser.UserId, cancellationToken);

        if (karigar == null)
            return Result<KarigarDashboardDto>.Forbidden("You are not registered as a Karigar");

        var today = DateOnly.FromDateTime(DateTime.Today);
        var threeDaysLater = today.AddDays(3);

        // Get all active assignments for this Karigar
        var activeAssignments = await _context.OrderAssignments
            .IgnoreQueryFilters()
            .Include(a => a.Order)
                .ThenInclude(o => o.Tenant)
            .Include(a => a.Order)
                .ThenInclude(o => o.OrderFromBusiness)
            .Include(a => a.Order)
                .ThenInclude(o => o.OrderFromExternalBusiness)
            .Where(a => a.KarigarId == karigar.Id && a.IsActive)
            .ToListAsync(cancellationToken);

        // Calculate stats
        var totalAssigned = activeAssignments.Count;
        var newWork = activeAssignments.Count(a => a.Status == AssignmentStatus.PendingAcceptance);
        var workAccepted = activeAssignments.Count(a => a.Status == AssignmentStatus.Active &&
                                                       a.Order.Status == OrderStatus.Assigned);
        var inProgress = activeAssignments.Count(a => a.Order.Status == OrderStatus.InProgress);
        var dueToday = activeAssignments.Count(a => a.DueDate == today && a.Order.Status != OrderStatus.Ready);
        var dueSoon = activeAssignments.Count(a =>
            a.DueDate > today && a.DueDate <= threeDaysLater &&
            a.Order.Status != OrderStatus.Ready && a.Order.Status != OrderStatus.Delivered && a.Order.Status != OrderStatus.Closed);
        var overdue = activeAssignments.Count(a =>
            a.DueDate < today &&
            a.Order.Status != OrderStatus.Ready && a.Order.Status != OrderStatus.Delivered && a.Order.Status != OrderStatus.Closed);
        var ready = activeAssignments.Count(a => a.Order.Status == OrderStatus.Ready);

        // Due soon orders (next 3 days including today)
        var dueSoonOrders = activeAssignments
            .Where(a => a.DueDate <= threeDaysLater &&
                a.Order.Status != OrderStatus.Ready &&
                a.Order.Status != OrderStatus.Delivered &&
                a.Order.Status != OrderStatus.Closed)
            .OrderBy(a => a.DueDate)
            .Take(10)
            .Select(a => new KarigarOrderDto
            {
                OrderId = a.OrderId,
                OrderNo = a.Order.OrderNo,
                OrderFromBusinessName = a.Order.Tenant.ShopName,
                SourceShopName = a.Order.Tenant.ShopName,
                Status = a.Order.Status.ToString(),
                AssignmentStatus = a.Status.ToString(),
                DueDate = a.DueDate.ToString("yyyy-MM-dd"),
                DaysLeft = a.DueDate.DayNumber - today.DayNumber,
                Notes = a.Notes,
                TotalWeight = a.Order.TotalWeight
            })
            .ToList();

        // Recent orders
        var recentOrders = activeAssignments
            .OrderByDescending(a => a.CreatedAt)
            .Take(5)
            .Select(a => new KarigarOrderDto
            {
                OrderId = a.OrderId,
                OrderNo = a.Order.OrderNo,
                OrderFromBusinessName = a.Order.Tenant.ShopName,
                SourceShopName = a.Order.Tenant.ShopName,
                Status = a.Order.Status.ToString(),
                AssignmentStatus = a.Status.ToString(),
                DueDate = a.DueDate.ToString("yyyy-MM-dd"),
                DaysLeft = a.DueDate.DayNumber - today.DayNumber,
                Notes = a.Notes,
                TotalWeight = a.Order.TotalWeight
            })
            .ToList();

        return Result<KarigarDashboardDto>.Success(new KarigarDashboardDto
        {
            TotalAssigned = totalAssigned,
            NewWork = newWork,
            WorkAccepted = workAccepted,
            InProgress = inProgress,
            DueToday = dueToday,
            DueSoon = dueSoon,
            Overdue = overdue,
            Ready = ready,
            DueSoonOrders = dueSoonOrders,
            RecentOrders = recentOrders
        });
    }
}
