using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace GoldDesk.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddPlatformNotifications : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "PlatformNotifications",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Type = table.Column<int>(type: "integer", nullable: false),
                    Title = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Body = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: false),
                    ScheduledAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    Status = table.Column<int>(type: "integer", nullable: false),
                    SentAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    TargetCount = table.Column<int>(type: "integer", nullable: false),
                    ErrorMessage = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PlatformNotifications", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_PlatformNotifications_CreatedAt",
                table: "PlatformNotifications",
                column: "CreatedAt");

            migrationBuilder.CreateIndex(
                name: "IX_PlatformNotifications_ScheduledAt",
                table: "PlatformNotifications",
                column: "ScheduledAt");

            migrationBuilder.CreateIndex(
                name: "IX_PlatformNotifications_Status",
                table: "PlatformNotifications",
                column: "Status");

            migrationBuilder.CreateIndex(
                name: "IX_PlatformNotifications_Status_ScheduledAt",
                table: "PlatformNotifications",
                columns: new[] { "Status", "ScheduledAt" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "PlatformNotifications");
        }
    }
}
