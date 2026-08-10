using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Orders.Dtos;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Assignments.GetAssignmentHistory;

public class GetAssignmentHistoryQueryHandler : IRequestHandler<GetAssignmentHistoryQuery, Result<List<AssignmentDto>>>
{
    private readonly IApplicationDbContext _context;

    public GetAssignmentHistoryQueryHandler(IApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<Result<List<AssignmentDto>>> Handle(GetAssignmentHistoryQuery request, CancellationToken cancellationToken)
    {
        var orderExists = await _context.Orders
            .AnyAsync(o => o.Id == request.OrderId, cancellationToken);

        if (!orderExists)
            return Result<List<AssignmentDto>>.NotFound("Order not found");

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
