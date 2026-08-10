using GoldDesk.Application.Common.Interfaces;
using Microsoft.Extensions.Logging;

namespace GoldDesk.Infrastructure.Services;

/// <summary>
/// FCM push notification sender stub.
/// Replace with actual Firebase Admin SDK implementation when Firebase is configured.
/// </summary>
public class FcmNotificationSender : INotificationSender
{
    private readonly ILogger<FcmNotificationSender> _logger;

    public FcmNotificationSender(ILogger<FcmNotificationSender> logger)
    {
        _logger = logger;
    }

    public Task SendPushNotificationAsync(
        string deviceToken,
        string title,
        string body,
        Dictionary<string, string>? data = null,
        CancellationToken cancellationToken = default)
    {
        // TODO: Implement with Firebase Admin SDK
        // var message = new FirebaseAdmin.Messaging.Message
        // {
        //     Token = deviceToken,
        //     Notification = new Notification { Title = title, Body = body },
        //     Data = data
        // };
        // await FirebaseMessaging.DefaultInstance.SendAsync(message, cancellationToken);

        _logger.LogInformation("FCM Push [STUB]: Token={Token}, Title={Title}, Body={Body}",
            deviceToken[..Math.Min(20, deviceToken.Length)] + "...", title, body);

        return Task.CompletedTask;
    }

    public Task SendPushToMultipleAsync(
        IEnumerable<string> deviceTokens,
        string title,
        string body,
        Dictionary<string, string>? data = null,
        CancellationToken cancellationToken = default)
    {
        var tokens = deviceTokens.ToList();
        _logger.LogInformation("FCM Push [STUB]: Sending to {Count} devices, Title={Title}", tokens.Count, title);

        return Task.CompletedTask;
    }
}
