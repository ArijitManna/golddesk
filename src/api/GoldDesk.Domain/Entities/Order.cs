using GoldDesk.Domain.Common;
using GoldDesk.Domain.Enums;

namespace GoldDesk.Domain.Entities;

public class Order : BaseTenantEntity
{
    public string OrderNo { get; set; } = string.Empty;
    /// <summary>Business profile that entered the order into GoldDesk.</summary>
    public Guid CreatedByBusinessId { get; set; }
    /// <summary>GoldDesk business that sent the order/request, when connected.</summary>
    public Guid? OrderFromBusinessId { get; set; }
    /// <summary>Non-GoldDesk business that sent the order/request.</summary>
    public Guid? OrderFromExternalBusinessId { get; set; }
    /// <summary>TenantId is the receiving/fulfilling business (Order To).</summary>
    public OrderSource Source { get; set; } = OrderSource.Direct;
    [Obsolete("Retail customers are not part of Phase 1 B2B orders.")]
    public Guid? CustomerId { get; set; }
    public OrderAcceptanceStatus AcceptanceStatus { get; set; } = OrderAcceptanceStatus.Pending;
    public DateTime? AcceptedAt { get; set; }
    public DateTime? RejectedAt { get; set; }
    public string? AcceptanceNote { get; set; }
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
    public Tenant CreatedByBusiness { get; set; } = null!;
    public Tenant? OrderFromBusiness { get; set; }
    public ExternalBusiness? OrderFromExternalBusiness { get; set; }
    [Obsolete("Retail customers are not part of Phase 1 B2B orders.")]
    public Customer? Customer { get; set; }
    public ICollection<OrderItem> Items { get; set; } = new List<OrderItem>();
    public ICollection<OrderAssignment> Assignments { get; set; } = new List<OrderAssignment>();
    public ICollection<OrderStatusHistory> StatusHistory { get; set; } = new List<OrderStatusHistory>();
}
