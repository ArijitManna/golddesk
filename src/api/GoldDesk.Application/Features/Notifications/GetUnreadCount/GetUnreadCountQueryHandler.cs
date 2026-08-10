using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Notifications.GetUnreadCount;

public class GetUnreadCountQueryHandler : IRequestHandler<GetUnreadCountQuery, Result<int>>
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;

    public GetUnreadCountQueryHandler(IApplicationDbContext context, ICurrentUserService currentUser)
    {
        _context = context;
        _currentUser = currentUser;
    }

    public async Task<Result<int>> Handle(GetUnreadCountQuery request, CancellationToken cancellationToken)
    {
        var count = await _context.Notifications
            .CountAsync(n => n.UserId == _currentUser.UserId && !n.IsRead, cancellationToken);

        return Result<int>.Success(count);
    }
}
