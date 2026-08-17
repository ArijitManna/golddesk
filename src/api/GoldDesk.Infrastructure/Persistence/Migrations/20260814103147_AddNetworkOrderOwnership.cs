using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace GoldDesk.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddNetworkOrderOwnership : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "CreatedByBusinessId",
                table: "orders",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Source",
                table: "orders",
                type: "character varying(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "Direct");

            migrationBuilder.Sql("""
                UPDATE orders
                SET "CreatedByBusinessId" = "TenantId";
                """);

            migrationBuilder.AlterColumn<Guid>(
                name: "CreatedByBusinessId",
                table: "orders",
                type: "uuid",
                nullable: false,
                oldClrType: typeof(Guid),
                oldType: "uuid",
                oldNullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_orders_CreatedByBusinessId_Status",
                table: "orders",
                columns: new[] { "CreatedByBusinessId", "Status" });

            migrationBuilder.AddForeignKey(
                name: "FK_orders_tenants_CreatedByBusinessId",
                table: "orders",
                column: "CreatedByBusinessId",
                principalTable: "tenants",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_orders_tenants_CreatedByBusinessId",
                table: "orders");

            migrationBuilder.DropIndex(
                name: "IX_orders_CreatedByBusinessId_Status",
                table: "orders");

            migrationBuilder.DropColumn(
                name: "CreatedByBusinessId",
                table: "orders");

            migrationBuilder.DropColumn(
                name: "Source",
                table: "orders");
        }
    }
}
