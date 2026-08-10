using GoldDesk.Domain.Common;

namespace GoldDesk.Domain.Entities;

public class AuditLog : BaseTenantEntity
{
    public Guid? UserId { get; set; }
    public string Action { get; set; } = string.Empty;
    public string Entity { get; set; } = string.Empty;
    public Guid? EntityId { get; set; }
    public string? OldValues { get; set; }
    public string? NewValues { get; set; }
    public string? Details { get; set; }
}
