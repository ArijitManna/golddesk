using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Infrastructure.BackgroundJobs;
using GoldDesk.Infrastructure.Persistence;
using GoldDesk.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace GoldDesk.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddDbContext<ApplicationDbContext>(options =>
        {
            options.UseNpgsql(
                configuration.GetConnectionString("DefaultConnection"),
                b => b.MigrationsAssembly(typeof(ApplicationDbContext).Assembly.FullName));
            options.ConfigureWarnings(w =>
                w.Ignore(RelationalEventId.PendingModelChangesWarning));
        });

        services.AddScoped<IApplicationDbContext>(provider => provider.GetRequiredService<ApplicationDbContext>());
        services.AddScoped<IAuthProvider, AuthProvider>();
        services.AddScoped<INotificationService, NotificationService>();
        services.AddSingleton<INotificationSender, FcmNotificationSender>();

        // Background jobs
        services.AddHostedService<DueDateEvaluatorJob>();

        return services;
    }
}
