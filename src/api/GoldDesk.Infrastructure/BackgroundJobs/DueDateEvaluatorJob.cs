using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Domain.Enums;
using GoldDesk.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace GoldDesk.Infrastructure.BackgroundJobs;

/// <summary>
/// Background service that periodically evaluates due dates and generates notifications.
/// Runs every hour and checks for orders approaching or past their due date.
/// </summary>
public class DueDateEvaluatorJob : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<DueDateEvaluatorJob> _logger;
    private readonly TimeSpan _interval = TimeSpan.FromHours(1);

    public DueDateEvaluatorJob(IServiceProvider serviceProvider, ILogger<DueDateEvaluatorJob> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Due Date Evaluator started. Running every {Interval}", _interval);

        // Initial delay to let the app start up
        await Task.Delay(TimeSpan.FromSeconds(30), stoppingToken);

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await EvaluateDueDatesAsync(stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in Due Date Evaluator");
            }

            await Task.Delay(_interval, stoppingToken);
        }
    }

    private async Task EvaluateDueDatesAsync(CancellationToken cancellationToken)
    {
        using var scope = _serviceProvider.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        var notificationService = scope.ServiceProvider.GetRequiredService<INotificationService>();

        var today = DateOnly.FromDateTime(DateTime.Today);

        // Get all active assignments that are not Ready/Delivered/Closed/Cancelled
        var activeAssignments = await context.OrderAssignments
            .IgnoreQueryFilters()
            .Include(a => a.Order)
                .ThenInclude(o => o.Customer)
            .Include(a => a.Karigar)
            .Where(a => a.IsActive &&
                a.Order.Status != OrderStatus.Ready &&
                a.Order.Status != OrderStatus.Delivered &&
                a.Order.Status != OrderStatus.Closed &&
                a.Order.Status != OrderStatus.Cancelled)
            .ToListAsync(cancellationToken);

        _logger.LogInformation("Evaluating {Count} active assignments for due dates", activeAssignments.Count);

        var tenantIds = activeAssignments.Select(a => a.Order.TenantId).Distinct().ToList();
        var tenants = await context.Tenants
            .IgnoreQueryFilters()
            .Where(t => tenantIds.Contains(t.Id))
            .ToDictionaryAsync(t => t.Id, cancellationToken);

        foreach (var assignment in activeAssignments)
        {
            var daysUntilDue = assignment.DueDate.DayNumber - today.DayNumber;
            var notificationType = GetNotificationType(daysUntilDue);

            if (notificationType == null)
                continue;

            if (tenants.TryGetValue(assignment.Order.TenantId, out var tenant) &&
                !IsNotificationEnabled(tenant, notificationType.Value))
            {
                continue;
            }

            // Check if this notification was already sent
            if (assignment.LastNotificationType == notificationType.Value.ToString())
                continue;

            var title = GetNotificationTitle(notificationType.Value, assignment.Order.OrderNo);
            var message = GetNotificationMessage(notificationType.Value, assignment.Order.OrderNo, assignment.Order.Customer.Name, daysUntilDue);

            // Notify Karigar
            if (assignment.Karigar.UserId.HasValue)
            {
                await notificationService.CreateAndPushAsync(
                    assignment.Order.TenantId,
                    assignment.Karigar.UserId.Value,
                    assignment.OrderId,
                    notificationType.Value,
                    title,
                    message,
                    cancellationToken);
            }

            // Notify Shop Owner(s)
            var shopOwners = await context.Users
                .IgnoreQueryFilters()
                .Where(u => u.TenantId == assignment.Order.TenantId &&
                    u.Role == UserRole.ShopOwner &&
                    u.Status == UserStatus.Active)
                .ToListAsync(cancellationToken);

            foreach (var owner in shopOwners)
            {
                await notificationService.CreateAndPushAsync(
                    assignment.Order.TenantId,
                    owner.Id,
                    assignment.OrderId,
                    notificationType.Value,
                    title,
                    message,
                    cancellationToken);
            }

            // Update last notification type to prevent duplicates
            assignment.LastNotificationType = notificationType.Value.ToString();
            await context.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Due date notification sent for Order {OrderNo}: {Type}",
                assignment.Order.OrderNo, notificationType.Value);
        }
    }

    private static bool IsNotificationEnabled(Domain.Entities.Tenant tenant, NotificationType type)
    {
        return type switch
        {
            NotificationType.DueSoon3Days => tenant.NotifyDueSoon3Days,
            NotificationType.DueSoon2Days => tenant.NotifyDueSoon2Days,
            NotificationType.DueSoon1Day => tenant.NotifyDueSoon1Day,
            NotificationType.DueToday => tenant.NotifyDueToday,
            NotificationType.Overdue => tenant.NotifyOverdue,
            _ => true
        };
    }

    private static NotificationType? GetNotificationType(int daysUntilDue)
    {
        return daysUntilDue switch
        {
            3 => NotificationType.DueSoon3Days,
            2 => NotificationType.DueSoon2Days,
            1 => NotificationType.DueSoon1Day,
            0 => NotificationType.DueToday,
            < 0 => NotificationType.Overdue,
            _ => null
        };
    }

    private static string GetNotificationTitle(NotificationType type, string orderNo)
    {
        return type switch
        {
            NotificationType.DueSoon3Days => "Order Due in 3 Days",
            NotificationType.DueSoon2Days => "Order Due in 2 Days",
            NotificationType.DueSoon1Day => "Order Due Tomorrow",
            NotificationType.DueToday => "Order Due Today",
            NotificationType.Overdue => "Order Overdue",
            _ => "Order Notification"
        };
    }

    private static string GetNotificationMessage(NotificationType type, string orderNo, string customerName, int daysUntilDue)
    {
        return type switch
        {
            NotificationType.DueSoon3Days => $"Order {orderNo} for {customerName} is due in 3 days",
            NotificationType.DueSoon2Days => $"Order {orderNo} for {customerName} is due in 2 days",
            NotificationType.DueSoon1Day => $"Order {orderNo} for {customerName} is due tomorrow",
            NotificationType.DueToday => $"Order {orderNo} for {customerName} is due today",
            NotificationType.Overdue => $"Order {orderNo} for {customerName} is overdue by {Math.Abs(daysUntilDue)} day(s)",
            _ => $"Notification for order {orderNo}"
        };
    }
}
