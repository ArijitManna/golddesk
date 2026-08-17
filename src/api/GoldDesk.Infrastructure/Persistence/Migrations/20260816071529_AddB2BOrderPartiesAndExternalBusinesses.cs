using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace GoldDesk.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddB2BOrderPartiesAndExternalBusinesses : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<Guid>(
                name: "CustomerId",
                table: "orders",
                type: "uuid",
                nullable: true,
                oldClrType: typeof(Guid),
                oldType: "uuid");

            migrationBuilder.AddColumn<string>(
                name: "AcceptanceNote",
                table: "orders",
                type: "character varying(1000)",
                maxLength: 1000,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "AcceptanceStatus",
                table: "orders",
                type: "character varying(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<DateTime>(
                name: "AcceptedAt",
                table: "orders",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "OrderFromBusinessId",
                table: "orders",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "OrderFromExternalBusinessId",
                table: "orders",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "RejectedAt",
                table: "orders",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "external_businesses",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    BusinessType = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    ContactPerson = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: true),
                    Mobile = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: true),
                    Email = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    Address = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    LinkedBusinessId = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    TenantId = table.Column<Guid>(type: "uuid", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_external_businesses", x => x.Id);
                    table.ForeignKey(
                        name: "FK_external_businesses_tenants_LinkedBusinessId",
                        column: x => x.LinkedBusinessId,
                        principalTable: "tenants",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_orders_OrderFromBusinessId_AcceptanceStatus",
                table: "orders",
                columns: new[] { "OrderFromBusinessId", "AcceptanceStatus" });

            migrationBuilder.CreateIndex(
                name: "IX_orders_OrderFromExternalBusinessId_AcceptanceStatus",
                table: "orders",
                columns: new[] { "OrderFromExternalBusinessId", "AcceptanceStatus" });

            migrationBuilder.CreateIndex(
                name: "IX_external_businesses_LinkedBusinessId",
                table: "external_businesses",
                column: "LinkedBusinessId");

            migrationBuilder.CreateIndex(
                name: "IX_external_businesses_TenantId_Name",
                table: "external_businesses",
                columns: new[] { "TenantId", "Name" });

            migrationBuilder.AddForeignKey(
                name: "FK_orders_external_businesses_OrderFromExternalBusinessId",
                table: "orders",
                column: "OrderFromExternalBusinessId",
                principalTable: "external_businesses",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_orders_tenants_OrderFromBusinessId",
                table: "orders",
                column: "OrderFromBusinessId",
                principalTable: "tenants",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_orders_external_businesses_OrderFromExternalBusinessId",
                table: "orders");

            migrationBuilder.DropForeignKey(
                name: "FK_orders_tenants_OrderFromBusinessId",
                table: "orders");

            migrationBuilder.DropTable(
                name: "external_businesses");

            migrationBuilder.DropIndex(
                name: "IX_orders_OrderFromBusinessId_AcceptanceStatus",
                table: "orders");

            migrationBuilder.DropIndex(
                name: "IX_orders_OrderFromExternalBusinessId_AcceptanceStatus",
                table: "orders");

            migrationBuilder.DropColumn(
                name: "AcceptanceNote",
                table: "orders");

            migrationBuilder.DropColumn(
                name: "AcceptanceStatus",
                table: "orders");

            migrationBuilder.DropColumn(
                name: "AcceptedAt",
                table: "orders");

            migrationBuilder.DropColumn(
                name: "OrderFromBusinessId",
                table: "orders");

            migrationBuilder.DropColumn(
                name: "OrderFromExternalBusinessId",
                table: "orders");

            migrationBuilder.DropColumn(
                name: "RejectedAt",
                table: "orders");

            migrationBuilder.AlterColumn<Guid>(
                name: "CustomerId",
                table: "orders",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"),
                oldClrType: typeof(Guid),
                oldType: "uuid",
                oldNullable: true);
        }
    }
}
