using GoldDesk.Application.Common.Events;
using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Orders.Dtos;
using GoldDesk.Domain.Entities;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Assignments.AssignKarigar;

public class AssignKarigarCommandHandler : IRequestHandler<AssignKarigarCommand, Result<AssignmentDto>>
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;
    private readonly IMediator _mediator;

    public AssignKarigarCommandHandler(IApplicationDbContext context, ICurrentUserService currentUser, IMediator mediator)
    {
        _context = context;
        _currentUser = currentUser;
        _mediator = mediator;
    }

    public async Task<Result<AssignmentDto>> Handle(AssignKarigarCommand request, CancellationToken cancellationToken)
    {
        var order = await _context.Orders
            .Include(o => o.Assignments.Where(a => a.IsActive))
            .FirstOrDefaultAsync(o => o.Id == request.OrderId, cancellationToken);

        if (order == null)
            return Result<AssignmentDto>.NotFound("Order not found");

        if (!_currentUser.TenantId.HasValue || order.TenantId != _currentUser.TenantId.Value)
            return Result<AssignmentDto>.Forbidden("Only the fulfilling Shop can assign a Karigar");

        if (order.AcceptanceStatus != OrderAcceptanceStatus.Accepted)
            return Result<AssignmentDto>.Failure("Accept the incoming order before giving work to a Karigar.");

        if (order.Status == OrderStatus.Delivered || order.Status == OrderStatus.Closed || order.Status == OrderStatus.Cancelled)
            return Result<AssignmentDto>.Failure($"Cannot assign Karigar to an order with status '{order.Status}'");

        // Only an independent Karigar with an accepted Shop↔Karigar connection can receive work.
        var karigar = await _context.Karigars
            .IgnoreQueryFilters()
            .FirstOrDefaultAsync(k => k.Id == request.KarigarId && k.Status == KarigarStatus.Active, cancellationToken);

        if (karigar == null)
            return Result<AssignmentDto>.NotFound("Karigar not found or inactive");

        var connected = await _context.BusinessConnections.AnyAsync(c =>
            c.ConnectionType == ConnectionType.ShopKarigar &&
            c.Status == ConnectionStatus.Accepted &&
            ((c.FromBusinessId == order.TenantId && c.ToBusinessId == karigar.TenantId) ||
             (c.FromBusinessId == karigar.TenantId && c.ToBusinessId == order.TenantId)),
            cancellationToken);

        if (!connected)
            return Result<AssignmentDto>.Forbidden("Assign only a Karigar with an accepted connection");

        // Parse dates — karigar due date is one day before the order delivery date
        var givenDate = DateOnly.Parse(request.GivenDate);
        DateOnly dueDate;
        if (order.DeliveryDate.HasValue)
        {
            dueDate = order.DeliveryDate.Value.AddDays(-1);
        }
        else if (!string.IsNullOrWhiteSpace(request.DueDate) && DateOnly.TryParse(request.DueDate, out var parsedDue))
        {
            dueDate = parsedDue;
        }
        else
        {
            return Result<AssignmentDto>.Failure("Due date is required when the order has no delivery date");
        }

        if (dueDate < givenDate)
            dueDate = givenDate;

        // Deactivate existing active assignment (reassignment)
        foreach (var existing in order.Assignments.Where(a => a.IsActive))
        {
            existing.IsActive = false;
            existing.Status = AssignmentStatus.Reassigned;
        }

        // Create new assignment
        var assignment = new OrderAssignment
        {
            OrderId = order.Id,
            KarigarId = request.KarigarId,
            GivenDate = givenDate,
            DueDate = dueDate,
            Status = AssignmentStatus.PendingAcceptance,
            Notes = request.Notes,
            AssignedBy = _currentUser.UserId ?? Guid.Empty,
            IsActive = true
        };

        _context.OrderAssignments.Add(assignment);
        _context.OrderEvents.Add(new OrderEvent
        {
            OrderId = order.Id,
            BusinessId = order.TenantId,
            UserId = _currentUser.UserId,
            EventType = "WorkGiven",
            Description = $"Work given to {karigar.Name}; awaiting Karigar acceptance"
        });

        // Update order status to Assigned if currently Pending
        if (order.Status == OrderStatus.Pending)
        {
            var previousStatus = order.Status;
            order.Status = OrderStatus.Assigned;

            _context.OrderStatusHistory.Add(new OrderStatusHistory
            {
                OrderId = order.Id,
                FromStatus = previousStatus,
                ToStatus = OrderStatus.Assigned,
                ChangedBy = _currentUser.UserId ?? Guid.Empty,
                Remarks = $"Assigned to {karigar.Name}"
            });
        }

        await _context.SaveChangesAsync(cancellationToken);

        // Publish notification events
        var hadPreviousAssignment = order.Assignments.Count(a => !a.IsActive && a.Status == AssignmentStatus.Reassigned) > 0;

        if (karigar.UserId.HasValue)
        {
            if (hadPreviousAssignment)
            {
                await _mediator.Publish(new OrderReassignedEvent
                {
                    TenantId = karigar.TenantId,
                    OrderId = order.Id,
                    OrderNo = order.OrderNo,
                    NewKarigarUserId = karigar.UserId.Value,
                    NewKarigarName = karigar.Name
                }, cancellationToken);
            }
            else
            {
                await _mediator.Publish(new OrderAssignedEvent
                {
                    TenantId = karigar.TenantId,
                    OrderId = order.Id,
                    OrderNo = order.OrderNo,
                    KarigarUserId = karigar.UserId.Value,
                    KarigarName = karigar.Name,
                    DueDate = dueDate.ToString("yyyy-MM-dd")
                }, cancellationToken);
            }
        }

        return Result<AssignmentDto>.Created(new AssignmentDto
        {
            Id = assignment.Id,
            KarigarName = karigar.Name,
            KarigarId = karigar.Id,
            GivenDate = assignment.GivenDate.ToString("yyyy-MM-dd"),
            DueDate = assignment.DueDate.ToString("yyyy-MM-dd"),
            Status = assignment.Status.ToString(),
            Notes = assignment.Notes,
            IsActive = assignment.IsActive,
            CreatedAt = assignment.CreatedAt
        });
    }
}
