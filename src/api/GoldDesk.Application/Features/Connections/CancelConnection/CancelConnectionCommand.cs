using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Connections.CancelConnection;

public record CancelConnectionCommand(Guid ConnectionId) : IRequest<Result<bool>>;

public class CancelConnectionCommandHandler
    : IRequestHandler<CancelConnectionCommand, Result<bool>>
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;

    public CancelConnectionCommandHandler(
        IApplicationDbContext context,
        ICurrentUserService currentUser)
    {
        _context = context;
        _currentUser = currentUser;
    }

    public async Task<Result<bool>> Handle(
        CancelConnectionCommand request,
        CancellationToken cancellationToken)
    {
        if (!_currentUser.TenantId.HasValue)
            return Result<bool>.Unauthorized();

        var connection = await _context.BusinessConnections
            .FirstOrDefaultAsync(c => c.Id == request.ConnectionId, cancellationToken);

        if (connection == null)
            return Result<bool>.NotFound("Connection request not found.");

        if (connection.FromBusinessId != _currentUser.TenantId.Value)
            return Result<bool>.Forbidden("Only the business that sent this request can cancel it.");

        if (connection.Status != ConnectionStatus.Pending)
            return Result<bool>.Failure("Only pending connection requests can be cancelled.");

        // Mark Inactive (not hard-delete) so a later request can reopen the same pair.
        connection.Status = ConnectionStatus.Inactive;
        connection.AcceptedAt = null;
        connection.RejectedAt = null;
        await _context.SaveChangesAsync(cancellationToken);
        return Result<bool>.Success(true);
    }
}
