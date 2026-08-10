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
        builder.Property(t => t.AdminNote).HasMaxLength(1000);
        builder.Property(t => t.Status).HasConversion<string>().HasMaxLength(50);

        builder.HasIndex(t => t.Email).IsUnique();
        builder.HasIndex(t => t.Mobile).IsUnique();
        builder.HasIndex(t => t.Status);
    }
}
