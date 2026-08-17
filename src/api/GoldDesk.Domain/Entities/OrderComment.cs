using GoldDesk.Domain.Common;
using GoldDesk.Domain.Enums;

namespace GoldDesk.Domain.Entities;

/// <summary>Private conversation entry attached to a business order.</summary>
public class OrderComment : BaseEntity
{
    public Guid OrderId { get; set; }
    public Guid AuthorBusinessId { get; set; }
    public Guid AuthorUserId { get; set; }
    public OrderCommentChannel Channel { get; set; }
    public string Message { get; set; } = string.Empty;

    public Order Order { get; set; } = null!;
    public Tenant AuthorBusiness { get; set; } = null!;
}
