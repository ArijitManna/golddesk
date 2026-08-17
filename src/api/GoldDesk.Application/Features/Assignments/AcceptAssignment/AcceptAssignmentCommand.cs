using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Domain.Entities;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Assignments.AcceptAssignment;

public record AcceptAssignmentCommand(Guid OrderId) : IRequest<Result<bool>>;

public class AcceptAssignmentCommandHandler
    : IRequestHandler<AcceptAssignmentCommand, Result<bool>>
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;
    private readonly INotificationService _notifications;

    public AcceptAssignmentCommandHandler(
        IApplicationDbContext context,
        ICurrentUserService currentUser,
        INotificationService notifications)
    {
        _context = context;
        _currentUser = currentUser;
        _notifications = notifications;
    }

    public async Task<Result<bool>> Handle(AcceptAssignmentCommand request, CancellationToken cancellationToken)
    {
        var karigar = await _context.Karigars
            .IgnoreQueryFilters()
            .FirstOrDefaultAsync(k => k.UserId == _currentUser.UserId, cancellationToken);
        if (karigar == null)
            return Result<bool>.Forbidden("You are not registered as a Karigar.");

        var assignment = await _context.OrderAssignments
            .IgnoreQueryFilters()
            .Include(a => a.Order)
            .FirstOrDefaultAsync(a => a.OrderId == request.OrderId &&
                                      a.KarigarId == karigar.Id &&
                                      a.IsActive,
                cancellationToken);
        if (assignment == null)
            return Result<bool>.NotFound("No active work assignment found.");

        if (assignment.Status != AssignmentStatus.PendingAcceptance)
            return Result<bool>.Failure("This work assignment has already been accepted.");

        assignment.Status = AssignmentStatus.Active;
        assignment.AcceptedAt = DateTime.UtcNow;
        _context.OrderEvents.Add(new OrderEvent
        {
            OrderId = assignment.OrderId,
            BusinessId = karigar.TenantId,
            UserId = _currentUser.UserId,
            EventType = "WorkAccepted",
            Description = "Karigar accepted the work"
        });
        await _context.SaveChangesAsync(cancellationToken);

        var shopOwnerIds = await _context.Users
            .IgnoreQueryFilters()
            .Where(u => u.TenantId == assignment.Order.TenantId &&
                        u.Role == UserRole.ShopOwner &&
                        u.Status == UserStatus.Active)
            .Select(u => u.Id)
            .ToListAsync(cancellationToken);

        foreach (var shopOwnerId in shopOwnerIds)
        {
            await _notifications.CreateAndPushAsync(
                assignment.Order.TenantId,
                shopOwnerId,
                assignment.OrderId,
                NotificationType.WorkAccepted,
                "Work accepted",
                $"{karigar.Name} accepted work for order {assignment.Order.OrderNo}.",
                cancellationToken);
        }

        return Result<bool>.Success(true);
    }
}
