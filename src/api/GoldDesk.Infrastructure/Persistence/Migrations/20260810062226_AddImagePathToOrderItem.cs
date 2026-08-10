using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace GoldDesk.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddImagePathToOrderItem : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ImagePath",
                table: "order_items",
                type: "character varying(500)",
                maxLength: 500,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ImagePath",
                table: "order_items");
        }
    }
}
