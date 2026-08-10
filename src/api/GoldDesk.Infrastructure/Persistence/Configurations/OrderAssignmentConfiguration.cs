using GoldDesk.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace GoldDesk.Infrastructure.Persistence.Configurations;

public class OrderAssignmentConfiguration : IEntityTypeConfiguration<OrderAssignment>
{
    public void Configure(EntityTypeBuilder<OrderAssignment> builder)
    {
        builder.ToTable("order_assignments");

        builder.HasKey(oa => oa.Id);

        builder.Property(oa => oa.Status).HasConversion<string>().HasMaxLength(50);
        builder.Property(oa => oa.Notes).HasMaxLength(1000);
        builder.Property(oa => oa.LastNotificationType).HasMaxLength(50);

        builder.HasIndex(oa => new { oa.OrderId, oa.IsActive });
        builder.HasIndex(oa => new { oa.KarigarId, oa.IsActive });
        builder.HasIndex(oa => oa.DueDate);

        builder.HasOne(oa => oa.Order)
            .WithMany(o => o.Assignments)
            .HasForeignKey(oa => oa.OrderId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(oa => oa.Karigar)
            .WithMany(k => k.Assignments)
            .HasForeignKey(oa => oa.KarigarId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
