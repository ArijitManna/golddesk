using GoldDesk.Domain.Common;

namespace GoldDesk.Domain.Entities;

/// <summary>Append-only audit event for a B2B order workflow.</summary>
public class OrderEvent : BaseEntity
{
    public Guid OrderId { get; set; }
    public Guid BusinessId { get; set; }
    public Guid? UserId { get; set; }
    public string EventType { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;

    public Order Order { get; set; } = null!;
    public Tenant Business { get; set; } = null!;
}
