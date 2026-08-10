using GoldDesk.Application.Common.Models;
using MediatR;

namespace GoldDesk.Application.Features.Notifications.GetNotifications;

public record GetNotificationsQuery : IRequest<Result<PagedResult<NotificationDto>>>
{
    public bool? UnreadOnly { get; init; }
    public int Page { get; init; } = 1;
    public int PageSize { get; init; } = 20;
}

public record NotificationDto
{
    public Guid Id { get; init; }
    public Guid? OrderId { get; init; }
    public string Type { get; init; } = string.Empty;
    public string Title { get; init; } = string.Empty;
    public string Message { get; init; } = string.Empty;
    public bool IsRead { get; init; }
    public DateTime CreatedAt { get; init; }
}
