using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;
using GoldDesk.Application.Common.Interfaces;
using Microsoft.Extensions.Logging;

namespace GoldDesk.Infrastructure.Services;

/// <summary>
/// Fetches Indian jeweller gold rates (24K / 22K INR per gram).
/// Uses Goodreturns city pages when a city is supplied; otherwise India national.
/// Falls back to international spot if Goodreturns is unavailable.
/// Cached per city for 15 minutes.
/// </summary>
public class GoldRateService : IGoldRateService
{
    private static readonly TimeSpan CacheTtl = TimeSpan.FromMinutes(15);
    private const decimal TroyOunceGrams = 31.1034768m;
    private const string IndiaRatesUrl = "https://www.goodreturns.in/gold-rates/";
    private const string CityRatesUrlFormat = "https://www.goodreturns.in/gold-rates/{0}.html";

    private static readonly Regex IndiaPricesRegex = new(
        @"currentMetalPrices\s*=\s*\{\s*'24'\s*:\s*(?<r24>\d+(?:\.\d+)?)\s*,\s*'22'\s*:\s*(?<r22>\d+(?:\.\d+)?)",
        RegexOptions.Compiled | RegexOptions.CultureInvariant);

    /// <summary>Common GPS / geocoder names → Goodreturns city slug.</summary>
    private static readonly Dictionary<string, string> CityAliases = new(StringComparer.OrdinalIgnoreCase)
    {
        ["bengaluru"] = "bangalore",
        ["bangalore"] = "bangalore",
        ["bombay"] = "mumbai",
        ["mumbai"] = "mumbai",
        ["new delhi"] = "delhi",
        ["delhi"] = "delhi",
        ["ncr"] = "delhi",
        ["gurgaon"] = "gurgaon",
        ["gurugram"] = "gurgaon",
        ["calcutta"] = "kolkata",
        ["kolkata"] = "kolkata",
        ["madras"] = "chennai",
        ["chennai"] = "chennai",
        ["trivandrum"] = "trivandrum",
        ["thiruvananthapuram"] = "trivandrum",
        ["pondicherry"] = "pondicherry",
        ["puducherry"] = "pondicherry",
        ["vizag"] = "visakhapatnam",
        ["visakhapatnam"] = "visakhapatnam",
        ["benares"] = "varanasi",
        ["varanasi"] = "varanasi",
        ["baroda"] = "vadodara",
        ["vadodara"] = "vadodara",
        ["cochin"] = "kochi",
        ["kochi"] = "kochi",
        ["trichy"] = "trichy",
        ["tiruchirappalli"] = "trichy",
        ["tuticorin"] = "tuticorin",
        ["thoothukudi"] = "tuticorin",
        ["mangaluru"] = "mangalore",
        ["mangalore"] = "mangalore",
        ["mysuru"] = "mysore",
        ["mysore"] = "mysore",
        ["belagavi"] = "belgaum",
        ["belgaum"] = "belgaum",
        ["hubballi"] = "hubli",
        ["hubli"] = "hubli",
        ["pune"] = "pune",
        ["poona"] = "pune",
        ["hyderabad"] = "hyderabad",
        ["secunderabad"] = "hyderabad",
        ["ahmedabad"] = "ahmedabad",
        ["amdavad"] = "ahmedabad",
        ["jaipur"] = "jaipur",
        ["lucknow"] = "lucknow",
        ["chandigarh"] = "chandigarh",
        ["indore"] = "indore",
        ["bhopal"] = "bhopal",
        ["nagpur"] = "nagpur",
        ["surat"] = "surat",
        ["patna"] = "patna",
        ["ranchi"] = "ranchi",
        ["raipur"] = "raipur",
        ["bhubaneswar"] = "bhubaneswar",
        ["guwahati"] = "guwahati",
        ["kanpur"] = "kanpur",
        ["agra"] = "agra",
        ["allahabad"] = "prayagraj",
        ["prayagraj"] = "prayagraj",
        ["noida"] = "noida",
        ["ghaziabad"] = "ghaziabad",
        ["faridabad"] = "delhi",
        ["thane"] = "thane",
        ["navi mumbai"] = "mumbai",
        ["howrah"] = "kolkata",
        ["salt lake"] = "kolkata",
    };

    private readonly IHttpClientFactory _httpClientFactory;
    private readonly ILogger<GoldRateService> _logger;
    private readonly object _lock = new();
    private readonly Dictionary<string, CacheEntry> _cacheByKey = new(StringComparer.OrdinalIgnoreCase);

    public GoldRateService(
        IHttpClientFactory httpClientFactory,
        ILogger<GoldRateService> logger)
    {
        _httpClientFactory = httpClientFactory;
        _logger = logger;
    }

    public async Task<GoldRateSnapshot?> GetLatestAsync(
        string? city = null,
        CancellationToken cancellationToken = default)
    {
        var resolved = ResolveCity(city);
        var cacheKey = resolved?.Slug ?? "india";

        lock (_lock)
        {
            if (_cacheByKey.TryGetValue(cacheKey, out var cached) &&
                DateTime.UtcNow < cached.ExpiresAtUtc)
            {
                return cached.Snapshot;
            }
        }

        try
        {
            var client = _httpClientFactory.CreateClient(nameof(GoldRateService));
            client.Timeout = TimeSpan.FromSeconds(15);

            if (resolved != null)
            {
                var cityUrl = string.Format(CityRatesUrlFormat, resolved.Slug);
                var cityRates = await TryFetchGoodreturnsAsync(
                    client,
                    cityUrl,
                    $"{resolved.DisplayName} market rates (24K / 22K)",
                    cancellationToken);
                if (cityRates != null)
                {
                    return CacheAndReturn(
                        cacheKey,
                        cityRates.Value.Rate24k,
                        cityRates.Value.Rate22k,
                        cityRates.Value.Source,
                        resolved.DisplayName);
                }

                _logger.LogInformation(
                    "City gold rates unavailable for {City}; falling back to India",
                    resolved.DisplayName);
            }

            var india = await TryFetchGoodreturnsAsync(
                client,
                IndiaRatesUrl,
                "India market rates (24K / 22K)",
                cancellationToken);
            if (india != null)
            {
                return CacheAndReturn(
                    cacheKey,
                    india.Value.Rate24k,
                    india.Value.Rate22k,
                    india.Value.Source,
                    resolved?.DisplayName);
            }

            var spot = await TryFetchInternationalSpotAsync(client, cancellationToken);
            if (spot != null)
            {
                return CacheAndReturn(
                    cacheKey,
                    spot.Value.Rate24k,
                    spot.Value.Rate22k,
                    spot.Value.Source,
                    resolved?.DisplayName);
            }

            lock (_lock)
            {
                return _cacheByKey.TryGetValue(cacheKey, out var stale) ? stale.Snapshot : null;
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to fetch live gold rates");
            lock (_lock)
            {
                return _cacheByKey.TryGetValue(cacheKey, out var stale) ? stale.Snapshot : null;
            }
        }
    }

    private static ResolvedCity? ResolveCity(string? city)
    {
        if (string.IsNullOrWhiteSpace(city))
            return null;

        var cleaned = Regex.Replace(city.Trim(), @"\s+", " ");
        if (cleaned.Length < 2)
            return null;

        var key = cleaned.ToLowerInvariant();
        if (CityAliases.TryGetValue(key, out var aliasSlug))
            return new ResolvedCity(aliasSlug, ToTitleCase(aliasSlug.Replace('-', ' ')));

        // "Mumbai Suburban" / "Pune City" → try first token(s)
        var parts = cleaned.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        if (parts.Length > 1)
        {
            var firstTwo = string.Join(' ', parts.Take(2));
            if (CityAliases.TryGetValue(firstTwo.ToLowerInvariant(), out var twoSlug))
                return new ResolvedCity(twoSlug, ToTitleCase(twoSlug.Replace('-', ' ')));

            if (CityAliases.TryGetValue(parts[0].ToLowerInvariant(), out var oneSlug))
                return new ResolvedCity(oneSlug, ToTitleCase(oneSlug.Replace('-', ' ')));
        }

        var slug = ToSlug(cleaned);
        if (string.IsNullOrWhiteSpace(slug))
            return null;

        return new ResolvedCity(slug, ToTitleCase(cleaned));
    }

    private static string ToSlug(string value)
    {
        var sb = new StringBuilder(value.Length);
        foreach (var ch in value.ToLowerInvariant())
        {
            if (char.IsLetterOrDigit(ch))
                sb.Append(ch);
            else if (ch is ' ' or '-' or '_')
            {
                if (sb.Length > 0 && sb[^1] != '-')
                    sb.Append('-');
            }
        }

        return sb.ToString().Trim('-');
    }

    private static string ToTitleCase(string value) =>
        CultureInfo.GetCultureInfo("en-IN").TextInfo.ToTitleCase(value.ToLowerInvariant());

    private async Task<(decimal Rate24k, decimal Rate22k, string Source)?> TryFetchGoodreturnsAsync(
        HttpClient client,
        string url,
        string sourceLabel,
        CancellationToken cancellationToken)
    {
        try
        {
            using var request = new HttpRequestMessage(HttpMethod.Get, url);
            request.Headers.TryAddWithoutValidation(
                "User-Agent",
                "Mozilla/5.0 (compatible; GoldDesk/1.0; +https://golddesk.app)");
            request.Headers.TryAddWithoutValidation("Accept-Language", "en-IN,en;q=0.9");

            using var response = await client.SendAsync(request, cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("Goodreturns returned {Status} for {Url}", (int)response.StatusCode, url);
                return null;
            }

            var html = await response.Content.ReadAsStringAsync(cancellationToken);
            var match = IndiaPricesRegex.Match(html);
            if (!match.Success)
            {
                _logger.LogWarning("Goodreturns HTML missing currentMetalPrices for {Url}", url);
                return null;
            }

            if (!decimal.TryParse(match.Groups["r24"].Value, NumberStyles.Number, CultureInfo.InvariantCulture, out var rate24k) ||
                !decimal.TryParse(match.Groups["r22"].Value, NumberStyles.Number, CultureInfo.InvariantCulture, out var rate22k) ||
                rate24k <= 0 || rate22k <= 0)
            {
                _logger.LogWarning("Goodreturns parsed invalid gold rates for {Url}", url);
                return null;
            }

            rate24k = Math.Round(rate24k, 0, MidpointRounding.AwayFromZero);
            rate22k = Math.Round(rate22k, 0, MidpointRounding.AwayFromZero);
            return (rate24k, rate22k, sourceLabel);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Goodreturns gold rate fetch failed for {Url}", url);
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

    private GoldRateSnapshot CacheAndReturn(
        string cacheKey,
        decimal rate24k,
        decimal rate22k,
        string source,
        string? city)
    {
        lock (_lock)
        {
            decimal? changePct = null;
            if (_cacheByKey.TryGetValue(cacheKey, out var previous) && previous.Snapshot.Rate24kPerGramInr > 0)
            {
                var prev = previous.Snapshot.Rate24kPerGramInr;
                changePct = Math.Round((rate24k - prev) / prev * 100m, 1, MidpointRounding.AwayFromZero);
            }

            var snapshot = new GoldRateSnapshot(
                rate24k,
                rate22k,
                changePct,
                DateTime.UtcNow,
                source,
                city);

            _cacheByKey[cacheKey] = new CacheEntry(snapshot, DateTime.UtcNow.Add(CacheTtl));
            return snapshot;
        }
    }

    private sealed record ResolvedCity(string Slug, string DisplayName);
    private sealed record CacheEntry(GoldRateSnapshot Snapshot, DateTime ExpiresAtUtc);
}
