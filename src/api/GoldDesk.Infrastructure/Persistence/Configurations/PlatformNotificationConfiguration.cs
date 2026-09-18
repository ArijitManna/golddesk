using GoldDesk.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace GoldDesk.Infrastructure.Persistence.Configurations;

public class PlatformNotificationConfiguration : IEntityTypeConfiguration<PlatformNotification>
{
    public void Configure(EntityTypeBuilder<PlatformNotification> builder)
    {
        builder.ToTable("PlatformNotifications");
        builder.HasKey(x => x.Id);

        builder.Property(x => x.Title).HasMaxLength(200).IsRequired();
        builder.Property(x => x.Body).HasMaxLength(2000).IsRequired();
        builder.Property(x => x.ImageUrl).HasMaxLength(1000);
        builder.Property(x => x.ErrorMessage).HasMaxLength(1000);

        builder.HasIndex(x => x.Status);
        builder.HasIndex(x => x.ScheduledAt);
        builder.HasIndex(x => new { x.Status, x.ScheduledAt });
        builder.HasIndex(x => x.CreatedAt);
    }
}
