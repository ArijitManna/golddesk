using GoldDesk.Domain.Common;
using GoldDesk.Domain.Enums;

namespace GoldDesk.Domain.Entities;

/// <summary>
/// Many-to-many working relationship between two independent business profiles.
/// </summary>
public class BusinessConnection : BaseEntity
{
    public Guid FromBusinessId { get; set; }
    public Guid ToBusinessId { get; set; }
    public ConnectionType ConnectionType { get; set; }
    public ConnectionStatus Status { get; set; } = ConnectionStatus.Pending;
    public Guid RequestedByUserId { get; set; }
    public DateTime? AcceptedAt { get; set; }
    public DateTime? RejectedAt { get; set; }
    public string? Notes { get; set; }

    public Tenant FromBusiness { get; set; } = null!;
    public Tenant ToBusiness { get; set; } = null!;
}
