using GoldDesk.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace GoldDesk.Infrastructure.Persistence.Configurations;

public class OrderItemConfiguration : IEntityTypeConfiguration<OrderItem>
{
    public void Configure(EntityTypeBuilder<OrderItem> builder)
    {
        builder.ToTable("order_items");

        builder.HasKey(oi => oi.Id);

        builder.Property(oi => oi.ItemName).HasMaxLength(200).IsRequired();
        builder.Property(oi => oi.Weight).HasPrecision(18, 3);
        builder.Property(oi => oi.Purity).HasMaxLength(20);
        builder.Property(oi => oi.Rate).HasPrecision(18, 2);
        builder.Property(oi => oi.MakingCharge).HasPrecision(18, 2);
        builder.Property(oi => oi.Amount).HasPrecision(18, 2);
        builder.Property(oi => oi.Size).HasMaxLength(50);
        builder.Property(oi => oi.ImagePath).HasMaxLength(500);

        builder.HasOne(oi => oi.Order)
            .WithMany(o => o.Items)
            .HasForeignKey(oi => oi.OrderId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(oi => oi.ItemMaster)
            .WithMany()
            .HasForeignKey(oi => oi.ItemMasterId)
            .OnDelete(DeleteBehavior.SetNull);
    }
}
