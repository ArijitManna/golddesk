using GoldDesk.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace GoldDesk.Infrastructure.Persistence.Configurations;

public class TenantConfiguration : IEntityTypeConfiguration<Tenant>
{
    public void Configure(EntityTypeBuilder<Tenant> builder)
    {
        builder.ToTable("tenants");

        builder.HasKey(t => t.Id);

        builder.Property(t => t.ShopName).HasMaxLength(200).IsRequired();
        builder.Property(t => t.OwnerName).HasMaxLength(200).IsRequired();
        builder.Property(t => t.Mobile).HasMaxLength(20).IsRequired();
        builder.Property(t => t.Email).HasMaxLength(200).IsRequired();
        builder.Property(t => t.Address).HasMaxLength(500);
        builder.Property(t => t.GstNumber).HasMaxLength(50);
        builder.Property(t => t.LogoPath).HasMaxLength(500);
        // No HasDefaultValue: Showroom = 0 is the CLR default and would be omitted from INSERTs,
// silently becoming Shop in the database and breaking Showroom↔Shop connections.
        builder.Property(t => t.BusinessType).HasConversion<string>().HasMaxLength(50).IsRequired();
        builder.Property(t => t.GoldDeskId).HasMaxLength(30).IsRequired();
        builder.Property(t => t.AdminNote).HasMaxLength(1000);
        builder.Property(t => t.Status).HasConversion<string>().HasMaxLength(50);

        builder.Property(t => t.NotifyDueSoon3Days).HasDefaultValue(true);
        builder.Property(t => t.NotifyDueSoon2Days).HasDefaultValue(true);
        builder.Property(t => t.NotifyDueSoon1Day).HasDefaultValue(true);
        builder.Property(t => t.NotifyDueToday).HasDefaultValue(true);
        builder.Property(t => t.NotifyOverdue).HasDefaultValue(true);

        // Email is shared across multi-profile accounts; uniqueness is on users (Email, TenantId).
        builder.HasIndex(t => t.Email);
        builder.HasIndex(t => t.Mobile).IsUnique();
        builder.HasIndex(t => t.GoldDeskId).IsUnique();
        builder.HasIndex(t => t.Status);
        builder.HasIndex(t => t.BusinessType);
    }
}
