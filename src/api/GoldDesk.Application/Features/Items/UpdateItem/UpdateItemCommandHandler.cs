using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Items.Dtos;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Items.UpdateItem;

public class UpdateItemCommandHandler : IRequestHandler<UpdateItemCommand, Result<ItemDto>>
{
    private readonly IApplicationDbContext _context;

    public UpdateItemCommandHandler(IApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<Result<ItemDto>> Handle(UpdateItemCommand request, CancellationToken cancellationToken)
    {
        var item = await _context.Items
            .FirstOrDefaultAsync(i => i.Id == request.Id, cancellationToken);

        if (item == null)
            return Result<ItemDto>.NotFound("Item not found");

        item.Name = request.Name;
        item.Category = request.Category;
        item.Purity = request.Purity;
        item.DefaultRate = request.DefaultRate;
        item.DefaultMakingCharge = request.DefaultMakingCharge;

        await _context.SaveChangesAsync(cancellationToken);

        return Result<ItemDto>.Success(new ItemDto
        {
            Id = item.Id,
            Name = item.Name,
            Category = item.Category,
            Purity = item.Purity,
            DefaultRate = item.DefaultRate,
            DefaultMakingCharge = item.DefaultMakingCharge,
            IsActive = item.IsActive,
            CreatedAt = item.CreatedAt
        });
    }
}
