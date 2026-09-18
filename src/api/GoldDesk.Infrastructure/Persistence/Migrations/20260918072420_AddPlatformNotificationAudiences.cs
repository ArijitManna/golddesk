using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace GoldDesk.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddPlatformNotificationAudiences : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "TargetAudiences",
                table: "PlatformNotifications",
                type: "character varying(100)",
                maxLength: 100,
                nullable: false,
                defaultValue: "Shop,Showroom,Karigar");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "TargetAudiences",
                table: "PlatformNotifications");
        }
    }
}
