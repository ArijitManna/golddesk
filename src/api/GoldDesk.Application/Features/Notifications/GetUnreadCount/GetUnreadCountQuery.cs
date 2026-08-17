using GoldDesk.Application.Common.Models;
using GoldDesk.Domain.Enums;
using MediatR;

namespace GoldDesk.Application.Features.Notifications.GetUnreadCount;

public record GetUnreadCountQuery : IRequest<Result<int>>
{
    public NotificationType? Type { get; init; }
    public Guid? OrderId { get; init; }
}
