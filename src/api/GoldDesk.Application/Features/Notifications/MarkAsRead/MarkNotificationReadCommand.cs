using GoldDesk.Application.Common.Models;
using MediatR;

namespace GoldDesk.Application.Features.Notifications.MarkAsRead;

public record MarkNotificationReadCommand(Guid Id) : IRequest<Result<bool>>;

public record MarkAllNotificationsReadCommand : IRequest<Result<int>>;
