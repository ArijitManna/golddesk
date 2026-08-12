using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Items.Dtos;
using GoldDesk.Domain.Entities;
using MediatR;
using Microsoft.EntityFrameworkCore;

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
        // Check unique item code
        var codeExists = await _context.Items
            .AnyAsync(i => i.ItemCode == request.ItemCode, cancellationToken);

        if (codeExists)
            return Result<ItemDto>.Conflict($"Item code '{request.ItemCode}' already exists");

        var item = new ItemMaster
        {
            ItemCode = request.ItemCode,
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
            ItemCode = item.ItemCode,
            Name = item.Name,
            Category = item.Category,
            Purity = item.Purity,
            DefaultRate = item.DefaultRate,
            DefaultMakingCharge = item.DefaultMakingCharge,
            ImagePath = item.ImagePath,
            IsActive = item.IsActive,
            CreatedAt = item.CreatedAt
        });
    }
}
