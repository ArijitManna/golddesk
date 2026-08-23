using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Orders.Dtos;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Orders.GetOrderById;

public class GetOrderByIdQueryHandler : IRequestHandler<GetOrderByIdQuery, Result<OrderDetailDto>>
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;

    public GetOrderByIdQueryHandler(IApplicationDbContext context, ICurrentUserService currentUser)
    {
        _context = context;
        _currentUser = currentUser;
    }

    public async Task<Result<OrderDetailDto>> Handle(GetOrderByIdQuery request, CancellationToken cancellationToken)
    {
        if (!_currentUser.TenantId.HasValue || !_currentUser.UserId.HasValue)
            return Result<OrderDetailDto>.Unauthorized();

        var tenantId = _currentUser.TenantId.Value;
        var viewer = await _context.Tenants
            .AsNoTracking()
            .FirstOrDefaultAsync(t => t.Id == tenantId, cancellationToken);
        if (viewer == null)
            return Result<OrderDetailDto>.NotFound("Business profile not found");

        var isShowroomViewer = viewer.BusinessType == BusinessType.Showroom;
        var isKarigarViewer = viewer.BusinessType == BusinessType.Karigar;

        Guid? assignedKarigarId = null;
        if (isKarigarViewer)
        {
            assignedKarigarId = await _context.Karigars
                .AsNoTracking()
                .Where(k => k.UserId == _currentUser.UserId)
                .Select(k => (Guid?)k.Id)
                .FirstOrDefaultAsync(cancellationToken);
            if (!assignedKarigarId.HasValue)
                return Result<OrderDetailDto>.Forbidden("You are not registered as a Karigar");
        }

        // Ignore related tenant filters so either order party (or assigned Karigar) can read the shared order.
        var order = await _context.Orders
            .IgnoreQueryFilters()
            .Include(o => o.CreatedByBusiness)
            .Include(o => o.OrderFromBusiness)
            .Include(o => o.OrderFromExternalBusiness)
            .Include(o => o.Tenant)
            .Include(o => o.Items)
            .Include(o => o.Assignments)
                .ThenInclude(a => a.Karigar)
            .Include(o => o.StatusHistory)
            .FirstOrDefaultAsync(o => o.Id == request.Id &&
                                      (o.TenantId == tenantId ||
                                       o.CreatedByBusinessId == tenantId ||
                                       o.OrderFromBusinessId == tenantId ||
                                       (assignedKarigarId.HasValue &&
                                        o.Assignments.Any(a => a.IsActive && a.KarigarId == assignedKarigarId.Value))),
                cancellationToken);

        if (order == null)
            return Result<OrderDetailDto>.NotFound("Order not found");

        var activeAssignment = order.Assignments.FirstOrDefault(a => a.IsActive);

        // Karigar only sees the fulfilling Shop as counterparty (never showroom/customer).
        var orderFromName = isKarigarViewer
            ? order.Tenant.ShopName
            : order.OrderFromBusiness?.ShopName ??
              order.OrderFromExternalBusiness?.Name ??
              string.Empty;

        var dueDate = isShowroomViewer
            ? order.DeliveryDate?.ToString("yyyy-MM-dd")
            : activeAssignment?.DueDate.ToString("yyyy-MM-dd")
                ?? order.DeliveryDate?.ToString("yyyy-MM-dd");

        var dto = new OrderDetailDto
        {
            Id = order.Id,
            OrderNo = order.OrderNo,
            OrderFromBusinessId = isKarigarViewer ? null : order.OrderFromBusinessId,
            OrderFromExternalBusinessId = isKarigarViewer ? null : order.OrderFromExternalBusinessId,
            OrderFromBusinessName = orderFromName,
            OrderDate = order.OrderDate.ToString("yyyy-MM-dd"),
            DeliveryDate = order.DeliveryDate?.ToString("yyyy-MM-dd"),
            Status = order.Status.ToString(),
            AcceptanceStatus = order.AcceptanceStatus.ToString(),
            AcceptanceNote = isKarigarViewer ? null : order.AcceptanceNote,
            TotalWeight = order.TotalWeight,
            MakingCharges = isKarigarViewer ? 0 : order.MakingCharges,
            AdvancePaid = isKarigarViewer ? 0 : order.AdvancePaid,
            EstimatedAmount = isKarigarViewer ? 0 : order.EstimatedAmount,
            Notes = order.Notes,
            KarigarName = isShowroomViewer || isKarigarViewer ? null : activeAssignment?.Karigar?.Name,
            AssignmentStatus = isShowroomViewer ? null : activeAssignment?.Status.ToString(),
            DueDate = dueDate,
            FirstItemImage = order.Items.Select(i => i.ImagePath).FirstOrDefault(p => p != null),
            FirstItemSize = order.Items
                .Where(i => !string.IsNullOrWhiteSpace(i.Size))
                .Select(i => i.Size)
                .FirstOrDefault(),
            Source = order.Source.ToString(),
            CreatedByBusinessId = isKarigarViewer ? order.TenantId : order.CreatedByBusinessId,
            CreatedByBusinessName = isKarigarViewer ? order.Tenant.ShopName : order.CreatedByBusiness.ShopName,
            CreatedForBusinessId = order.TenantId,
            CreatedForBusinessName = order.Tenant.ShopName,
            CreatedAt = order.CreatedAt,
            Items = order.Items
                .OrderBy(i => i.CreatedAt)
                .Select(i => new OrderItemDto
            {
                Id = i.Id,
                ItemMasterId = i.ItemMasterId,
                ItemName = i.ItemName,
                Weight = i.Weight,
                Quantity = i.Quantity,
                Purity = i.Purity,
                Rate = isKarigarViewer ? 0 : i.Rate,
                MakingCharge = isKarigarViewer ? 0 : i.MakingCharge,
                Amount = isKarigarViewer ? 0 : i.Amount,
                Size = i.Size,
                ImagePath = i.ImagePath
            }).ToList(),
            Assignments = isShowroomViewer || isKarigarViewer
                ? new List<AssignmentDto>()
                : order.Assignments
                    .OrderByDescending(a => a.CreatedAt)
                    .Select(a => new AssignmentDto
                    {
                        Id = a.Id,
                        KarigarName = a.Karigar?.Name ?? string.Empty,
                        KarigarId = a.KarigarId,
                        GivenDate = a.GivenDate.ToString("yyyy-MM-dd"),
                        DueDate = a.DueDate.ToString("yyyy-MM-dd"),
                        Status = a.Status.ToString(),
                        Notes = a.Notes,
                        IsActive = a.IsActive,
                        CreatedAt = a.CreatedAt
                    }).ToList(),
            StatusHistory = isShowroomViewer || isKarigarViewer
                ? new List<StatusHistoryDto>()
                : order.StatusHistory
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
