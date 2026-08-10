using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace GoldDesk.Infrastructure.Persistence;

/// <summary>
/// Factory used by EF Core tooling (migrations) to create the DbContext at design time.
/// </summary>
public class DesignTimeDbContextFactory : IDesignTimeDbContextFactory<ApplicationDbContext>
{
    public ApplicationDbContext CreateDbContext(string[] args)
    {
        var optionsBuilder = new DbContextOptionsBuilder<ApplicationDbContext>();
        optionsBuilder.UseNpgsql("Host=localhost;Port=5434;Database=golddesk;Username=golddesk;Password=golddesk_dev;SslMode=Disable");

        return new ApplicationDbContext(optionsBuilder.Options, new DesignTimeCurrentUserService());
    }
}

/// <summary>
/// Minimal implementation of ICurrentUserService for design-time migrations.
/// </summary>
internal class DesignTimeCurrentUserService : ICurrentUserService
{
    public Guid? UserId => null;
    public Guid? TenantId => null;
    public UserRole? Role => null;
    public string? Email => null;
    public bool IsAuthenticated => false;
}
