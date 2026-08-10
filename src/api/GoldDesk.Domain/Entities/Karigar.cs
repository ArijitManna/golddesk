using GoldDesk.Domain.Common;
using GoldDesk.Domain.Enums;

namespace GoldDesk.Domain.Entities;

public class Karigar : BaseTenantEntity
{
    public Guid? UserId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Mobile { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string? Address { get; set; }
    public string? Specialization { get; set; }
    public KarigarStatus Status { get; set; } = KarigarStatus.Active;

    // Navigation properties
    public Tenant Tenant { get; set; } = null!;
    public User? User { get; set; }
    public ICollection<OrderAssignment> Assignments { get; set; } = new List<OrderAssignment>();
}
