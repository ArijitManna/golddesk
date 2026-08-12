using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace GoldDesk.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddItemCodeAndImageToItemMaster : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ImagePath",
                table: "item_master",
                type: "character varying(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ItemCode",
                table: "item_master",
                type: "character varying(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "");

            migrationBuilder.CreateIndex(
                name: "IX_item_master_TenantId_ItemCode",
                table: "item_master",
                columns: new[] { "TenantId", "ItemCode" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_item_master_TenantId_ItemCode",
                table: "item_master");

            migrationBuilder.DropColumn(
                name: "ImagePath",
                table: "item_master");

            migrationBuilder.DropColumn(
                name: "ItemCode",
                table: "item_master");
        }
    }
}
