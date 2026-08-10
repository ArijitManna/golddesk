using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Orders.Dtos;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Orders.GetOrderById;

public class GetOrderByIdQueryHandler : IRequestHandler<GetOrderByIdQuery, Result<OrderDetailDto>>
{
    private readonly IApplicationDbContext _context;

    public GetOrderByIdQueryHandler(IApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<Result<OrderDetailDto>> Handle(GetOrderByIdQuery request, CancellationToken cancellationToken)
    {
        var order = await _context.Orders
            .Include(o => o.Customer)
            .Include(o => o.Items)
            .Include(o => o.Assignments)
                .ThenInclude(a => a.Karigar)
            .Include(o => o.StatusHistory)
            .FirstOrDefaultAsync(o => o.Id == request.Id, cancellationToken);

        if (order == null)
            return Result<OrderDetailDto>.NotFound("Order not found");

        var activeAssignment = order.Assignments.FirstOrDefault(a => a.IsActive);

        var dto = new OrderDetailDto
        {
            Id = order.Id,
            OrderNo = order.OrderNo,
            CustomerName = order.Customer.Name,
            CustomerId = order.CustomerId,
            OrderDate = order.OrderDate.ToString("yyyy-MM-dd"),
            DeliveryDate = order.DeliveryDate?.ToString("yyyy-MM-dd"),
            Status = order.Status.ToString(),
            TotalWeight = order.TotalWeight,
            MakingCharges = order.MakingCharges,
            AdvancePaid = order.AdvancePaid,
            EstimatedAmount = order.EstimatedAmount,
            Notes = order.Notes,
            KarigarName = activeAssignment?.Karigar.Name,
            DueDate = activeAssignment?.DueDate.ToString("yyyy-MM-dd"),
            CreatedAt = order.CreatedAt,
            Items = order.Items.Select(i => new OrderItemDto
            {
                Id = i.Id,
                ItemName = i.ItemName,
                Weight = i.Weight,
                Quantity = i.Quantity,
                Purity = i.Purity,
                Rate = i.Rate,
                MakingCharge = i.MakingCharge,
                Amount = i.Amount,
                Size = i.Size,
                ImagePath = i.ImagePath
            }).ToList(),
            Assignments = order.Assignments
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
                }).ToList(),
            StatusHistory = order.StatusHistory
                .OrderByDescending(h => h.CreatedAt)
                .Select(h => new StatusHistoryDto
                {
                    FromStatus = h.FromStatus.ToString(),
                    ToStatus = h.ToStatus.ToString(),
                    Remarks = h.Remarks,
                    ChangedAt = h.CreatedAt
                }).ToList()
        };

        return Result<OrderDetailDto>.Success(dto);
    }
}
