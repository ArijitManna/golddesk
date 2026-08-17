using GoldDesk.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace GoldDesk.Infrastructure.Persistence.Configurations;

public class OrderCommentConfiguration : IEntityTypeConfiguration<OrderComment>
{
    public void Configure(EntityTypeBuilder<OrderComment> builder)
    {
        builder.ToTable("order_comments");
        builder.HasKey(c => c.Id);
        builder.Property(c => c.Channel).HasConversion<string>().HasMaxLength(30);
        builder.Property(c => c.Message).HasMaxLength(2000).IsRequired();
        builder.HasIndex(c => new { c.OrderId, c.Channel, c.CreatedAt });

        builder.HasOne(c => c.Order)
            .WithMany()
            .HasForeignKey(c => c.OrderId)
            .OnDelete(DeleteBehavior.Cascade);
        builder.HasOne(c => c.AuthorBusiness)
            .WithMany()
            .HasForeignKey(c => c.AuthorBusinessId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
