using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.ExternalBusinesses;

public record LinkExternalBusinessCommand : IRequest<Result<ExternalBusinessDto>>
{
    public Guid ExternalBusinessId { get; init; }
    public string GoldDeskId { get; init; } = string.Empty;
}

public class LinkExternalBusinessCommandHandler
    : IRequestHandler<LinkExternalBusinessCommand, Result<ExternalBusinessDto>>
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;

    public LinkExternalBusinessCommandHandler(IApplicationDbContext context, ICurrentUserService currentUser)
    {
        _context = context;
        _currentUser = currentUser;
    }

    public async Task<Result<ExternalBusinessDto>> Handle(LinkExternalBusinessCommand request, CancellationToken cancellationToken)
    {
        if (!_currentUser.TenantId.HasValue)
            return Result<ExternalBusinessDto>.Unauthorized();

        var external = await _context.ExternalBusinesses
            .FirstOrDefaultAsync(b => b.Id == request.ExternalBusinessId, cancellationToken);
        if (external == null)
            return Result<ExternalBusinessDto>.NotFound("External business not found.");

        var business = await _context.Tenants.AsNoTracking()
            .FirstOrDefaultAsync(t => t.GoldDeskId == request.GoldDeskId.Trim(), cancellationToken);
        if (business == null || business.Status != TenantStatus.Active)
            return Result<ExternalBusinessDto>.NotFound("Active GoldDesk business not found.");
        if (business.BusinessType != external.BusinessType)
            return Result<ExternalBusinessDto>.Failure("Business type does not match the external business.");

        var connected = await _context.BusinessConnections.AnyAsync(c =>
            c.Status == ConnectionStatus.Accepted &&
            ((c.FromBusinessId == _currentUser.TenantId.Value && c.ToBusinessId == business.Id) ||
             (c.FromBusinessId == business.Id && c.ToBusinessId == _currentUser.TenantId.Value)),
            cancellationToken);
        if (!connected)
            return Result<ExternalBusinessDto>.Failure(
                "Create and accept a GoldDesk connection before linking this external business.");

        external.LinkedBusinessId = business.Id;
        await _context.SaveChangesAsync(cancellationToken);
        return Result<ExternalBusinessDto>.Success(
            CreateExternalBusinessCommandHandler.ToDto(external));
    }
}
