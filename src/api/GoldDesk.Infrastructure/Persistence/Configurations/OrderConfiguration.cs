using GoldDesk.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace GoldDesk.Infrastructure.Persistence.Configurations;

public class OrderConfiguration : IEntityTypeConfiguration<Order>
{
    public void Configure(EntityTypeBuilder<Order> builder)
    {
        builder.ToTable("orders");

        builder.HasKey(o => o.Id);

        builder.Property(o => o.OrderNo).HasMaxLength(20).IsRequired();
        builder.Property(o => o.Status).HasConversion<string>().HasMaxLength(50);
        builder.Property(o => o.TotalWeight).HasPrecision(18, 3);
        builder.Property(o => o.MakingCharges).HasPrecision(18, 2);
        builder.Property(o => o.AdvancePaid).HasPrecision(18, 2);
        builder.Property(o => o.EstimatedAmount).HasPrecision(18, 2);
        builder.Property(o => o.Notes).HasMaxLength(2000);

        builder.HasIndex(o => new { o.TenantId, o.OrderNo }).IsUnique();
        builder.HasIndex(o => new { o.TenantId, o.Status });
        builder.HasIndex(o => o.DeliveryDate);

        builder.HasOne(o => o.Tenant)
            .WithMany(t => t.Orders)
            .HasForeignKey(o => o.TenantId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(o => o.Customer)
            .WithMany(c => c.Orders)
            .HasForeignKey(o => o.CustomerId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
