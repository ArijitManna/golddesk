using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Karigars.Dtos;
using MediatR;

namespace GoldDesk.Application.Features.Karigars.GetKarigars;

public record GetKarigarsQuery : IRequest<Result<PagedResult<KarigarDto>>>
{
    public string? Search { get; init; }
    public bool? ActiveOnly { get; init; } = true;
    public int Page { get; init; } = 1;
    public int PageSize { get; init; } = 20;
}
