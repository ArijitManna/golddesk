using GoldDesk.Domain.Enums;

namespace GoldDesk.Application.Common.Interfaces;

public interface ICurrentUserService
{
    Guid? UserId { get; }
    Guid? TenantId { get; }
    UserRole? Role { get; }
    string? Email { get; }
    bool IsAuthenticated { get; }
}
