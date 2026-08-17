using GoldDesk.Application.Common.Interfaces;
using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using Microsoft.Extensions.Configuration;
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
        IConfiguration configuration)
    {
        _logger = logger;
        var serviceAccountPath = configuration["Firebase:ServiceAccountPath"];

        if (string.IsNullOrWhiteSpace(serviceAccountPath) || !File.Exists(serviceAccountPath))
        {
            _logger.LogWarning(
                "Firebase push delivery is disabled. Set Firebase__ServiceAccountPath to a valid service-account JSON file.");
            return;
        }

        try
        {
            var app = FirebaseApp.DefaultInstance ?? FirebaseApp.Create(new AppOptions
            {
                Credential = GoogleCredential.FromFile(serviceAccountPath)
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
}
