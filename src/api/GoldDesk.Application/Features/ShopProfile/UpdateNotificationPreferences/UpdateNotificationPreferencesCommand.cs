using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.ShopProfile.Dtos;
using MediatR;

namespace GoldDesk.Application.Features.ShopProfile.UpdateNotificationPreferences;

public record UpdateNotificationPreferencesCommand : IRequest<Result<TenantProfileDto>>
{
    public bool NotifyDueSoon3Days { get; init; }
    public bool NotifyDueSoon2Days { get; init; }
    public bool NotifyDueSoon1Day { get; init; }
    public bool NotifyDueToday { get; init; }
    public bool NotifyOverdue { get; init; }
}
