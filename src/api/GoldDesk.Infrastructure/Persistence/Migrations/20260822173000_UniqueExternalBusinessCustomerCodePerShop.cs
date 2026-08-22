using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace GoldDesk.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class UniqueExternalBusinessCustomerCodePerShop : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_external_businesses_TenantId_CustomerCode",
                table: "external_businesses");

            migrationBuilder.CreateIndex(
                name: "IX_external_businesses_TenantId_CustomerCode",
                table: "external_businesses",
                columns: new[] { "TenantId", "CustomerCode" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_external_businesses_TenantId_CustomerCode",
                table: "external_businesses");

            migrationBuilder.CreateIndex(
                name: "IX_external_businesses_TenantId_CustomerCode",
                table: "external_businesses",
                columns: new[] { "TenantId", "CustomerCode" });
        }
    }
}
