using GoldDesk.Domain.Common;
using GoldDesk.Domain.Enums;

namespace GoldDesk.Domain.Entities;

public class OrderStatusHistory : BaseEntity
{
    public Guid OrderId { get; set; }
    public OrderStatus FromStatus { get; set; }
    public OrderStatus ToStatus { get; set; }
    public Guid ChangedBy { get; set; }
    public string? Remarks { get; set; }

    // Navigation properties
    public Order Order { get; set; } = null!;
}
