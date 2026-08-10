using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Items.Dtos;
using GoldDesk.Domain.Entities;
using MediatR;

namespace GoldDesk.Application.Features.Items.CreateItem;

public class CreateItemCommandHandler : IRequestHandler<CreateItemCommand, Result<ItemDto>>
{
    private readonly IApplicationDbContext _context;

    public CreateItemCommandHandler(IApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<Result<ItemDto>> Handle(CreateItemCommand request, CancellationToken cancellationToken)
    {
        var item = new ItemMaster
        {
            Name = request.Name,
            Category = request.Category,
            Purity = request.Purity,
            DefaultRate = request.DefaultRate,
            DefaultMakingCharge = request.DefaultMakingCharge,
            IsActive = true
        };

        _context.Items.Add(item);
        await _context.SaveChangesAsync(cancellationToken);

        return Result<ItemDto>.Created(new ItemDto
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
