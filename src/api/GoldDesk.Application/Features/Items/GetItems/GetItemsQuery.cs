using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Items.Dtos;
using MediatR;

namespace GoldDesk.Application.Features.Items.GetItems;

public record GetItemsQuery : IRequest<Result<PagedResult<ItemDto>>>
{
    public string? Search { get; init; }
    public string? Category { get; init; }
    public int Page { get; init; } = 1;
    public int PageSize { get; init; } = 20;
}
