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
        builder.Property(o => o.Source).HasConversion<string>().HasMaxLength(50);
        builder.Property(o => o.Status).HasConversion<string>().HasMaxLength(50);
        builder.Property(o => o.AcceptanceStatus).HasConversion<string>().HasMaxLength(50);
        builder.Property(o => o.AcceptanceNote).HasMaxLength(1000);
        builder.Property(o => o.TotalWeight).HasPrecision(18, 3);
        builder.Property(o => o.MakingCharges).HasPrecision(18, 2);
        builder.Property(o => o.AdvancePaid).HasPrecision(18, 2);
        builder.Property(o => o.EstimatedAmount).HasPrecision(18, 2);
        builder.Property(o => o.Notes).HasMaxLength(2000);

        builder.HasIndex(o => new { o.TenantId, o.OrderNo }).IsUnique();
        builder.HasIndex(o => new { o.TenantId, o.Status });
        builder.HasIndex(o => new { o.CreatedByBusinessId, o.Status });
        builder.HasIndex(o => new { o.OrderFromBusinessId, o.AcceptanceStatus });
        builder.HasIndex(o => new { o.OrderFromExternalBusinessId, o.AcceptanceStatus });
        builder.HasIndex(o => o.DeliveryDate);

        builder.HasOne(o => o.Tenant)
            .WithMany(t => t.Orders)
            .HasForeignKey(o => o.TenantId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(o => o.CreatedByBusiness)
            .WithMany(t => t.OrdersCreated)
            .HasForeignKey(o => o.CreatedByBusinessId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(o => o.OrderFromBusiness)
            .WithMany()
            .HasForeignKey(o => o.OrderFromBusinessId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(o => o.OrderFromExternalBusiness)
            .WithMany(b => b.OrdersFrom)
            .HasForeignKey(o => o.OrderFromExternalBusinessId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(o => o.Customer)
            .WithMany(c => c.Orders)
            .HasForeignKey(o => o.CustomerId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
