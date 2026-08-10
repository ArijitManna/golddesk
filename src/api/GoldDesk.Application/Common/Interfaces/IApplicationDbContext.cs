using GoldDesk.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Common.Interfaces;

public interface IApplicationDbContext
{
    DbSet<Tenant> Tenants { get; }
    DbSet<User> Users { get; }
    DbSet<Customer> Customers { get; }
    DbSet<Karigar> Karigars { get; }
    DbSet<ItemMaster> Items { get; }
    DbSet<Order> Orders { get; }
    DbSet<OrderItem> OrderItems { get; }
    DbSet<OrderAssignment> OrderAssignments { get; }
    DbSet<OrderStatusHistory> OrderStatusHistory { get; }
    DbSet<Notification> Notifications { get; }
    DbSet<AuditLog> AuditLogs { get; }

    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
