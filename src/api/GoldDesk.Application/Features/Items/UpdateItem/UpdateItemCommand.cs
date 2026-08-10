using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Items.Dtos;
using MediatR;

namespace GoldDesk.Application.Features.Items.UpdateItem;

public record UpdateItemCommand : IRequest<Result<ItemDto>>
{
    public Guid Id { get; init; }
    public string Name { get; init; } = string.Empty;
    public string? Category { get; init; }
    public string? Purity { get; init; }
    public decimal? DefaultRate { get; init; }
    public decimal? DefaultMakingCharge { get; init; }
}
