using GoldDesk.Domain.Entities;
using GoldDesk.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Api.Endpoints;

public static class AppVersionEndpoints
{
    public static void MapAppVersionEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/app-version").WithTags("App Version");

        group.MapGet("/check", async (string? currentVersion, ApplicationDbContext db) =>
        {
            var latest = await db.AppVersions
                .OrderByDescending(v => v.CreatedAt)
                .FirstOrDefaultAsync();

            if (latest == null)
                return Results.Ok(new { updateAvailable = false });

            var needsUpdate = currentVersion == null ||
                              string.Compare(latest.Version, currentVersion, StringComparison.Ordinal) > 0;

            return Results.Ok(new
            {
                updateAvailable = needsUpdate,
                forceUpdate = needsUpdate && latest.ForceUpdate,
                latestVersion = latest.Version,
                downloadUrl = latest.DownloadUrl,
                releaseNotes = latest.ReleaseNotes
            });
        })
        .AllowAnonymous()
        .WithName("CheckAppVersion");

        group.MapPost("/", async (SetAppVersionRequest request, ApplicationDbContext db) =>
        {
            var version = new AppVersion
            {
                Version = request.Version,
                DownloadUrl = request.DownloadUrl,
                ForceUpdate = request.ForceUpdate,
                ReleaseNotes = request.ReleaseNotes
            };
            db.AppVersions.Add(version);
            await db.SaveChangesAsync();
            return Results.Created($"/app-version/{version.Id}", version);
        })
        .RequireAuthorization()
        .WithName("SetAppVersion");
    }
}

public record SetAppVersionRequest
{
    public string Version { get; init; } = string.Empty;
    public string? DownloadUrl { get; init; }
    public bool ForceUpdate { get; init; }
    public string? ReleaseNotes { get; init; }
}
