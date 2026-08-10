using GoldDesk.Domain.Common;
using GoldDesk.Domain.Enums;

namespace GoldDesk.Domain.Entities;

public class User : BaseTenantEntity
{
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string Mobile { get; set; } = string.Empty;
    public UserRole Role { get; set; }
    public UserStatus Status { get; set; } = UserStatus.Inactive;
    public string? FcmToken { get; set; }
    public string? RefreshToken { get; set; }
    public DateTime? RefreshTokenExpiryTime { get; set; }
    public DateTime? LastLoginAt { get; set; }

    // Navigation properties
    public Tenant Tenant { get; set; } = null!;
    public Karigar? Karigar { get; set; }
}
