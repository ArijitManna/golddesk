using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Connections.Dtos;
using GoldDesk.Domain.Entities;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Connections.RespondConnection;

public class RespondConnectionCommandHandler : IRequestHandler<RespondConnectionCommand, Result<BusinessConnectionDto>>
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;
    private readonly INotificationService _notifications;

    public RespondConnectionCommandHandler(
        IApplicationDbContext context,
        ICurrentUserService currentUser,
        INotificationService notifications)
    {
        _context = context;
        _currentUser = currentUser;
        _notifications = notifications;
    }

    public async Task<Result<BusinessConnectionDto>> Handle(RespondConnectionCommand request, CancellationToken cancellationToken)
    {
        if (!_currentUser.TenantId.HasValue)
            return Result<BusinessConnectionDto>.Unauthorized();

        var myId = _currentUser.TenantId.Value;
        var connection = await _context.BusinessConnections
            .Include(c => c.FromBusiness)
            .Include(c => c.ToBusiness)
            .FirstOrDefaultAsync(c => c.Id == request.ConnectionId, cancellationToken);

        if (connection == null)
            return Result<BusinessConnectionDto>.NotFound("Connection request not found");

        // Only the target business can accept/reject
        if (connection.ToBusinessId != myId)
            return Result<BusinessConnectionDto>.Forbidden("Only the invited business can respond to this request");

        if (connection.Status != ConnectionStatus.Pending)
            return Result<BusinessConnectionDto>.Failure($"Request is already {connection.Status}");

        if (request.Accept)
        {
            connection.Status = ConnectionStatus.Accepted;
            connection.AcceptedAt = DateTime.UtcNow;
            connection.RejectedAt = null;
        }
        else
        {
            connection.Status = ConnectionStatus.Rejected;
            connection.RejectedAt = DateTime.UtcNow;
        }

        await _context.SaveChangesAsync(cancellationToken);
        if (request.Accept)
        {
            await NotifyRequestSenderAsync(connection, cancellationToken);
        }

        return Result<BusinessConnectionDto>.Success(new BusinessConnectionDto
        {
            Id = connection.Id,
            CounterpartyBusinessId = connection.FromBusinessId,
            CounterpartyName = connection.FromBusiness.ShopName,
            CounterpartyGoldDeskId = connection.FromBusiness.GoldDeskId,
            CounterpartyBusinessType = connection.FromBusiness.BusinessType.ToString(),
            ConnectionType = connection.ConnectionType.ToString(),
            Status = connection.Status.ToString(),
            IsIncoming = true,
            CreatedAt = connection.CreatedAt,
            AcceptedAt = connection.AcceptedAt
        });
    }

    private async Task NotifyRequestSenderAsync(
        BusinessConnection connection,
        CancellationToken cancellationToken)
    {
        var recipientIds = await _context.Users
            .Where(u => u.TenantId == connection.FromBusinessId && u.Status == UserStatus.Active)
            .Select(u => u.Id)
            .ToListAsync(cancellationToken);

        foreach (var recipientId in recipientIds)
        {
            await _notifications.CreateAndPushAsync(
                connection.FromBusinessId,
                recipientId,
                null,
                NotificationType.ConnectionAccepted,
                "Connection accepted",
                $"{connection.ToBusiness.ShopName} accepted your connection request.",
                cancellationToken);
        }
    }
}
