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
