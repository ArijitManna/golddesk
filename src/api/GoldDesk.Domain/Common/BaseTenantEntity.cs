namespace GoldDesk.Domain.Common;

public abstract class BaseTenantEntity : BaseEntity, ITenantEntity
{
    public Guid TenantId { get; set; }
}
