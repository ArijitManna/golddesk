namespace GoldDesk.Application.Common.Interfaces;

public interface INotificationSender
{
    Task SendPushNotificationAsync(string deviceToken, string title, string body, Dictionary<string, string>? data = null, CancellationToken cancellationToken = default);
    Task SendPushToMultipleAsync(IEnumerable<string> deviceTokens, string title, string body, Dictionary<string, string>? data = null, CancellationToken cancellationToken = default);
}
