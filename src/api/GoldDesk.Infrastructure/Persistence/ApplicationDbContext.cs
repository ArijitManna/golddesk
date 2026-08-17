using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Domain.Common;
using GoldDesk.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Infrastructure.Persistence;

public class ApplicationDbContext : DbContext, IApplicationDbContext
{
    private readonly ICurrentUserService _currentUserService;

    public ApplicationDbContext(
        DbContextOptions<ApplicationDbContext> options,
        ICurrentUserService currentUserService)
        : base(options)
    {
        _currentUserService = currentUserService;
    }

    public DbSet<Tenant> Tenants => Set<Tenant>();
    public DbSet<User> Users => Set<User>();
    public DbSet<Customer> Customers => Set<Customer>();
    public DbSet<Karigar> Karigars => Set<Karigar>();
    public DbSet<ItemMaster> Items => Set<ItemMaster>();
    public DbSet<Order> Orders => Set<Order>();
    public DbSet<OrderItem> OrderItems => Set<OrderItem>();
    public DbSet<OrderAssignment> OrderAssignments => Set<OrderAssignment>();
    public DbSet<OrderStatusHistory> OrderStatusHistory => Set<OrderStatusHistory>();
    public DbSet<Notification> Notifications => Set<Notification>();
    public DbSet<AuditLog> AuditLogs => Set<AuditLog>();
    public DbSet<BusinessConnection> BusinessConnections => Set<BusinessConnection>();
    public DbSet<ExternalBusiness> ExternalBusinesses => Set<ExternalBusiness>();
    public DbSet<OrderComment> OrderComments => Set<OrderComment>();
    public DbSet<OrderEvent> OrderEvents => Set<OrderEvent>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Apply all configurations from this assembly
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(ApplicationDbContext).Assembly);

        // Global query filter for tenant isolation
        // Must reference _currentUserService directly (not a captured variable)
        // so EF Core evaluates it at query time, not model creation time
        modelBuilder.Entity<Customer>().HasQueryFilter(e => e.TenantId == _currentUserService.TenantId);
        modelBuilder.Entity<Karigar>().HasQueryFilter(e => e.TenantId == _currentUserService.TenantId);
        modelBuilder.Entity<ItemMaster>().HasQueryFilter(e => e.TenantId == _currentUserService.TenantId);
        modelBuilder.Entity<Order>().HasQueryFilter(e =>
            e.TenantId == _currentUserService.TenantId ||
            e.CreatedByBusinessId == _currentUserService.TenantId ||
            e.OrderFromBusinessId == _currentUserService.TenantId);
        modelBuilder.Entity<ExternalBusiness>().HasQueryFilter(e => e.TenantId == _currentUserService.TenantId);
        modelBuilder.Entity<Notification>().HasQueryFilter(e => e.TenantId == _currentUserService.TenantId);
        modelBuilder.Entity<AuditLog>().HasQueryFilter(e => e.TenantId == _currentUserService.TenantId);
    }

    public override async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        foreach (var entry in ChangeTracker.Entries<BaseEntity>())
        {
            switch (entry.State)
            {
                case EntityState.Added:
                    entry.Entity.CreatedAt = DateTime.UtcNow;
                    entry.Entity.CreatedBy = _currentUserService.UserId;
                    break;
                case EntityState.Modified:
                    entry.Entity.UpdatedAt = DateTime.UtcNow;
                    entry.Entity.UpdatedBy = _currentUserService.UserId;
                    break;
            }
        }

        // Auto-set TenantId for new tenant entities
        foreach (var entry in ChangeTracker.Entries<BaseTenantEntity>())
        {
            if (entry.State == EntityState.Added && entry.Entity.TenantId == Guid.Empty)
            {
                if (_currentUserService.TenantId.HasValue)
                {
                    entry.Entity.TenantId = _currentUserService.TenantId.Value;
                }
            }
        }

        return await base.SaveChangesAsync(cancellationToken);
    }
}
