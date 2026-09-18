using GoldDesk.Infrastructure.Services;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace GoldDesk.Infrastructure.BackgroundJobs;

/// <summary>
/// Dispatches scheduled platform push notifications every minute.
/// </summary>
public class PlatformNotificationDispatchJob : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<PlatformNotificationDispatchJob> _logger;
    private readonly TimeSpan _interval = TimeSpan.FromMinutes(1);

    public PlatformNotificationDispatchJob(
        IServiceProvider serviceProvider,
        ILogger<PlatformNotificationDispatchJob> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation(
            "Platform notification dispatcher started. Running every {Interval}",
            _interval);

        await Task.Delay(TimeSpan.FromSeconds(45), stoppingToken);

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                using var scope = _serviceProvider.CreateScope();
                var dispatcher = scope.ServiceProvider
                    .GetRequiredService<PlatformNotificationDispatcher>();
                await dispatcher.DispatchDueAsync(stoppingToken);
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                _logger.LogError(ex, "Error in platform notification dispatcher");
            }

            await Task.Delay(_interval, stoppingToken);
        }
    }
}
