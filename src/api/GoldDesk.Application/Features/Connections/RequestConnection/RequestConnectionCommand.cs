using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Connections.Dtos;
using MediatR;

namespace GoldDesk.Application.Features.Connections.RequestConnection;

public record RequestConnectionCommand : IRequest<Result<BusinessConnectionDto>>
{
    /// <summary>GoldDesk ID of the business to connect with (e.g. GD-SHOP-0001).</summary>
    public string TargetGoldDeskId { get; init; } = string.Empty;
    public string? Notes { get; init; }
}
