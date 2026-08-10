using GoldDesk.Domain.Common;
using GoldDesk.Domain.Enums;

namespace GoldDesk.Domain.Entities;

public class OrderAssignment : BaseEntity
{
    public Guid OrderId { get; set; }
    public Guid? OrderItemId { get; set; }
    public Guid KarigarId { get; set; }
    public DateOnly GivenDate { get; set; }
    public DateOnly DueDate { get; set; }
    public AssignmentStatus Status { get; set; } = AssignmentStatus.Active;
    public string? Notes { get; set; }
    public Guid AssignedBy { get; set; }
    public bool IsActive { get; set; } = true;
    public string? LastNotificationType { get; set; }

    // Navigation properties
    public Order Order { get; set; } = null!;
    public Karigar Karigar { get; set; } = null!;
}
