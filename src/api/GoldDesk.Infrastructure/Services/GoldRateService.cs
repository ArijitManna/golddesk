using System.Text.Json;
using GoldDesk.Application.Common.Interfaces;
using Microsoft.Extensions.Logging;

namespace GoldDesk.Infrastructure.Services;

/// <summary>
/// Fetches international gold spot (USD/oz) and converts to INR/g for 24K and 22K.
/// Uses free public APIs (no API key): gold-api.com + frankfurter.app.
/// Cached for 15 minutes.
/// </summary>
public class GoldRateService : IGoldRateService
{
    private static readonly TimeSpan CacheTtl = TimeSpan.FromMinutes(15);
    private const decimal TroyOunceGrams = 31.1034768m;

    private readonly IHttpClientFactory _httpClientFactory;
    private readonly ILogger<GoldRateService> _logger;
    private readonly object _lock = new();
    private GoldRateSnapshot? _cache;
    private DateTime _cacheExpiresAtUtc = DateTime.MinValue;
    private decimal? _previous24k;

    public GoldRateService(
        IHttpClientFactory httpClientFactory,
        ILogger<GoldRateService> logger)
    {
        _httpClientFactory = httpClientFactory;
        _logger = logger;
    }

    public async Task<GoldRateSnapshot?> GetLatestAsync(CancellationToken cancellationToken = default)
    {
        lock (_lock)
        {
            if (_cache != null && DateTime.UtcNow < _cacheExpiresAtUtc)
                return _cache;
        }

        try
        {
            var client = _httpClientFactory.CreateClient(nameof(GoldRateService));
            client.Timeout = TimeSpan.FromSeconds(12);

            using var goldResponse = await client.GetAsync(
                "https://api.gold-api.com/price/XAU",
                cancellationToken);
            goldResponse.EnsureSuccessStatusCode();
            await using var goldStream = await goldResponse.Content.ReadAsStreamAsync(cancellationToken);
            using var goldDoc = await JsonDocument.ParseAsync(goldStream, cancellationToken: cancellationToken);
            if (!goldDoc.RootElement.TryGetProperty("price", out var priceEl) ||
                !priceEl.TryGetDecimal(out var usdPerOz))
            {
                _logger.LogWarning("Gold API response missing price");
                return _cache;
            }

            using var fxResponse = await client.GetAsync(
                "https://api.frankfurter.app/latest?from=USD&to=INR",
                cancellationToken);
            fxResponse.EnsureSuccessStatusCode();
            await using var fxStream = await fxResponse.Content.ReadAsStreamAsync(cancellationToken);
            using var fxDoc = await JsonDocument.ParseAsync(fxStream, cancellationToken: cancellationToken);
            if (!fxDoc.RootElement.TryGetProperty("rates", out var rates) ||
                !rates.TryGetProperty("INR", out var inrEl) ||
                !inrEl.TryGetDecimal(out var usdToInr))
            {
                _logger.LogWarning("FX API response missing INR rate");
                return _cache;
            }

            var inrPerOz = usdPerOz * usdToInr;
            var rate24k = Math.Round(inrPerOz / TroyOunceGrams, 0, MidpointRounding.AwayFromZero);
            var rate22k = Math.Round(rate24k * 22m / 24m, 0, MidpointRounding.AwayFromZero);

            decimal? changePct = null;
            if (_previous24k is > 0)
            {
                changePct = Math.Round(
                    (rate24k - _previous24k.Value) / _previous24k.Value * 100m,
                    1,
                    MidpointRounding.AwayFromZero);
            }

            var snapshot = new GoldRateSnapshot(
                rate24k,
                rate22k,
                changePct,
                DateTime.UtcNow,
                "International spot (gold-api.com + frankfurter)");

            lock (_lock)
            {
                _previous24k = rate24k;
                _cache = snapshot;
                _cacheExpiresAtUtc = DateTime.UtcNow.Add(CacheTtl);
            }

            return snapshot;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to fetch live gold rates");
            lock (_lock)
            {
                return _cache;
            }
        }
    }
}
