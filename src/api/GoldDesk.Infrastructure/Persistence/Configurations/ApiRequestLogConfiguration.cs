using GoldDesk.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace GoldDesk.Infrastructure.Persistence.Configurations;

public class ApiRequestLogConfiguration : IEntityTypeConfiguration<ApiRequestLog>
{
    public void Configure(EntityTypeBuilder<ApiRequestLog> builder)
    {
        builder.ToTable("ApiRequestLogs");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Method).HasMaxLength(16).IsRequired();
        builder.Property(x => x.Path).HasMaxLength(500).IsRequired();
        builder.HasIndex(x => x.CreatedAt);
        builder.HasIndex(x => x.Path);
        builder.HasIndex(x => new { x.Path, x.Method });
    }
}
