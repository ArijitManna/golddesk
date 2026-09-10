using GoldDesk.Api.Services;
using GoldDesk.Domain.Entities;
using GoldDesk.Infrastructure.Persistence;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Api.Endpoints;

public static class AppVersionEndpoints
{
    private const long MaxApkBytes = 200L * 1024 * 1024; // 200 MB

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
            var versions = await db.AppVersions.AsNoTracking().ToListAsync();
            var latest = AppVersionHelper.SelectLatest(versions);

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

        group.MapGet("/current", async (
            HttpContext httpContext,
            IConfiguration configuration,
            IWebHostEnvironment environment,
            ApplicationDbContext db) =>
        {
            var versions = await db.AppVersions.AsNoTracking().ToListAsync();
            var latest = AppVersionHelper.SelectLatest(versions);

            var apkInfo = GetApkInfo(configuration, environment);
            var downloadUrl = latest == null
                ? (apkInfo == null ? null : ResolveDownloadUrl(httpContext, configuration, environment, null))
                : ResolveDownloadUrl(httpContext, configuration, environment, latest.DownloadUrl);

            return Results.Ok(new
            {
                currentVersion = latest?.Version,
                forceUpdate = latest?.ForceUpdate ?? false,
                releaseNotes = latest?.ReleaseNotes,
                downloadUrl,
                createdAt = latest?.CreatedAt,
                apk = apkInfo == null ? null : new
                {
                    apkInfo.FileName,
                    apkInfo.SizeBytes,
                    apkInfo.LastModifiedUtc
                }
            });
        })
        .RequireAuthorization(policy => policy.RequireRole("SuperAdmin"))
        .WithName("GetCurrentAppVersion");

        group.MapGet("/history", async (ApplicationDbContext db) =>
        {
            var rows = await db.AppVersions
                .AsNoTracking()
                .ToListAsync();

            var ordered = rows
                .OrderByDescending(v => v.Version, Comparer<string>.Create(AppVersionHelper.CompareVersions))
                .ThenByDescending(v => v.CreatedAt)
                .Take(20)
                .Select(v => new
                {
                    v.Id,
                    v.Version,
                    v.ForceUpdate,
                    v.ReleaseNotes,
                    v.DownloadUrl,
                    v.CreatedAt
                });

            return Results.Ok(ordered);
        })
        .RequireAuthorization(policy => policy.RequireRole("SuperAdmin"))
        .WithName("GetAppVersionHistory");

        group.MapPost("/", async (
            SetAppVersionRequest request,
            HttpContext httpContext,
            IConfiguration configuration,
            IWebHostEnvironment environment,
            ApplicationDbContext db) =>
        {
            if (string.IsNullOrWhiteSpace(request.Version))
                return Results.BadRequest(new { error = "Version is required" });

            var downloadUrl = string.IsNullOrWhiteSpace(request.DownloadUrl)
                ? ResolveDownloadUrl(httpContext, configuration, environment, null)
                : request.DownloadUrl;

            var version = new AppVersion
            {
                Version = request.Version.Trim(),
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

        group.MapPost("/publish", async (
            HttpContext httpContext,
            IConfiguration configuration,
            IWebHostEnvironment environment,
            ApplicationDbContext db,
            [FromForm] string version,
            [FromForm] bool forceUpdate = false,
            [FromForm] string? releaseNotes = null,
            IFormFile? apk = null) =>
        {
            if (string.IsNullOrWhiteSpace(version))
                return Results.BadRequest(new { error = "Version is required" });

            string? savedFileName = null;
            if (apk != null && apk.Length > 0)
            {
                if (apk.Length > MaxApkBytes)
                    return Results.BadRequest(new { error = "APK exceeds 200MB limit" });

                var ext = Path.GetExtension(apk.FileName).ToLowerInvariant();
                if (ext != ".apk")
                    return Results.BadRequest(new { error = "Only .apk files are allowed" });

                var outputFolder = configuration["AppUpdates:OutputFolder"] ?? "output";
                var apkFileName = configuration["AppUpdates:ApkFileName"] ?? "golddesk.apk";
                var outputPath = Path.Combine(environment.ContentRootPath, outputFolder);
                Directory.CreateDirectory(outputPath);

                var targetPath = Path.Combine(outputPath, apkFileName);
                await using (var stream = File.Create(targetPath))
                {
                    await apk.CopyToAsync(stream);
                }

                savedFileName = apkFileName;
            }

            var downloadUrl = ResolveDownloadUrl(httpContext, configuration, environment, null);
            var row = new AppVersion
            {
                Version = version.Trim(),
                DownloadUrl = downloadUrl,
                ForceUpdate = forceUpdate,
                ReleaseNotes = string.IsNullOrWhiteSpace(releaseNotes) ? null : releaseNotes.Trim()
            };
            db.AppVersions.Add(row);
            await db.SaveChangesAsync();

            var apkInfo = GetApkInfo(configuration, environment);
            return Results.Ok(new
            {
                message = savedFileName == null
                    ? "App version saved (no new APK uploaded)"
                    : $"App version saved and APK uploaded as {savedFileName}",
                id = row.Id,
                version = row.Version,
                forceUpdate = row.ForceUpdate,
                releaseNotes = row.ReleaseNotes,
                downloadUrl = row.DownloadUrl,
                createdAt = row.CreatedAt,
                apk = apkInfo == null ? null : new
                {
                    apkInfo.FileName,
                    apkInfo.SizeBytes,
                    apkInfo.LastModifiedUtc
                }
            });
        })
        .DisableAntiforgery()
        .RequireAuthorization(policy => policy.RequireRole("SuperAdmin"))
        .WithName("PublishAppVersion");
    }

    private static ApkFileInfo? GetApkInfo(IConfiguration configuration, IWebHostEnvironment environment)
    {
        var outputFolder = configuration["AppUpdates:OutputFolder"] ?? "output";
        var outputPath = Path.Combine(environment.ContentRootPath, outputFolder);
        if (!Directory.Exists(outputPath))
            return null;

        var apkFiles = Directory.GetFiles(outputPath, "*.apk")
            .OrderByDescending(File.GetLastWriteTimeUtc)
            .ToArray();

        if (apkFiles.Length == 0)
            return null;

        var path = apkFiles[0];
        var info = new FileInfo(path);
        return new ApkFileInfo(info.Name, info.Length, info.LastWriteTimeUtc);
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

    private sealed record ApkFileInfo(string FileName, long SizeBytes, DateTime LastModifiedUtc);
}

public record SetAppVersionRequest
{
    public string Version { get; init; } = string.Empty;
    public string? DownloadUrl { get; init; }
    public bool ForceUpdate { get; init; }
    public string? ReleaseNotes { get; init; }
}
