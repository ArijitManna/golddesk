using GoldDesk.Domain.Common;

namespace GoldDesk.Domain.Entities;

public class OrderItem : BaseEntity
{
    public Guid OrderId { get; set; }
    public Guid? ItemMasterId { get; set; }
    public string ItemName { get; set; } = string.Empty;
    public decimal Weight { get; set; }
    public int Quantity { get; set; } = 1;
    public string? Purity { get; set; }
    public decimal Rate { get; set; }
    public decimal MakingCharge { get; set; }
    public decimal Amount { get; set; }
    public string? Size { get; set; }
    public string? ImagePath { get; set; }

    // Navigation properties
    public Order Order { get; set; } = null!;
    public ItemMaster? ItemMaster { get; set; }
}
