using GoldDesk.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace GoldDesk.Infrastructure.Persistence.Configurations;

public class BusinessConnectionConfiguration : IEntityTypeConfiguration<BusinessConnection>
{
    public void Configure(EntityTypeBuilder<BusinessConnection> builder)
    {
        builder.ToTable("business_connections");

        builder.HasKey(c => c.Id);

        builder.Property(c => c.ConnectionType).HasConversion<string>().HasMaxLength(50);
        builder.Property(c => c.Status).HasConversion<string>().HasMaxLength(50);
        builder.Property(c => c.Notes).HasMaxLength(1000);

        builder.HasIndex(c => new { c.FromBusinessId, c.ToBusinessId, c.ConnectionType }).IsUnique();
        builder.HasIndex(c => new { c.ToBusinessId, c.Status });
        builder.HasIndex(c => new { c.FromBusinessId, c.Status });

        builder.HasOne(c => c.FromBusiness)
            .WithMany(t => t.ConnectionsFrom)
            .HasForeignKey(c => c.FromBusinessId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(c => c.ToBusiness)
            .WithMany(t => t.ConnectionsTo)
            .HasForeignKey(c => c.ToBusinessId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
