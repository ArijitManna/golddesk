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
    /// <summary>Primary image, shown on lists. Older app versions only read this.</summary>
    public string? ImagePath { get; set; }
    /// <summary>Extra images after the primary one, in display order.</summary>
    public List<string> AdditionalImagePaths { get; set; } = new();

    // Navigation properties
    public Order Order { get; set; } = null!;
    public ItemMaster? ItemMaster { get; set; }
}
