using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace GoldDesk.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddBusinessNetworkFoundation : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "BusinessType",
                table: "tenants",
                type: "character varying(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "Shop");

            // Add nullable first, backfill unique IDs, then enforce required + unique
            migrationBuilder.AddColumn<string>(
                name: "GoldDeskId",
                table: "tenants",
                type: "character varying(30)",
                maxLength: 30,
                nullable: true);

            migrationBuilder.Sql("""
                UPDATE tenants
                SET "GoldDeskId" = 'GD-PLATFORM'
                WHERE "Id" = '00000000-0000-0000-0000-000000000001';

                UPDATE tenants t
                SET "GoldDeskId" = 'GD-SHOP-' || LPAD(sub.rn::text, 4, '0')
                FROM (
                    SELECT "Id", ROW_NUMBER() OVER (ORDER BY "CreatedAt", "Id") AS rn
                    FROM tenants
                    WHERE "Id" <> '00000000-0000-0000-0000-000000000001'
                ) sub
                WHERE t."Id" = sub."Id";
                """);

            migrationBuilder.AlterColumn<string>(
                name: "GoldDeskId",
                table: "tenants",
                type: "character varying(30)",
                maxLength: 30,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "character varying(30)",
                oldMaxLength: 30,
                oldNullable: true);

            migrationBuilder.CreateTable(
                name: "business_connections",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    FromBusinessId = table.Column<Guid>(type: "uuid", nullable: false),
                    ToBusinessId = table.Column<Guid>(type: "uuid", nullable: false),
                    ConnectionType = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Status = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    RequestedByUserId = table.Column<Guid>(type: "uuid", nullable: false),
                    AcceptedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    RejectedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    Notes = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_business_connections", x => x.Id);
                    table.ForeignKey(
                        name: "FK_business_connections_tenants_FromBusinessId",
                        column: x => x.FromBusinessId,
                        principalTable: "tenants",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_business_connections_tenants_ToBusinessId",
                        column: x => x.ToBusinessId,
                        principalTable: "tenants",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_tenants_BusinessType",
                table: "tenants",
                column: "BusinessType");

            migrationBuilder.CreateIndex(
                name: "IX_tenants_GoldDeskId",
                table: "tenants",
                column: "GoldDeskId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_business_connections_FromBusinessId_Status",
                table: "business_connections",
                columns: new[] { "FromBusinessId", "Status" });

            migrationBuilder.CreateIndex(
                name: "IX_business_connections_FromBusinessId_ToBusinessId_Connection~",
                table: "business_connections",
                columns: new[] { "FromBusinessId", "ToBusinessId", "ConnectionType" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_business_connections_ToBusinessId_Status",
                table: "business_connections",
                columns: new[] { "ToBusinessId", "Status" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "business_connections");

            migrationBuilder.DropIndex(
                name: "IX_tenants_BusinessType",
                table: "tenants");

            migrationBuilder.DropIndex(
                name: "IX_tenants_GoldDeskId",
                table: "tenants");

            migrationBuilder.DropColumn(
                name: "BusinessType",
                table: "tenants");

            migrationBuilder.DropColumn(
                name: "GoldDeskId",
                table: "tenants");
        }
    }
}
