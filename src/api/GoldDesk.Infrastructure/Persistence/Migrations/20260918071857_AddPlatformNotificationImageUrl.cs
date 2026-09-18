using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace GoldDesk.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddPlatformNotificationImageUrl : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ImageUrl",
                table: "PlatformNotifications",
                type: "character varying(1000)",
                maxLength: 1000,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ImageUrl",
                table: "PlatformNotifications");
        }
    }
}
