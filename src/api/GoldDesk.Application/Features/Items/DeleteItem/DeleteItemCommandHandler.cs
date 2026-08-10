using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Items.DeleteItem;

public class DeleteItemCommandHandler : IRequestHandler<DeleteItemCommand, Result<bool>>
{
    private readonly IApplicationDbContext _context;

    public DeleteItemCommandHandler(IApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<Result<bool>> Handle(DeleteItemCommand request, CancellationToken cancellationToken)
    {
        var item = await _context.Items
            .FirstOrDefaultAsync(i => i.Id == request.Id, cancellationToken);

        if (item == null)
            return Result<bool>.NotFound("Item not found");

        item.IsActive = false;
        await _context.SaveChangesAsync(cancellationToken);

        return Result<bool>.Success(true);
    }
}
