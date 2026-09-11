namespace GoldDesk.Domain.Entities;

/// <summary>
/// Platform-wide API request timing log (not tenant-scoped).
/// </summary>
public class ApiRequestLog
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public string Method { get; set; } = string.Empty;
    public string Path { get; set; } = string.Empty;
    public int StatusCode { get; set; }
    public long DurationMs { get; set; }
    public Guid? UserId { get; set; }
}
