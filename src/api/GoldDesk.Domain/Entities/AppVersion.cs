using GoldDesk.Domain.Common;

namespace GoldDesk.Domain.Entities;

public class AppVersion : BaseEntity
{
    public string Version { get; set; } = string.Empty;
    public string? DownloadUrl { get; set; }
    public bool ForceUpdate { get; set; }
    public string? ReleaseNotes { get; set; }
}
