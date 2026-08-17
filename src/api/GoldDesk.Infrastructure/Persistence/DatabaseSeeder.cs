using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Domain.Entities;
using GoldDesk.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace GoldDesk.Infrastructure.Persistence;

public class DatabaseSeeder
{
    private readonly ApplicationDbContext _context;
    private readonly IAuthProvider _authProvider;
    private readonly ILogger<DatabaseSeeder> _logger;

    // Well-known IDs for the platform admin
    private static readonly Guid PlatformTenantId = Guid.Parse("00000000-0000-0000-0000-000000000001");
    private static readonly Guid SuperAdminUserId = Guid.Parse("00000000-0000-0000-0000-000000000002");

    public DatabaseSeeder(
        ApplicationDbContext context,
        IAuthProvider authProvider,
        ILogger<DatabaseSeeder> logger)
    {
        _context = context;
        _authProvider = authProvider;
        _logger = logger;
    }

    public async Task SeedAsync()
    {
        await SeedPlatformTenantAsync();
        await SeedSuperAdminAsync();
        // Demo network seeding disabled — register Showroom/Shop/Karigar from scratch to test Phase 1.
        await BackfillGoldDeskIdsAsync();
        await BackfillBusinessTypesFromGoldDeskIdAsync();
        await ActivateUsersForActiveTenantsAsync();
        await RestoreShowroomCustomersMovedToShopsAsync();
    }

    private async Task SeedPhaseOneDemoNetworkAsync()
    {
        if (await _context.Tenants.IgnoreQueryFilters().AnyAsync(t => t.GoldDeskId == "GD-S-001"))
            return;

        var businesses = new[]
        {
            new Tenant { Id = Guid.NewGuid(), ShopName = "A Showroom", OwnerName = "Showroom One", Mobile = "9000000001", Email = "show1@test.com", BusinessType = BusinessType.Showroom, GoldDeskId = "GD-S-001", Status = TenantStatus.Active, ApprovedAt = DateTime.UtcNow },
            new Tenant { Id = Guid.NewGuid(), ShopName = "B Showroom", OwnerName = "Showroom Two", Mobile = "9000000002", Email = "show2@test.com", BusinessType = BusinessType.Showroom, GoldDeskId = "GD-S-002", Status = TenantStatus.Active, ApprovedAt = DateTime.UtcNow },
            new Tenant { Id = Guid.NewGuid(), ShopName = "C Showroom", OwnerName = "Showroom Three", Mobile = "9000000003", Email = "show3@test.com", BusinessType = BusinessType.Showroom, GoldDeskId = "GD-S-003", Status = TenantStatus.Active, ApprovedAt = DateTime.UtcNow },
            new Tenant { Id = Guid.NewGuid(), ShopName = "A Shop", OwnerName = "Shop One", Mobile = "9000000011", Email = "shop1@test.com", BusinessType = BusinessType.Shop, GoldDeskId = "GD-P-001", Status = TenantStatus.Active, ApprovedAt = DateTime.UtcNow },
            new Tenant { Id = Guid.NewGuid(), ShopName = "B Shop", OwnerName = "Shop Two", Mobile = "9000000012", Email = "shop2@test.com", BusinessType = BusinessType.Shop, GoldDeskId = "GD-P-002", Status = TenantStatus.Active, ApprovedAt = DateTime.UtcNow },
            new Tenant { Id = Guid.NewGuid(), ShopName = "A Karigar", OwnerName = "Karigar One", Mobile = "9000000021", Email = "kar1@test.com", BusinessType = BusinessType.Karigar, GoldDeskId = "GD-K-001", Status = TenantStatus.Active, ApprovedAt = DateTime.UtcNow },
            new Tenant { Id = Guid.NewGuid(), ShopName = "B Karigar", OwnerName = "Karigar Two", Mobile = "9000000022", Email = "kar2@test.com", BusinessType = BusinessType.Karigar, GoldDeskId = "GD-K-002", Status = TenantStatus.Active, ApprovedAt = DateTime.UtcNow },
            new Tenant { Id = Guid.NewGuid(), ShopName = "C Karigar", OwnerName = "Karigar Three", Mobile = "9000000023", Email = "kar3@test.com", BusinessType = BusinessType.Karigar, GoldDeskId = "GD-K-003", Status = TenantStatus.Active, ApprovedAt = DateTime.UtcNow }
        };

        _context.Tenants.AddRange(businesses);
        var users = businesses.Select(b => new User
        {
            Id = Guid.NewGuid(),
            TenantId = b.Id,
            Email = b.Email,
            PasswordHash = _authProvider.HashPassword("Test@123"),
            FullName = b.OwnerName,
            Mobile = b.Mobile,
            Role = b.BusinessType == BusinessType.Karigar ? UserRole.Karigar : UserRole.ShopOwner,
            Status = UserStatus.Active
        }).ToList();
        _context.Users.AddRange(users);

        var karigarBusinesses = businesses.Where(b => b.BusinessType == BusinessType.Karigar).ToList();
        foreach (var business in karigarBusinesses)
        {
            _context.Karigars.Add(new Karigar
            {
                TenantId = business.Id,
                UserId = users.Single(u => u.TenantId == business.Id).Id,
                Name = business.ShopName,
                Mobile = business.Mobile,
                Email = business.Email,
                Status = KarigarStatus.Active
            });
        }

        var showrooms = businesses.Where(b => b.BusinessType == BusinessType.Showroom).ToList();
        var shops = businesses.Where(b => b.BusinessType == BusinessType.Shop).ToList();
        var connections = new[]
        {
            (showrooms[0], shops[0], ConnectionType.ShowroomShop),
            (showrooms[0], shops[1], ConnectionType.ShowroomShop),
            (showrooms[1], shops[0], ConnectionType.ShowroomShop),
            (shops[0], karigarBusinesses[0], ConnectionType.ShopKarigar),
            (shops[0], karigarBusinesses[1], ConnectionType.ShopKarigar),
            (shops[1], karigarBusinesses[0], ConnectionType.ShopKarigar),
            (shops[1], karigarBusinesses[2], ConnectionType.ShopKarigar)
        };
        foreach (var (from, to, type) in connections)
        {
            _context.BusinessConnections.Add(new BusinessConnection
            {
                FromBusinessId = from.Id,
                ToBusinessId = to.Id,
                ConnectionType = type,
                Status = ConnectionStatus.Accepted,
                RequestedByUserId = users.Single(u => u.TenantId == from.Id).Id,
                AcceptedAt = DateTime.UtcNow
            });
        }

        await _context.SaveChangesAsync();
        _logger.LogInformation("Seeded clean Phase 1 B2B demo network");
    }

    /// <summary>
    /// Earlier logic moved Showroom customers onto the Shop on order create.
    /// Restore a Showroom-side copy so the Showroom customer list stays intact.
    /// </summary>
    private async Task RestoreShowroomCustomersMovedToShopsAsync()
    {
        var showroomOrders = await _context.Orders
            .IgnoreQueryFilters()
            .Include(o => o.Customer)
            .Where(o => o.Source == OrderSource.Showroom &&
                        o.Customer.TenantId == o.TenantId &&
                        o.CreatedByBusinessId != o.TenantId)
            .ToListAsync();

        if (showroomOrders.Count == 0) return;

        var restored = 0;
        foreach (var order in showroomOrders)
        {
            var shopCustomer = order.Customer;
            var existsOnShowroom = await _context.Customers
                .IgnoreQueryFilters()
                .AnyAsync(c =>
                    c.TenantId == order.CreatedByBusinessId &&
                    c.IsActive &&
                    c.Name == shopCustomer.Name &&
                    c.Mobile == shopCustomer.Mobile);

            if (existsOnShowroom) continue;

            _context.Customers.Add(new Customer
            {
                TenantId = order.CreatedByBusinessId,
                Name = shopCustomer.Name,
                Mobile = shopCustomer.Mobile,
                Email = shopCustomer.Email,
                Address = shopCustomer.Address,
                Notes = shopCustomer.Notes,
                IsActive = true
            });
            restored++;
        }

        if (restored > 0)
        {
            await _context.SaveChangesAsync();
            _logger.LogInformation(
                "Restored {Count} Showroom customer copies that were previously moved to Shops",
                restored);
        }
    }

    /// <summary>
    /// Karigar approvals previously activated only ShopOwner users, leaving Karigar
    /// logins Inactive on an Active tenant. Activate those orphaned accounts.
    /// </summary>
    private async Task ActivateUsersForActiveTenantsAsync()
    {
        var stuckUsers = await _context.Users
            .IgnoreQueryFilters()
            .Include(u => u.Tenant)
            .Where(u => u.Status == UserStatus.Inactive &&
                        u.Tenant.Status == TenantStatus.Active &&
                        (u.Role == UserRole.ShopOwner || u.Role == UserRole.Karigar))
            .ToListAsync();

        if (stuckUsers.Count == 0) return;

        foreach (var user in stuckUsers)
            user.Status = UserStatus.Active;

        await _context.SaveChangesAsync();
        _logger.LogInformation(
            "Activated {Count} inactive owner users on already-approved businesses",
            stuckUsers.Count);
    }

    /// <summary>
    /// Repair tenants whose BusinessType was incorrectly saved as Shop because
    /// Showroom (enum 0) hit EF's database-default sentinel behavior.
    /// GoldDesk ID prefix is the source of truth.
    /// </summary>
    private async Task BackfillBusinessTypesFromGoldDeskIdAsync()
    {
        var tenants = await _context.Tenants
            .IgnoreQueryFilters()
            .Where(t => t.GoldDeskId != "" && t.GoldDeskId != "GD-PLATFORM")
            .ToListAsync();

        var fixedCount = 0;
        foreach (var tenant in tenants)
        {
            var expected = tenant.GoldDeskId switch
            {
                var id when id.StartsWith("GD-SHOW-", StringComparison.OrdinalIgnoreCase) => BusinessType.Showroom,
                var id when id.StartsWith("GD-KAR-", StringComparison.OrdinalIgnoreCase) => BusinessType.Karigar,
                var id when id.StartsWith("GD-SHOP-", StringComparison.OrdinalIgnoreCase) => BusinessType.Shop,
                _ => tenant.BusinessType
            };

            if (tenant.BusinessType != expected)
            {
                _logger.LogWarning(
                    "Fixing BusinessType for {GoldDeskId} ({ShopName}): {From} → {To}",
                    tenant.GoldDeskId, tenant.ShopName, tenant.BusinessType, expected);
                tenant.BusinessType = expected;
                fixedCount++;
            }
        }

        if (fixedCount > 0)
        {
            await _context.SaveChangesAsync();
            _logger.LogInformation("Corrected BusinessType on {Count} tenants from GoldDesk ID prefix", fixedCount);
        }
    }

    private async Task BackfillGoldDeskIdsAsync()
    {
        var missing = await _context.Tenants
            .IgnoreQueryFilters()
            .Where(t => string.IsNullOrEmpty(t.GoldDeskId))
            .OrderBy(t => t.CreatedAt)
            .ToListAsync();

        if (missing.Count == 0) return;

        var next = 1;
        var existing = await _context.Tenants
            .IgnoreQueryFilters()
            .Where(t => t.GoldDeskId.StartsWith("GD-SHOP-"))
            .Select(t => t.GoldDeskId)
            .ToListAsync();

        foreach (var id in existing)
        {
            var parts = id.Split('-');
            if (parts.Length >= 3 && int.TryParse(parts[^1], out var n) && n >= next)
                next = n + 1;
        }

        foreach (var tenant in missing)
        {
            if (tenant.Id == PlatformTenantId)
            {
                tenant.GoldDeskId = "GD-PLATFORM";
                tenant.BusinessType = BusinessType.Shop;
            }
            else
            {
                tenant.GoldDeskId = $"GD-SHOP-{next:D4}";
                tenant.BusinessType = BusinessType.Shop;
                next++;
            }
        }

        await _context.SaveChangesAsync();
        _logger.LogInformation("Backfilled GoldDesk IDs for {Count} tenants", missing.Count);
    }

    private async Task SeedPlatformTenantAsync()
    {
        var exists = await _context.Tenants
            .IgnoreQueryFilters()
            .AnyAsync(t => t.Id == PlatformTenantId);

        if (!exists)
        {
            var platformTenant = new Tenant
            {
                Id = PlatformTenantId,
                ShopName = "GoldDesk Platform",
                OwnerName = "Platform Admin",
                Mobile = "0000000000",
                Email = "admin@golddesk.com",
                BusinessType = BusinessType.Shop,
                GoldDeskId = "GD-PLATFORM",
                Status = TenantStatus.Active,
                AdminNote = "System platform tenant",
                ApprovedAt = DateTime.UtcNow,
                CreatedAt = DateTime.UtcNow
            };

            _context.Tenants.Add(platformTenant);
            await _context.SaveChangesAsync();
            _logger.LogInformation("Platform tenant seeded successfully");
        }
    }

    private async Task SeedSuperAdminAsync()
    {
        var exists = await _context.Users
            .IgnoreQueryFilters()
            .AnyAsync(u => u.Id == SuperAdminUserId);

        if (!exists)
        {
            var superAdmin = new User
            {
                Id = SuperAdminUserId,
                TenantId = PlatformTenantId,
                Email = "admin@golddesk.com",
                PasswordHash = _authProvider.HashPassword("Admin@123"),
                FullName = "Platform Super Admin",
                Mobile = "0000000000",
                Role = UserRole.SuperAdmin,
                Status = UserStatus.Active,
                CreatedAt = DateTime.UtcNow
            };

            _context.Users.Add(superAdmin);
            await _context.SaveChangesAsync();
            _logger.LogInformation("Super Admin user seeded (email: admin@golddesk.com, password: Admin@123)");
        }
    }
}
