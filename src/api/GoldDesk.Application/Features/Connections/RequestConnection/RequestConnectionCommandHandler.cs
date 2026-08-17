using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Connections.Dtos;
using GoldDesk.Domain.Entities;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Connections.RequestConnection;

public class RequestConnectionCommandHandler : IRequestHandler<RequestConnectionCommand, Result<BusinessConnectionDto>>
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;
    private readonly INotificationService _notifications;

    public RequestConnectionCommandHandler(
        IApplicationDbContext context,
        ICurrentUserService currentUser,
        INotificationService notifications)
    {
        _context = context;
        _currentUser = currentUser;
        _notifications = notifications;
    }

    public async Task<Result<BusinessConnectionDto>> Handle(RequestConnectionCommand request, CancellationToken cancellationToken)
    {
        if (!_currentUser.TenantId.HasValue || !_currentUser.UserId.HasValue)
            return Result<BusinessConnectionDto>.Unauthorized();

        var fromId = _currentUser.TenantId.Value;
        var from = await _context.Tenants.FirstOrDefaultAsync(t => t.Id == fromId, cancellationToken);
        if (from == null)
            return Result<BusinessConnectionDto>.NotFound("Your business profile was not found");

        var targetCode = request.TargetGoldDeskId.Trim().ToUpperInvariant();
        var to = await _context.Tenants.FirstOrDefaultAsync(t => t.GoldDeskId == targetCode, cancellationToken);
        if (to == null)
            return Result<BusinessConnectionDto>.NotFound("No business found with that GoldDesk ID");

        if (to.Id == from.Id)
            return Result<BusinessConnectionDto>.Failure("You cannot connect to your own business");

        if (to.Status != TenantStatus.Active)
            return Result<BusinessConnectionDto>.Failure("That business is not active yet");

        var connectionType = ResolveConnectionType(from.BusinessType, to.BusinessType);
        if (connectionType == null)
            return Result<BusinessConnectionDto>.Failure(
                $"Cannot connect a {from.BusinessType} to a {to.BusinessType}. Allowed: Showroom↔Shop, Shop↔Karigar.");

        var existing = await _context.BusinessConnections
            .FirstOrDefaultAsync(c =>
                    (c.FromBusinessId == from.Id && c.ToBusinessId == to.Id) ||
                    (c.FromBusinessId == to.Id && c.ToBusinessId == from.Id),
                cancellationToken);

        if (existing != null)
        {
            return existing.Status switch
            {
                ConnectionStatus.Accepted => Result<BusinessConnectionDto>.Conflict("Already connected with this business"),
                ConnectionStatus.Pending => Result<BusinessConnectionDto>.Conflict("A connection request is already pending"),
                ConnectionStatus.Blocked => Result<BusinessConnectionDto>.Failure("Connection is blocked"),
                ConnectionStatus.Rejected or ConnectionStatus.Inactive => await ReopenRequest(existing, from, to, connectionType.Value, request.Notes, cancellationToken),
                _ => Result<BusinessConnectionDto>.Conflict("Connection already exists")
            };
        }

        var connection = new BusinessConnection
        {
            FromBusinessId = from.Id,
            ToBusinessId = to.Id,
            ConnectionType = connectionType.Value,
            Status = ConnectionStatus.Pending,
            RequestedByUserId = _currentUser.UserId.Value,
            Notes = request.Notes
        };

        _context.BusinessConnections.Add(connection);
        await _context.SaveChangesAsync(cancellationToken);
        await NotifyRequestRecipientAsync(from, to, cancellationToken);

        return Result<BusinessConnectionDto>.Created(Map(connection, from, to, isIncoming: false));
    }

    private async Task<Result<BusinessConnectionDto>> ReopenRequest(
        BusinessConnection existing,
        Tenant from,
        Tenant to,
        ConnectionType type,
        string? notes,
        CancellationToken cancellationToken)
    {
        existing.FromBusinessId = from.Id;
        existing.ToBusinessId = to.Id;
        existing.ConnectionType = type;
        existing.Status = ConnectionStatus.Pending;
        existing.RequestedByUserId = _currentUser.UserId!.Value;
        existing.Notes = notes;
        existing.AcceptedAt = null;
        existing.RejectedAt = null;
        await _context.SaveChangesAsync(cancellationToken);
        await NotifyRequestRecipientAsync(from, to, cancellationToken);
        return Result<BusinessConnectionDto>.Success(Map(existing, from, to, isIncoming: false));
    }

    private async Task NotifyRequestRecipientAsync(Tenant from, Tenant to, CancellationToken cancellationToken)
    {
        var recipientIds = await _context.Users
            .Where(u => u.TenantId == to.Id && u.Status == UserStatus.Active)
            .Select(u => u.Id)
            .ToListAsync(cancellationToken);

        foreach (var recipientId in recipientIds)
        {
            await _notifications.CreateAndPushAsync(
                to.Id,
                recipientId,
                null,
                NotificationType.ConnectionRequested,
                "New connection request",
                $"{from.ShopName} wants to connect with your business.",
                cancellationToken);
        }
    }

    private static ConnectionType? ResolveConnectionType(BusinessType from, BusinessType to)
    {
        if ((from == BusinessType.Showroom && to == BusinessType.Shop) ||
            (from == BusinessType.Shop && to == BusinessType.Showroom))
            return ConnectionType.ShowroomShop;

        if ((from == BusinessType.Shop && to == BusinessType.Karigar) ||
            (from == BusinessType.Karigar && to == BusinessType.Shop))
            return ConnectionType.ShopKarigar;

        return null;
    }

    private static BusinessConnectionDto Map(BusinessConnection c, Tenant from, Tenant to, bool isIncoming)
    {
        var counterparty = isIncoming ? from : to;
        return new BusinessConnectionDto
        {
            Id = c.Id,
            CounterpartyBusinessId = counterparty.Id,
            CounterpartyName = counterparty.ShopName,
            CounterpartyGoldDeskId = counterparty.GoldDeskId,
            CounterpartyBusinessType = counterparty.BusinessType.ToString(),
            ConnectionType = c.ConnectionType.ToString(),
            Status = c.Status.ToString(),
            IsIncoming = isIncoming,
            CreatedAt = c.CreatedAt,
            AcceptedAt = c.AcceptedAt
        };
    }
}
