namespace GoldDesk.Application.Features.ShopProfile.Dtos;

public class TenantProfileDto
{
    public Guid Id { get; init; }
    public string ShopName { get; init; } = string.Empty;
    public string OwnerName { get; init; } = string.Empty;
    public string Mobile { get; init; } = string.Empty;
    public string Email { get; init; } = string.Empty;
    public string? Address { get; init; }
    public string? GstNumber { get; init; }
    public string? LogoPath { get; init; }
    public string BusinessType { get; init; } = "Shop";
    public string GoldDeskId { get; init; } = string.Empty;
    public bool NotifyDueSoon3Days { get; init; }
    public bool NotifyDueSoon2Days { get; init; }
    public bool NotifyDueSoon1Day { get; init; }
    public bool NotifyDueToday { get; init; }
    public bool NotifyOverdue { get; init; }
}
