namespace GoldDesk.Application.Common.Interfaces;

public interface IGoldRateService
{
    Task<GoldRateSnapshot?> GetLatestAsync(string? city = null, CancellationToken cancellationToken = default);
}

public record GoldRateSnapshot(
    decimal Rate24kPerGramInr,
    decimal Rate22kPerGramInr,
    decimal? ChangePercent24k,
    DateTime UpdatedAtUtc,
    string Source,
    string? City = null);
