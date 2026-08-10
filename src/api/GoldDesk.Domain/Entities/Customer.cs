using GoldDesk.Domain.Common;

namespace GoldDesk.Domain.Entities;

public class Customer : BaseTenantEntity
{
    public string Name { get; set; } = string.Empty;
    public string? Mobile { get; set; }
    public string? Email { get; set; }
    public string? Address { get; set; }
    public string? Notes { get; set; }
    public bool IsActive { get; set; } = true;

    // Navigation properties
    public Tenant Tenant { get; set; } = null!;
    public ICollection<Order> Orders { get; set; } = new List<Order>();
}
