using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Connections.Dtos;
using MediatR;

namespace GoldDesk.Application.Features.Connections.GetConnections;

public record GetConnectionsQuery : IRequest<Result<List<BusinessConnectionDto>>>
{
    /// <summary>Optional filter: Pending, Accepted, etc.</summary>
    public string? Status { get; init; }
    /// <summary>Optional filter: ShowroomShop, ShopKarigar</summary>
    public string? ConnectionType { get; init; }
}
