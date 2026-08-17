using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Orders.Dtos;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Assignments.GetAssignmentHistory;

public class GetAssignmentHistoryQueryHandler : IRequestHandler<GetAssignmentHistoryQuery, Result<List<AssignmentDto>>>
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;

    public GetAssignmentHistoryQueryHandler(IApplicationDbContext context, ICurrentUserService currentUser)
    {
        _context = context;
        _currentUser = currentUser;
    }

    public async Task<Result<List<AssignmentDto>>> Handle(GetAssignmentHistoryQuery request, CancellationToken cancellationToken)
    {
        if (!_currentUser.TenantId.HasValue)
            return Result<List<AssignmentDto>>.Unauthorized();

        var tenantId = _currentUser.TenantId.Value;
        var viewer = await _context.Tenants
            .AsNoTracking()
            .FirstOrDefaultAsync(t => t.Id == tenantId, cancellationToken);

        if (viewer == null)
            return Result<List<AssignmentDto>>.NotFound("Business profile not found");

        if (viewer.BusinessType != BusinessType.Shop)
            return Result<List<AssignmentDto>>.Forbidden("Only the fulfilling shop can view assignment history");

        var order = await _context.Orders
            .IgnoreQueryFilters()
            .AsNoTracking()
            .FirstOrDefaultAsync(o => o.Id == request.OrderId, cancellationToken);

        if (order == null)
            return Result<List<AssignmentDto>>.NotFound("Order not found");

        if (order.TenantId != tenantId)
            return Result<List<AssignmentDto>>.Forbidden("Only the fulfilling shop can view assignment history");

        var assignments = await _context.OrderAssignments
            .Include(a => a.Karigar)
            .Where(a => a.OrderId == request.OrderId)
            .OrderByDescending(a => a.CreatedAt)
            .Select(a => new AssignmentDto
            {
                Id = a.Id,
                KarigarName = a.Karigar.Name,
                KarigarId = a.KarigarId,
                GivenDate = a.GivenDate.ToString("yyyy-MM-dd"),
                DueDate = a.DueDate.ToString("yyyy-MM-dd"),
                Status = a.Status.ToString(),
                Notes = a.Notes,
                IsActive = a.IsActive,
                CreatedAt = a.CreatedAt
            })
            .ToListAsync(cancellationToken);

        return Result<List<AssignmentDto>>.Success(assignments);
    }
}
