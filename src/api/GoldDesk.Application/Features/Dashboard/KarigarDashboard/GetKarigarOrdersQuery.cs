using GoldDesk.Application.Common.Models;
using MediatR;

namespace GoldDesk.Application.Features.Dashboard.KarigarDashboard;

public record GetKarigarOrdersQuery : IRequest<Result<PagedResult<KarigarOrderDto>>>
{
    public string? Status { get; init; }
    public int Page { get; init; } = 1;
    public int PageSize { get; init; } = 20;
}
