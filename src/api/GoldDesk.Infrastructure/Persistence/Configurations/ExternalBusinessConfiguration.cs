using GoldDesk.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace GoldDesk.Infrastructure.Persistence.Configurations;

public class ExternalBusinessConfiguration : IEntityTypeConfiguration<ExternalBusiness>
{
    public void Configure(EntityTypeBuilder<ExternalBusiness> builder)
    {
        builder.ToTable("external_businesses");
        builder.HasKey(b => b.Id);

        builder.Property(b => b.CustomerCode)
            .HasMaxLength(50)
            .IsRequired()
            .HasDefaultValue(string.Empty);
        builder.Property(b => b.Name).HasMaxLength(200).IsRequired();
        builder.Property(b => b.BusinessType).HasConversion<string>().HasMaxLength(50);
        builder.Property(b => b.ContactPerson).HasMaxLength(150);
        builder.Property(b => b.Mobile).HasMaxLength(30);
        builder.Property(b => b.Email).HasMaxLength(200);
        builder.Property(b => b.Address).HasMaxLength(1000);

        builder.HasIndex(b => new { b.TenantId, b.Name });
        builder.HasIndex(b => new { b.TenantId, b.CustomerCode }).IsUnique();
        builder.HasIndex(b => b.LinkedBusinessId);

        builder.HasOne(b => b.LinkedBusiness)
            .WithMany()
            .HasForeignKey(b => b.LinkedBusinessId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
