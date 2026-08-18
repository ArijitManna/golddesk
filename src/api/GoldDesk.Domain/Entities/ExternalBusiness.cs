using GoldDesk.Domain.Common;
using GoldDesk.Domain.Enums;

namespace GoldDesk.Domain.Entities;

/// <summary>
/// A business party that does not yet have a GoldDesk profile. It remains
/// owned by the business that added it and can later link to a Tenant.
/// </summary>
public class ExternalBusiness : BaseTenantEntity
{
    // Human-friendly external customer code (e.g. C00001 or P00001 style).
    // Used for order creation search (code + name).
    public string CustomerCode { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public BusinessType BusinessType { get; set; } = BusinessType.Shop;
    public string? ContactPerson { get; set; }
    public string? Mobile { get; set; }
    public string? Email { get; set; }
    public string? Address { get; set; }
    public Guid? LinkedBusinessId { get; set; }

    public Tenant? LinkedBusiness { get; set; }
    public ICollection<Order> OrdersFrom { get; set; } = new List<Order>();
}
