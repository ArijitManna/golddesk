using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace GoldDesk.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddExternalBusinessCustomerCode : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "CustomerCode",
                table: "external_businesses",
                type: "character varying(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "");

            migrationBuilder.CreateIndex(
                name: "IX_external_businesses_TenantId_CustomerCode",
                table: "external_businesses",
                columns: new[] { "TenantId", "CustomerCode" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_external_businesses_TenantId_CustomerCode",
                table: "external_businesses");

            migrationBuilder.DropColumn(
                name: "CustomerCode",
                table: "external_businesses");
        }
    }
}
