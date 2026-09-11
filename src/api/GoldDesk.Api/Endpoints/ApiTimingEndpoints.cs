using GoldDesk.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Api.Endpoints;

public static class ApiTimingEndpoints
{
    public static void MapApiTimingEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/admin/api-timing")
            .WithTags("API Timing")
            .RequireAuthorization(policy => policy.RequireRole("SuperAdmin"));

        group.MapGet("/", async (
            ApplicationDbContext db,
            int? take,
            long? minMs,
            DateOnly? fromDate,
            DateOnly? toDate,
            CancellationToken ct) =>
        {
            var limit = Math.Clamp(take ?? 100, 1, 500);
            var minDuration = Math.Max(0, minMs ?? 0);

            DateTime? fromUtc = fromDate.HasValue
                ? DateTime.SpecifyKind(fromDate.Value.ToDateTime(TimeOnly.MinValue), DateTimeKind.Utc)
                : null;
            DateTime? toUtcExclusive = toDate.HasValue
                ? DateTime.SpecifyKind(toDate.Value.AddDays(1).ToDateTime(TimeOnly.MinValue), DateTimeKind.Utc)
                : null;

            // Default window for summary + endpoint aggregates when no date filter
            var since = fromUtc ?? DateTime.UtcNow.AddHours(-24);
            var until = toUtcExclusive ?? DateTime.UtcNow.AddDays(1);

            IQueryable<Domain.Entities.ApiRequestLog> BaseQuery()
            {
                var q = db.ApiRequestLogs.AsNoTracking().AsQueryable();
                if (fromUtc.HasValue)
                    q = q.Where(x => x.CreatedAt >= fromUtc.Value);
                if (toUtcExclusive.HasValue)
                    q = q.Where(x => x.CreatedAt < toUtcExclusive.Value);
                if (minDuration > 0)
                    q = q.Where(x => x.DurationMs >= minDuration);
                return q;
            }

            var filtered = BaseQuery();

            var recent = await filtered
                .OrderByDescending(x => x.DurationMs)
                .ThenByDescending(x => x.CreatedAt)
                .Take(limit)
                .Select(x => new
                {
                    x.Id,
                    x.CreatedAt,
                    x.Method,
                    x.Path,
                    x.StatusCode,
                    x.DurationMs,
                    x.UserId
                })
                .ToListAsync(ct);

            var aggregateSource = db.ApiRequestLogs.AsNoTracking()
                .Where(x => x.CreatedAt >= since && x.CreatedAt < until);
            if (minDuration > 0)
                aggregateSource = aggregateSource.Where(x => x.DurationMs >= minDuration);

            var byEndpoint = await aggregateSource
                .GroupBy(x => new { x.Method, x.Path })
                .Select(g => new
                {
                    g.Key.Method,
                    g.Key.Path,
                    Count = g.Count(),
                    AvgMs = Math.Round(g.Average(x => (double)x.DurationMs), 1),
                    MaxMs = g.Max(x => x.DurationMs),
                    MinMs = g.Min(x => x.DurationMs)
                })
                .OrderByDescending(x => x.AvgMs)
                .Take(50)
                .ToListAsync(ct);

            var totalCount = await db.ApiRequestLogs.CountAsync(ct);
            var filteredCount = await filtered.CountAsync(ct);
            var windowCount = await aggregateSource.CountAsync(ct);
            var avgWindow = windowCount == 0
                ? 0
                : await aggregateSource.AverageAsync(x => (double)x.DurationMs, ct);

            return Results.Ok(new
            {
                summary = new
                {
                    totalCount,
                    filteredCount,
                    windowCount,
                    avgMsWindow = Math.Round(avgWindow, 1),
                    minMsApplied = minDuration,
                    fromDate = fromDate?.ToString("yyyy-MM-dd"),
                    toDate = toDate?.ToString("yyyy-MM-dd")
                },
                byEndpoint,
                recent
            });
        })
        .WithName("GetApiTiming");

        group.MapDelete("/", async (ApplicationDbContext db, CancellationToken ct) =>
        {
            var deleted = await db.ApiRequestLogs.ExecuteDeleteAsync(ct);
            return Results.Ok(new
            {
                message = "API timing data permanently deleted",
                deleted
            });
        })
        .WithName("FlashApiTiming");
    }
}
