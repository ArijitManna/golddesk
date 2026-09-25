using System.Globalization;
using System.Text.RegularExpressions;
using GoldDesk.Application.Common.Interfaces;
using Microsoft.Extensions.Logging;

namespace GoldDesk.Infrastructure.Services;

/// <summary>
/// Fetches India jeweller gold rates for 24K / 22K INR per gram (not city-locked).
/// Primary: Goodreturns India gold rates page (same family as Google/Bing snippets).
/// Fallback: international spot (gold-api.com) + USD→INR (frankfurter).
/// Cached for 15 minutes.
/// </summary>
public class GoldRateService : IGoldRateService
{
    private static readonly TimeSpan CacheTtl = TimeSpan.FromMinutes(15);
    private const decimal TroyOunceGrams = 31.1034768m;
    private const string IndiaRatesUrl = "https://www.goodreturns.in/gold-rates/";

    private static readonly Regex IndiaPricesRegex = new(
        @"currentMetalPrices\s*=\s*\{\s*'24'\s*:\s*(?<r24>\d+(?:\.\d+)?)\s*,\s*'22'\s*:\s*(?<r22>\d+(?:\.\d+)?)",
        RegexOptions.Compiled | RegexOptions.CultureInvariant);

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
            client.Timeout = TimeSpan.FromSeconds(15);

            var india = await TryFetchIndiaRatesAsync(client, cancellationToken);
            if (india != null)
                return CacheAndReturn(india.Value.Rate24k, india.Value.Rate22k, india.Value.Source);

            var spot = await TryFetchInternationalSpotAsync(client, cancellationToken);
            if (spot != null)
                return CacheAndReturn(spot.Value.Rate24k, spot.Value.Rate22k, spot.Value.Source);

            return _cache;
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

    private async Task<(decimal Rate24k, decimal Rate22k, string Source)?> TryFetchIndiaRatesAsync(
        HttpClient client,
        CancellationToken cancellationToken)
    {
        try
        {
            using var request = new HttpRequestMessage(HttpMethod.Get, IndiaRatesUrl);
            request.Headers.TryAddWithoutValidation(
                "User-Agent",
                "Mozilla/5.0 (compatible; GoldDesk/1.0; +https://golddesk.app)");
            request.Headers.TryAddWithoutValidation("Accept-Language", "en-IN,en;q=0.9");

            using var response = await client.SendAsync(request, cancellationToken);
            response.EnsureSuccessStatusCode();
            var html = await response.Content.ReadAsStringAsync(cancellationToken);

            var match = IndiaPricesRegex.Match(html);
            if (!match.Success)
            {
                _logger.LogWarning("Goodreturns HTML missing currentMetalPrices");
                return null;
            }

            if (!decimal.TryParse(match.Groups["r24"].Value, NumberStyles.Number, CultureInfo.InvariantCulture, out var rate24k) ||
                !decimal.TryParse(match.Groups["r22"].Value, NumberStyles.Number, CultureInfo.InvariantCulture, out var rate22k) ||
                rate24k <= 0 || rate22k <= 0)
            {
                _logger.LogWarning("Goodreturns parsed invalid gold rates");
                return null;
            }

            rate24k = Math.Round(rate24k, 0, MidpointRounding.AwayFromZero);
            rate22k = Math.Round(rate22k, 0, MidpointRounding.AwayFromZero);
            return (rate24k, rate22k, "India market rates (24K / 22K)");
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "India gold rate fetch failed; will try international spot");
            return null;
        }
    }

    private async Task<(decimal Rate24k, decimal Rate22k, string Source)?> TryFetchInternationalSpotAsync(
        HttpClient client,
        CancellationToken cancellationToken)
    {
        try
        {
            using var goldResponse = await client.GetAsync(
                "https://api.gold-api.com/price/XAU",
                cancellationToken);
            goldResponse.EnsureSuccessStatusCode();
            await using var goldStream = await goldResponse.Content.ReadAsStreamAsync(cancellationToken);
            using var goldDoc = await System.Text.Json.JsonDocument.ParseAsync(goldStream, cancellationToken: cancellationToken);
            if (!goldDoc.RootElement.TryGetProperty("price", out var priceEl) ||
                !priceEl.TryGetDecimal(out var usdPerOz))
            {
                _logger.LogWarning("Gold API response missing price");
                return null;
            }

            using var fxResponse = await client.GetAsync(
                "https://api.frankfurter.app/latest?from=USD&to=INR",
                cancellationToken);
            fxResponse.EnsureSuccessStatusCode();
            await using var fxStream = await fxResponse.Content.ReadAsStreamAsync(cancellationToken);
            using var fxDoc = await System.Text.Json.JsonDocument.ParseAsync(fxStream, cancellationToken: cancellationToken);
            if (!fxDoc.RootElement.TryGetProperty("rates", out var rates) ||
                !rates.TryGetProperty("INR", out var inrEl) ||
                !inrEl.TryGetDecimal(out var usdToInr))
            {
                _logger.LogWarning("FX API response missing INR rate");
                return null;
            }

            var inrPerOz = usdPerOz * usdToInr;
            var rate24k = Math.Round(inrPerOz / TroyOunceGrams, 0, MidpointRounding.AwayFromZero);
            var rate22k = Math.Round(rate24k * 22m / 24m, 0, MidpointRounding.AwayFromZero);
            return (rate24k, rate22k, "International spot (fallback)");
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "International spot gold rate fetch failed");
            return null;
        }
    }

    private GoldRateSnapshot CacheAndReturn(decimal rate24k, decimal rate22k, string source)
    {
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
            source);

        lock (_lock)
        {
            _previous24k = rate24k;
            _cache = snapshot;
            _cacheExpiresAtUtc = DateTime.UtcNow.Add(CacheTtl);
        }

        return snapshot;
    }
}
