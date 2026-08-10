using GoldDesk.Domain.Common;
using GoldDesk.Domain.Enums;

namespace GoldDesk.Domain.Entities;

public class Order : BaseTenantEntity
{
    public string OrderNo { get; set; } = string.Empty;
    public Guid CustomerId { get; set; }
    public DateOnly OrderDate { get; set; }
    public DateOnly? DeliveryDate { get; set; }
    public OrderStatus Status { get; set; } = OrderStatus.Pending;
    public decimal TotalWeight { get; set; }
    public decimal MakingCharges { get; set; }
    public decimal AdvancePaid { get; set; }
    public decimal EstimatedAmount { get; set; }
    public string? Notes { get; set; }

    // Navigation properties
    public Tenant Tenant { get; set; } = null!;
    public Customer Customer { get; set; } = null!;
    public ICollection<OrderItem> Items { get; set; } = new List<OrderItem>();
    public ICollection<OrderAssignment> Assignments { get; set; } = new List<OrderAssignment>();
    public ICollection<OrderStatusHistory> StatusHistory { get; set; } = new List<OrderStatusHistory>();
}
