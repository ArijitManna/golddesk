using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Karigars.DeactivateKarigar;

public class DeactivateKarigarCommandHandler : IRequestHandler<DeactivateKarigarCommand, Result<bool>>
{
    private readonly IApplicationDbContext _context;

    public DeactivateKarigarCommandHandler(IApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<Result<bool>> Handle(DeactivateKarigarCommand request, CancellationToken cancellationToken)
    {
        var karigar = await _context.Karigars
            .FirstOrDefaultAsync(k => k.Id == request.Id, cancellationToken);

        if (karigar == null)
            return Result<bool>.NotFound("Karigar not found");

        karigar.Status = KarigarStatus.Inactive;

        // Also deactivate user login if exists
        if (karigar.UserId.HasValue)
        {
            var user = await _context.Users
                .IgnoreQueryFilters()
                .FirstOrDefaultAsync(u => u.Id == karigar.UserId, cancellationToken);

            if (user != null)
                user.Status = UserStatus.Suspended;
        }

        await _context.SaveChangesAsync(cancellationToken);

        return Result<bool>.Success(true);
    }
}
