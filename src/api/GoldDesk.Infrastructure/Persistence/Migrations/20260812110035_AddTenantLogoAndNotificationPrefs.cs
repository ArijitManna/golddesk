using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace GoldDesk.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddTenantLogoAndNotificationPrefs : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "LogoPath",
                table: "tenants",
                type: "character varying(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "NotifyDueSoon1Day",
                table: "tenants",
                type: "boolean",
                nullable: false,
                defaultValue: true);

            migrationBuilder.AddColumn<bool>(
                name: "NotifyDueSoon2Days",
                table: "tenants",
                type: "boolean",
                nullable: false,
                defaultValue: true);

            migrationBuilder.AddColumn<bool>(
                name: "NotifyDueSoon3Days",
                table: "tenants",
                type: "boolean",
                nullable: false,
                defaultValue: true);

            migrationBuilder.AddColumn<bool>(
                name: "NotifyDueToday",
                table: "tenants",
                type: "boolean",
                nullable: false,
                defaultValue: true);

            migrationBuilder.AddColumn<bool>(
                name: "NotifyOverdue",
                table: "tenants",
                type: "boolean",
                nullable: false,
                defaultValue: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "LogoPath",
                table: "tenants");

            migrationBuilder.DropColumn(
                name: "NotifyDueSoon1Day",
                table: "tenants");

            migrationBuilder.DropColumn(
                name: "NotifyDueSoon2Days",
                table: "tenants");

            migrationBuilder.DropColumn(
                name: "NotifyDueSoon3Days",
                table: "tenants");

            migrationBuilder.DropColumn(
                name: "NotifyDueToday",
                table: "tenants");

            migrationBuilder.DropColumn(
                name: "NotifyOverdue",
                table: "tenants");
        }
    }
}
