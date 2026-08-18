using GoldDesk.Application.Common.Interfaces;
using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace GoldDesk.Infrastructure.Services;

/// <summary>
/// Sends Firebase Cloud Messaging notifications through the Firebase Admin SDK.
/// </summary>
public class FcmNotificationSender : INotificationSender
{
    private readonly ILogger<FcmNotificationSender> _logger;
    private readonly FirebaseMessaging? _messaging;

    public FcmNotificationSender(
        ILogger<FcmNotificationSender> logger,
        IConfiguration configuration,
        IHostEnvironment environment)
    {
        _logger = logger;

        try
        {
            var credential = ResolveCredential(configuration, environment);
            if (credential == null)
            {
                _logger.LogWarning(
                    "Firebase push delivery is disabled. Place firebase-adminsdk.json under secrets/ " +
                    "or set Firebase__ServiceAccountPath / Firebase__ServiceAccountJson on the server.");
                return;
            }

            var app = FirebaseApp.DefaultInstance ?? FirebaseApp.Create(new AppOptions
            {
                Credential = credential
            });
            _messaging = FirebaseMessaging.GetMessaging(app);
            _logger.LogInformation("Firebase Admin SDK initialized for push delivery.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Firebase Admin SDK could not be initialized.");
        }
    }

    public async Task SendPushNotificationAsync(
        string deviceToken,
        string title,
        string body,
        Dictionary<string, string>? data = null,
        CancellationToken cancellationToken = default)
    {
        if (_messaging == null || string.IsNullOrWhiteSpace(deviceToken))
            return;

        var message = new Message
        {
            Token = deviceToken,
            Notification = new Notification { Title = title, Body = body },
            Data = data ?? new Dictionary<string, string>(),
            Android = new AndroidConfig
            {
                Priority = Priority.High,
                Notification = new AndroidNotification { ChannelId = "golddesk_alerts" }
            }
        };

        try
        {
            await _messaging.SendAsync(message, cancellationToken);
        }
        catch (FirebaseMessagingException ex)
        {
            _logger.LogWarning(
                ex,
                "FCM delivery failed for device token prefix {TokenPrefix}.",
                deviceToken[..Math.Min(12, deviceToken.Length)]);
        }
    }

    public async Task SendPushToMultipleAsync(
        IEnumerable<string> deviceTokens,
        string title,
        string body,
        Dictionary<string, string>? data = null,
        CancellationToken cancellationToken = default)
    {
        var tokens = deviceTokens.Where(token => !string.IsNullOrWhiteSpace(token)).Distinct().ToList();
        if (_messaging == null || tokens.Count == 0)
            return;

        await Task.WhenAll(tokens.Select(token =>
            SendPushNotificationAsync(token, title, body, data, cancellationToken)));
    }

    private GoogleCredential? ResolveCredential(
        IConfiguration configuration,
        IHostEnvironment environment)
    {
        var json = configuration["Firebase:ServiceAccountJson"];
        if (!string.IsNullOrWhiteSpace(json))
            return GoogleCredential.FromJson(json);

        foreach (var candidate in CredentialFileCandidates(configuration, environment))
        {
            if (File.Exists(candidate))
            {
                _logger.LogInformation("Using Firebase service account at {Path}", candidate);
                return GoogleCredential.FromFile(candidate);
            }
        }

        return null;
    }

    private static IEnumerable<string> CredentialFileCandidates(
        IConfiguration configuration,
        IHostEnvironment environment)
    {
        var configured = configuration["Firebase:ServiceAccountPath"];
        if (!string.IsNullOrWhiteSpace(configured))
        {
            yield return configured;
            if (!Path.IsPathRooted(configured))
            {
                yield return Path.GetFullPath(Path.Combine(environment.ContentRootPath, configured));
                yield return Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, configured));
                yield return Path.GetFullPath(Path.Combine(Directory.GetCurrentDirectory(), configured));
            }
        }

        var googleAppCreds = Environment.GetEnvironmentVariable("GOOGLE_APPLICATION_CREDENTIALS");
        if (!string.IsNullOrWhiteSpace(googleAppCreds))
            yield return googleAppCreds;

        yield return Path.Combine(environment.ContentRootPath, "secrets", "firebase-adminsdk.json");
        yield return Path.Combine(AppContext.BaseDirectory, "secrets", "firebase-adminsdk.json");
        yield return Path.Combine(Directory.GetCurrentDirectory(), "secrets", "firebase-adminsdk.json");
        yield return "/app/secrets/firebase-adminsdk.json";
    }
}
