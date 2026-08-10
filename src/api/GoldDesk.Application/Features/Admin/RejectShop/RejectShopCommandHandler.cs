using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Admin.RejectShop;

public class RejectShopCommandHandler : IRequestHandler<RejectShopCommand, Result<RejectShopResponse>>
{
    private readonly IApplicationDbContext _context;

    public RejectShopCommandHandler(IApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<Result<RejectShopResponse>> Handle(RejectShopCommand request, CancellationToken cancellationToken)
    {
        var tenant = await _context.Tenants
            .IgnoreQueryFilters()
            .FirstOrDefaultAsync(t => t.Id == request.TenantId, cancellationToken);

        if (tenant == null)
            return Result<RejectShopResponse>.NotFound("Shop not found");

        if (tenant.Status != TenantStatus.PendingApproval)
            return Result<RejectShopResponse>.Failure($"Shop is already in '{tenant.Status}' status and cannot be rejected");

        tenant.Status = TenantStatus.Rejected;
        tenant.AdminNote = request.Reason;

        await _context.SaveChangesAsync(cancellationToken);

        return Result<RejectShopResponse>.Success(new RejectShopResponse
        {
            TenantId = tenant.Id,
            Message = $"Shop '{tenant.ShopName}' has been rejected"
        });
    }
}
