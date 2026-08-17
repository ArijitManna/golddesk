using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Connections.BlockConnection;

public record BlockConnectionCommand(Guid ConnectionId) : IRequest<Result<bool>>;

public class BlockConnectionCommandHandler
    : IRequestHandler<BlockConnectionCommand, Result<bool>>
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;

    public BlockConnectionCommandHandler(
        IApplicationDbContext context,
        ICurrentUserService currentUser)
    {
        _context = context;
        _currentUser = currentUser;
    }

    public async Task<Result<bool>> Handle(
        BlockConnectionCommand request,
        CancellationToken cancellationToken)
    {
        if (!_currentUser.TenantId.HasValue)
            return Result<bool>.Unauthorized();

        var businessId = _currentUser.TenantId.Value;
        var connection = await _context.BusinessConnections
            .FirstOrDefaultAsync(c => c.Id == request.ConnectionId, cancellationToken);

        if (connection == null)
            return Result<bool>.NotFound("Connection not found.");

        if (connection.FromBusinessId != businessId &&
            connection.ToBusinessId != businessId)
        {
            return Result<bool>.Forbidden("You cannot block this connection.");
        }

        if (connection.Status == ConnectionStatus.Blocked)
            return Result<bool>.Success(true);

        connection.Status = ConnectionStatus.Blocked;
        await _context.SaveChangesAsync(cancellationToken);
        return Result<bool>.Success(true);
    }
}
