using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace GoldDesk.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddOrderFinalWeight : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<decimal>(
                name: "FinalWeight",
                table: "orders",
                type: "numeric(18,3)",
                precision: 18,
                scale: 3,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "FinalWeight",
                table: "orders");
        }
    }
}
