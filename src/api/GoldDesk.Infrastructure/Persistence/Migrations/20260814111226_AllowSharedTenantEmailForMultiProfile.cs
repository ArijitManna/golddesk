using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace GoldDesk.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AllowSharedTenantEmailForMultiProfile : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_tenants_Email",
                table: "tenants");

            migrationBuilder.CreateIndex(
                name: "IX_tenants_Email",
                table: "tenants",
                column: "Email");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_tenants_Email",
                table: "tenants");

            migrationBuilder.CreateIndex(
                name: "IX_tenants_Email",
                table: "tenants",
                column: "Email",
                unique: true);
        }
    }
}
