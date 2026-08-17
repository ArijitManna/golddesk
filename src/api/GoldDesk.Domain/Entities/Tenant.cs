using GoldDesk.Domain.Common;
using GoldDesk.Domain.Enums;

namespace GoldDesk.Domain.Entities;

/// <summary>
/// Business profile in the GoldDesk network (Showroom / Shop / Karigar).
/// Existing shops are Tenants with BusinessType = Shop.
/// </summary>
public class Tenant : BaseEntity
{
    public string ShopName { get; set; } = string.Empty;
    public string OwnerName { get; set; } = string.Empty;
    public string Mobile { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? Address { get; set; }
    public string? GstNumber { get; set; }
    public string? LogoPath { get; set; }
    public BusinessType BusinessType { get; set; } = BusinessType.Shop;
    public string GoldDeskId { get; set; } = string.Empty;
    public bool NotifyDueSoon3Days { get; set; } = true;
    public bool NotifyDueSoon2Days { get; set; } = true;
    public bool NotifyDueSoon1Day { get; set; } = true;
    public bool NotifyDueToday { get; set; } = true;
    public bool NotifyOverdue { get; set; } = true;
    public TenantStatus Status { get; set; } = TenantStatus.PendingApproval;
    public string? AdminNote { get; set; }
    public Guid? ApprovedBy { get; set; }
    public DateTime? ApprovedAt { get; set; }

    // Navigation properties
    public ICollection<User> Users { get; set; } = new List<User>();
    public ICollection<Customer> Customers { get; set; } = new List<Customer>();
    public ICollection<Karigar> Karigars { get; set; } = new List<Karigar>();
    public ICollection<Order> Orders { get; set; } = new List<Order>();
    public ICollection<Order> OrdersCreated { get; set; } = new List<Order>();
    public ICollection<ItemMaster> Items { get; set; } = new List<ItemMaster>();
    public ICollection<BusinessConnection> ConnectionsFrom { get; set; } = new List<BusinessConnection>();
    public ICollection<BusinessConnection> ConnectionsTo { get; set; } = new List<BusinessConnection>();
}
