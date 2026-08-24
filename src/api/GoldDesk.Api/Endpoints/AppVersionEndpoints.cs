using GoldDesk.Api.Services;
using GoldDesk.Domain.Entities;
using GoldDesk.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Api.Endpoints;

public static class AppVersionEndpoints
{
    public static void MapAppVersionEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/app-version").WithTags("App Version");

        group.MapGet("/check", async (
            HttpContext httpContext,
            IConfiguration configuration,
            IWebHostEnvironment environment,
            string? currentVersion,
            ApplicationDbContext db) =>
        {
            var latest = await db.AppVersions
                .OrderByDescending(v => v.CreatedAt)
                .FirstOrDefaultAsync();

            if (latest == null)
                return Results.Ok(new { updateAvailable = false });

            var needsUpdate = AppVersionHelper.IsUpdateRequired(currentVersion, latest.Version);
            var downloadUrl = ResolveDownloadUrl(
                httpContext,
                configuration,
                environment,
                latest.DownloadUrl);

            return Results.Ok(new
            {
                updateAvailable = needsUpdate,
                forceUpdate = needsUpdate && latest.ForceUpdate,
                latestVersion = latest.Version,
                downloadUrl,
                releaseNotes = latest.ReleaseNotes
            });
        })
        .AllowAnonymous()
        .WithName("CheckAppVersion");

        group.MapPost("/", async (
            SetAppVersionRequest request,
            HttpContext httpContext,
            IConfiguration configuration,
            IWebHostEnvironment environment,
            ApplicationDbContext db) =>
        {
            var downloadUrl = string.IsNullOrWhiteSpace(request.DownloadUrl)
                ? ResolveDownloadUrl(httpContext, configuration, environment, null)
                : request.DownloadUrl;

            var version = new AppVersion
            {
                Version = request.Version,
                DownloadUrl = downloadUrl,
                ForceUpdate = request.ForceUpdate,
                ReleaseNotes = request.ReleaseNotes
            };
            db.AppVersions.Add(version);
            await db.SaveChangesAsync();
            return Results.Created($"/app-version/{version.Id}", version);
        })
        .RequireAuthorization(policy => policy.RequireRole("SuperAdmin"))
        .WithName("SetAppVersion");
    }

    private static string ResolveDownloadUrl(
        HttpContext httpContext,
        IConfiguration configuration,
        IWebHostEnvironment environment,
        string? configuredUrl)
    {
        if (!string.IsNullOrWhiteSpace(configuredUrl))
            return configuredUrl;

        var apkFileName = configuration["AppUpdates:ApkFileName"] ?? "golddesk.apk";
        var outputFolder = configuration["AppUpdates:OutputFolder"] ?? "output";
        var outputPath = Path.Combine(environment.ContentRootPath, outputFolder);

        if (Directory.Exists(outputPath))
        {
            var apkFiles = Directory.GetFiles(outputPath, "*.apk")
                .OrderByDescending(File.GetLastWriteTimeUtc)
                .ToArray();

            if (apkFiles.Length > 0)
                apkFileName = Path.GetFileName(apkFiles[0]);
        }

        return $"{httpContext.Request.Scheme}://{httpContext.Request.Host}/{outputFolder}/{apkFileName}";
    }
}

public record SetAppVersionRequest
{
    public string Version { get; init; } = string.Empty;
    public string? DownloadUrl { get; init; }
    public bool ForceUpdate { get; init; }
    public string? ReleaseNotes { get; init; }
}
