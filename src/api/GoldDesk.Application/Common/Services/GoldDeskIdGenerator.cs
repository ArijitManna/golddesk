using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Common.Services;

public static class GoldDeskIdGenerator
{
    public static string PrefixFor(BusinessType type) => type switch
    {
        BusinessType.Showroom => "GD-S",
        BusinessType.Shop => "GD-P",
        BusinessType.Karigar => "GD-K",
        _ => "GD-BIZ"
    };

    public static async Task<string> GenerateAsync(
        IApplicationDbContext context,
        BusinessType type,
        CancellationToken cancellationToken = default)
    {
        var prefix = PrefixFor(type);
        var existing = await context.Tenants
            .Where(t => t.GoldDeskId.StartsWith(prefix + "-"))
            .Select(t => t.GoldDeskId)
            .ToListAsync(cancellationToken);

        var next = 1;
        foreach (var id in existing)
        {
            var parts = id.Split('-');
            if (parts.Length >= 3 && int.TryParse(parts[^1], out var n) && n >= next)
                next = n + 1;
        }

        return $"{prefix}-{next:D3}";
    }
}
