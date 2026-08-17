using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Domain.Entities;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Orders.Comments;

public record AddOrderCommentCommand : IRequest<Result<OrderCommentDto>>
{
    public Guid OrderId { get; init; }
    public OrderCommentChannel Channel { get; init; }
    public string Message { get; init; } = string.Empty;
}

public record GetOrderCommentsQuery(Guid OrderId, OrderCommentChannel Channel)
    : IRequest<Result<List<OrderCommentDto>>>;

public record OrderCommentDto
{
    public Guid Id { get; init; }
    public string AuthorBusinessName { get; init; } = string.Empty;
    public string Channel { get; init; } = string.Empty;
    public string Message { get; init; } = string.Empty;
    public DateTime CreatedAt { get; init; }
}

public class AddOrderCommentCommandHandler
    : IRequestHandler<AddOrderCommentCommand, Result<OrderCommentDto>>
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;
    private readonly INotificationService _notificationService;

    public AddOrderCommentCommandHandler(
        IApplicationDbContext context,
        ICurrentUserService currentUser,
        INotificationService notificationService)
    {
        _context = context;
        _currentUser = currentUser;
        _notificationService = notificationService;
    }

    public async Task<Result<OrderCommentDto>> Handle(AddOrderCommentCommand request, CancellationToken cancellationToken)
    {
        if (!_currentUser.TenantId.HasValue || !_currentUser.UserId.HasValue)
            return Result<OrderCommentDto>.Unauthorized();
        if (string.IsNullOrWhiteSpace(request.Message))
            return Result<OrderCommentDto>.Failure("Comment message is required.");

        var order = await _context.Orders
            .IgnoreQueryFilters()
            .FirstOrDefaultAsync(o => o.Id == request.OrderId, cancellationToken);
        if (order == null) return Result<OrderCommentDto>.NotFound("Order not found.");

        var canUseChannel = await OrderCommentAccess.CanAccessAsync(
            _context, _currentUser, order, request.Channel, cancellationToken);
        if (!canUseChannel) return Result<OrderCommentDto>.Forbidden("You cannot access this order conversation.");

        var author = await _context.Tenants
            .AsNoTracking()
            .FirstAsync(t => t.Id == _currentUser.TenantId.Value, cancellationToken);
        var comment = new OrderComment
        {
            OrderId = order.Id,
            AuthorBusinessId = _currentUser.TenantId.Value,
            AuthorUserId = _currentUser.UserId.Value,
            Channel = request.Channel,
            Message = request.Message.Trim()
        };
        _context.OrderComments.Add(comment);
        await _context.SaveChangesAsync(cancellationToken);
        await NotifyOtherParticipantsAsync(order, request.Channel, cancellationToken);
        return Result<OrderCommentDto>.Created(OrderCommentAccess.ToDto(comment, author.ShopName));
    }

    private async Task NotifyOtherParticipantsAsync(
        Order order,
        OrderCommentChannel channel,
        CancellationToken cancellationToken)
    {
        var authorBusinessId = _currentUser.TenantId!.Value;
        var recipients = new List<(Guid TenantId, Guid UserId)>();

        if (channel == OrderCommentChannel.ShowroomShop)
        {
            Guid? otherBusinessId = null;
            if (authorBusinessId == order.TenantId && order.OrderFromBusinessId.HasValue)
                otherBusinessId = order.OrderFromBusinessId.Value;
            else if (order.OrderFromBusinessId == authorBusinessId)
                otherBusinessId = order.TenantId;

            if (otherBusinessId.HasValue)
            {
                var users = await _context.Users
                    .IgnoreQueryFilters()
                    .Where(u => u.TenantId == otherBusinessId.Value &&
                                u.Status == UserStatus.Active &&
                                u.Id != _currentUser.UserId)
                    .Select(u => u.Id)
                    .ToListAsync(cancellationToken);
                recipients.AddRange(users.Select(userId => (otherBusinessId.Value, userId)));
            }
        }
        else if (channel == OrderCommentChannel.ShopKarigar)
        {
            if (authorBusinessId == order.TenantId)
            {
                var assignees = await _context.OrderAssignments
                    .IgnoreQueryFilters()
                    .Include(a => a.Karigar)
                    .Where(a => a.OrderId == order.Id &&
                                a.IsActive &&
                                a.Karigar.UserId.HasValue)
                    .Select(a => new { a.Karigar.TenantId, UserId = a.Karigar.UserId!.Value })
                    .ToListAsync(cancellationToken);
                recipients.AddRange(assignees.Select(a => (a.TenantId, a.UserId)));
            }
            else
            {
                var shopUsers = await _context.Users
                    .IgnoreQueryFilters()
                    .Where(u => u.TenantId == order.TenantId &&
                                u.Status == UserStatus.Active &&
                                u.Id != _currentUser.UserId)
                    .Select(u => u.Id)
                    .ToListAsync(cancellationToken);
                recipients.AddRange(shopUsers.Select(userId => (order.TenantId, userId)));
            }
        }

        foreach (var recipient in recipients.Distinct())
        {
            await _notificationService.CreateAndPushAsync(
                recipient.TenantId,
                recipient.UserId,
                order.Id,
                NotificationType.CommentAdded,
                $"New message on order {order.OrderNo}",
                "Open the order conversation to read the new message.",
                cancellationToken);
        }
    }
}

public class GetOrderCommentsQueryHandler
    : IRequestHandler<GetOrderCommentsQuery, Result<List<OrderCommentDto>>>
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;
    public GetOrderCommentsQueryHandler(IApplicationDbContext context, ICurrentUserService currentUser)
    {
        _context = context;
        _currentUser = currentUser;
    }

    public async Task<Result<List<OrderCommentDto>>> Handle(GetOrderCommentsQuery request, CancellationToken cancellationToken)
    {
        if (!_currentUser.TenantId.HasValue)
            return Result<List<OrderCommentDto>>.Unauthorized();

        var order = await _context.Orders.IgnoreQueryFilters()
            .FirstOrDefaultAsync(o => o.Id == request.OrderId, cancellationToken);
        if (order == null) return Result<List<OrderCommentDto>>.NotFound("Order not found.");
        if (!await OrderCommentAccess.CanAccessAsync(_context, _currentUser, order, request.Channel, cancellationToken))
            return Result<List<OrderCommentDto>>.Forbidden("You cannot access this order conversation.");

        var comments = await _context.OrderComments
            .AsNoTracking()
            .Where(c => c.OrderId == request.OrderId && c.Channel == request.Channel)
            .OrderBy(c => c.CreatedAt)
            .Select(c => new OrderCommentDto
            {
                Id = c.Id,
                AuthorBusinessName = c.AuthorBusiness.ShopName,
                Channel = c.Channel.ToString(),
                Message = c.Message,
                CreatedAt = c.CreatedAt
            }).ToListAsync(cancellationToken);
        return Result<List<OrderCommentDto>>.Success(comments);
    }
}

internal static class OrderCommentAccess
{
    public static async Task<bool> CanAccessAsync(
        IApplicationDbContext context, ICurrentUserService user, Order order,
        OrderCommentChannel channel, CancellationToken cancellationToken)
    {
        if (!user.TenantId.HasValue) return false;
        var businessId = user.TenantId.Value;
        if (channel == OrderCommentChannel.ShowroomShop)
            return businessId == order.TenantId || businessId == order.OrderFromBusinessId;

        if (businessId == order.TenantId) return true;
        return user.UserId.HasValue && await context.OrderAssignments
            .IgnoreQueryFilters()
            .AnyAsync(a => a.OrderId == order.Id && a.IsActive &&
                           a.Karigar.UserId == user.UserId.Value, cancellationToken);
    }

    public static OrderCommentDto ToDto(OrderComment comment, string authorBusinessName) => new()
    {
        Id = comment.Id,
        AuthorBusinessName = authorBusinessName,
        Channel = comment.Channel.ToString(),
        Message = comment.Message,
        CreatedAt = comment.CreatedAt
    };
}
