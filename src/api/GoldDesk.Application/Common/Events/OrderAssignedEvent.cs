using MediatR;

namespace GoldDesk.Application.Common.Events;

public record OrderAssignedEvent : INotification
{
    public Guid TenantId { get; init; }
    public Guid OrderId { get; init; }
    public string OrderNo { get; init; } = string.Empty;
    public Guid KarigarUserId { get; init; }
    public string KarigarName { get; init; } = string.Empty;
    public string DueDate { get; init; } = string.Empty;
}

public record OrderStatusReadyEvent : INotification
{
    public Guid TenantId { get; init; }
    public Guid OrderId { get; init; }
    public string OrderNo { get; init; } = string.Empty;
    public string CustomerName { get; init; } = string.Empty;
    public string KarigarName { get; init; } = string.Empty;
}

public record OrderReassignedEvent : INotification
{
    public Guid TenantId { get; init; }
    public Guid OrderId { get; init; }
    public string OrderNo { get; init; } = string.Empty;
    public Guid NewKarigarUserId { get; init; }
    public string NewKarigarName { get; init; } = string.Empty;
}
