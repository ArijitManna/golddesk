using GoldDesk.Application.Common.Models;
using MediatR;

namespace GoldDesk.Application.Features.Notifications.GetUnreadCount;

public record GetUnreadCountQuery : IRequest<Result<int>>;
