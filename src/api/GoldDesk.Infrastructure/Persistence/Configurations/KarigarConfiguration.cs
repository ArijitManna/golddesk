using GoldDesk.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace GoldDesk.Infrastructure.Persistence.Configurations;

public class KarigarConfiguration : IEntityTypeConfiguration<Karigar>
{
    public void Configure(EntityTypeBuilder<Karigar> builder)
    {
        builder.ToTable("karigars");

        builder.HasKey(k => k.Id);

        builder.Property(k => k.Name).HasMaxLength(200).IsRequired();
        builder.Property(k => k.Mobile).HasMaxLength(20).IsRequired();
        builder.Property(k => k.Email).HasMaxLength(200);
        builder.Property(k => k.Address).HasMaxLength(500);
        builder.Property(k => k.Specialization).HasMaxLength(200);
        builder.Property(k => k.Status).HasConversion<string>().HasMaxLength(50);

        builder.HasIndex(k => new { k.TenantId, k.Mobile });

        builder.HasOne(k => k.Tenant)
            .WithMany(t => t.Karigars)
            .HasForeignKey(k => k.TenantId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(k => k.User)
            .WithOne(u => u.Karigar)
            .HasForeignKey<Karigar>(k => k.UserId)
            .OnDelete(DeleteBehavior.SetNull);
    }
}
