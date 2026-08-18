using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Common.Services;

public static class GoldDeskIdGenerator
{
    // New IDs:
    // - Showroom: S00001
    // - Shop:     P00001
    // - Karigar:  K00001
    //
    // Legacy IDs (still present in DB for already-created tenants):
    // - GD-S-001 / GD-P-001 / GD-K-001
    private static string LetterFor(BusinessType type) => type switch
    {
        BusinessType.Showroom => "S",
        BusinessType.Shop => "P",
        BusinessType.Karigar => "K",
        _ => "B"
    };

    private static string LegacyPrefixFor(BusinessType type) => type switch
    {
        BusinessType.Showroom => "GD-S",
        BusinessType.Shop => "GD-P",
        BusinessType.Karigar => "GD-K",
        _ => "GD-BIZ"
    };

    private static int? ExtractTrailingNumber(string goldDeskId, string letter, string legacyPrefix)
    {
        if (string.IsNullOrWhiteSpace(goldDeskId))
            return null;

        goldDeskId = goldDeskId.Trim().ToUpperInvariant();

        // Legacy: GD-S-001
        if (goldDeskId.StartsWith(legacyPrefix, StringComparison.OrdinalIgnoreCase))
        {
            var parts = goldDeskId.Split('-', StringSplitOptions.RemoveEmptyEntries);
            if (parts.Length >= 3 && int.TryParse(parts[^1], out var n))
                return n;
            return null;
        }

        // New: S00001
        if (goldDeskId.StartsWith(letter, StringComparison.OrdinalIgnoreCase))
        {
            var digits = goldDeskId.Substring(letter.Length);
            if (int.TryParse(digits, out var n))
                return n;
        }

        return null;
    }

    public static async Task<string> GenerateAsync(
        IApplicationDbContext context,
        BusinessType type,
        CancellationToken cancellationToken = default)
    {
        var letter = LetterFor(type);
        var legacyPrefix = LegacyPrefixFor(type);
        var existing = await context.Tenants
            .Select(t => t.GoldDeskId)
            .ToListAsync(cancellationToken);

        var next = 1;
        foreach (var id in existing)
        {
            var n = ExtractTrailingNumber(id, letter, legacyPrefix);
            if (n.HasValue && n.Value >= next)
                next = n.Value + 1;
        }

        return $"{letter}{next:D5}";
    }
}
