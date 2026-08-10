using GoldDesk.Domain.Common;

namespace GoldDesk.Domain.Entities;

public class ItemMaster : BaseTenantEntity
{
    public string Name { get; set; } = string.Empty;
    public string? Category { get; set; }
    public string? Purity { get; set; }
    public decimal? DefaultRate { get; set; }
    public decimal? DefaultMakingCharge { get; set; }
    public bool IsActive { get; set; } = true;

    // Navigation properties
    public Tenant Tenant { get; set; } = null!;
}
