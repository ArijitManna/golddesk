using System.Diagnostics;
using System.Security.Claims;
using GoldDesk.Domain.Entities;
using GoldDesk.Infrastructure.Persistence;

namespace GoldDesk.Api.Middleware;

/// <summary>
/// Records duration of each API request for SuperAdmin monitoring.
/// </summary>
public class ApiTimingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ApiTimingMiddleware> _logger;

    public ApiTimingMiddleware(RequestDelegate next, ILogger<ApiTimingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context, IServiceScopeFactory scopeFactory)
    {
        if (!ShouldLog(context))
        {
            await _next(context);
            return;
        }

        var sw = Stopwatch.StartNew();
        try
        {
            await _next(context);
        }
        finally
        {
            sw.Stop();
            await TrySaveAsync(context, scopeFactory, sw.ElapsedMilliseconds);
        }
    }

    private static bool ShouldLog(HttpContext context)
    {
        var path = context.Request.Path.Value ?? string.Empty;
        if (HttpMethods.IsOptions(context.Request.Method))
            return false;

        // Only track API calls (not admin SPA / static / apk / uploads)
        if (!path.StartsWith("/api", StringComparison.OrdinalIgnoreCase) &&
            !path.StartsWith("/app-version", StringComparison.OrdinalIgnoreCase))
            return false;

        // Avoid logging the monitor endpoints themselves
        if (path.StartsWith("/api/admin/api-timing", StringComparison.OrdinalIgnoreCase))
            return false;

        return true;
    }

    private async Task TrySaveAsync(
        HttpContext context,
        IServiceScopeFactory scopeFactory,
        long durationMs)
    {
        try
        {
            var path = context.Request.Path.Value ?? "/";
            if (path.Length > 500)
                path = path[..500];

            Guid? userId = null;
            var userIdClaim = context.User?.FindFirstValue(ClaimTypes.NameIdentifier)
                ?? context.User?.FindFirstValue("sub");
            if (Guid.TryParse(userIdClaim, out var parsed))
                userId = parsed;

            using var scope = scopeFactory.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
            db.ApiRequestLogs.Add(new ApiRequestLog
            {
                Method = context.Request.Method,
                Path = path,
                StatusCode = context.Response.StatusCode,
                DurationMs = durationMs,
                UserId = userId
            });
            await db.SaveChangesAsync();
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to persist API request timing log");
        }
    }
}
