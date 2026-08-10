using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Items.Dtos;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Items.GetItems;

public class GetItemsQueryHandler : IRequestHandler<GetItemsQuery, Result<PagedResult<ItemDto>>>
{
    private readonly IApplicationDbContext _context;

    public GetItemsQueryHandler(IApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<Result<PagedResult<ItemDto>>> Handle(GetItemsQuery request, CancellationToken cancellationToken)
    {
        var query = _context.Items.Where(i => i.IsActive);

        if (!string.IsNullOrWhiteSpace(request.Search))
        {
            var search = request.Search.ToLower();
            query = query.Where(i => i.Name.ToLower().Contains(search));
        }

        if (!string.IsNullOrWhiteSpace(request.Category))
        {
            query = query.Where(i => i.Category == request.Category);
        }

        var totalCount = await query.CountAsync(cancellationToken);

        var items = await query
            .OrderBy(i => i.Name)
            .Skip((request.Page - 1) * request.PageSize)
            .Take(request.PageSize)
            .Select(i => new ItemDto
            {
                Id = i.Id,
                Name = i.Name,
                Category = i.Category,
                Purity = i.Purity,
                DefaultRate = i.DefaultRate,
                DefaultMakingCharge = i.DefaultMakingCharge,
                IsActive = i.IsActive,
                CreatedAt = i.CreatedAt
            })
            .ToListAsync(cancellationToken);

        return Result<PagedResult<ItemDto>>.Success(
            new PagedResult<ItemDto>(items, totalCount, request.Page, request.PageSize));
    }
}
