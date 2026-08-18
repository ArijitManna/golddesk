using GoldDesk.Application.Common.Models;
using MediatR;

namespace GoldDesk.Application.Features.Dashboard.KarigarDashboard;

public record GetKarigarOrdersQuery : IRequest<Result<PagedResult<KarigarOrderDto>>>
{
    public string? Status { get; init; }
    public string? AssignmentStatus { get; init; }
    /// <summary>Due filter: today | overdue | next3</summary>
    public string? Due { get; init; }
    public int Page { get; init; } = 1;
    public int PageSize { get; init; } = 20;
}
