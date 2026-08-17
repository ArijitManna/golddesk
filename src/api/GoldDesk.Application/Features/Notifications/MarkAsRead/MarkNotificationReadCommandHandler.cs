using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Notifications.MarkAsRead;

public class MarkNotificationReadCommandHandler : IRequestHandler<MarkNotificationReadCommand, Result<bool>>
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;

    public MarkNotificationReadCommandHandler(IApplicationDbContext context, ICurrentUserService currentUser)
    {
        _context = context;
        _currentUser = currentUser;
    }

    public async Task<Result<bool>> Handle(MarkNotificationReadCommand request, CancellationToken cancellationToken)
    {
        var notification = await _context.Notifications
            .FirstOrDefaultAsync(n => n.Id == request.Id && n.UserId == _currentUser.UserId, cancellationToken);

        if (notification == null)
            return Result<bool>.NotFound("Notification not found");

        notification.IsRead = true;
        await _context.SaveChangesAsync(cancellationToken);

        return Result<bool>.Success(true);
    }
}

public class MarkAllNotificationsReadCommandHandler : IRequestHandler<MarkAllNotificationsReadCommand, Result<int>>
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;

    public MarkAllNotificationsReadCommandHandler(IApplicationDbContext context, ICurrentUserService currentUser)
    {
        _context = context;
        _currentUser = currentUser;
    }

    public async Task<Result<int>> Handle(MarkAllNotificationsReadCommand request, CancellationToken cancellationToken)
    {
        var unreadNotifications = await _context.Notifications
            .Where(n => n.UserId == _currentUser.UserId && !n.IsRead)
            .ToListAsync(cancellationToken);

        foreach (var notification in unreadNotifications)
            notification.IsRead = true;

        await _context.SaveChangesAsync(cancellationToken);

        return Result<int>.Success(unreadNotifications.Count);
    }
}

public class MarkOrderCommentNotificationsReadCommandHandler
    : IRequestHandler<MarkOrderCommentNotificationsReadCommand, Result<int>>
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;

    public MarkOrderCommentNotificationsReadCommandHandler(
        IApplicationDbContext context,
        ICurrentUserService currentUser)
    {
        _context = context;
        _currentUser = currentUser;
    }

    public async Task<Result<int>> Handle(
        MarkOrderCommentNotificationsReadCommand request,
        CancellationToken cancellationToken)
    {
        var unread = await _context.Notifications
            .Where(n => n.UserId == _currentUser.UserId &&
                        !n.IsRead &&
                        n.Type == NotificationType.CommentAdded &&
                        n.OrderId == request.OrderId)
            .ToListAsync(cancellationToken);

        foreach (var notification in unread)
            notification.IsRead = true;

        await _context.SaveChangesAsync(cancellationToken);
        return Result<int>.Success(unread.Count);
    }
}
