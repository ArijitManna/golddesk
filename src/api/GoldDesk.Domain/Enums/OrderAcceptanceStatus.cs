namespace GoldDesk.Domain.Enums;

/// <summary>
/// The receiving Shop's decision on an incoming business order.
/// Kept independently from production/work status.
/// </summary>
public enum OrderAcceptanceStatus
{
    Pending = 0,
    Accepted = 1,
    Rejected = 2
}
