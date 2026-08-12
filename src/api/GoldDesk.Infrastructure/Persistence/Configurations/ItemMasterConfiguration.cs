using GoldDesk.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace GoldDesk.Infrastructure.Persistence.Configurations;

public class ItemMasterConfiguration : IEntityTypeConfiguration<ItemMaster>
{
    public void Configure(EntityTypeBuilder<ItemMaster> builder)
    {
        builder.ToTable("item_master");

        builder.HasKey(i => i.Id);

        builder.Property(i => i.ItemCode).HasMaxLength(50).IsRequired();
        builder.Property(i => i.Name).HasMaxLength(200).IsRequired();
        builder.Property(i => i.Category).HasMaxLength(100);
        builder.Property(i => i.Purity).HasMaxLength(20);
        builder.Property(i => i.DefaultRate).HasPrecision(18, 2);
        builder.Property(i => i.DefaultMakingCharge).HasPrecision(18, 2);
        builder.Property(i => i.ImagePath).HasMaxLength(500);

        builder.HasIndex(i => new { i.TenantId, i.ItemCode }).IsUnique();
        builder.HasIndex(i => new { i.TenantId, i.Name });

        builder.HasOne(i => i.Tenant)
            .WithMany(t => t.Items)
            .HasForeignKey(i => i.TenantId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
