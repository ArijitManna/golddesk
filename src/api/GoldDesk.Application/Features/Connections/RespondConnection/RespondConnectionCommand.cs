using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Connections.Dtos;
using MediatR;

namespace GoldDesk.Application.Features.Connections.RespondConnection;

public record RespondConnectionCommand : IRequest<Result<BusinessConnectionDto>>
{
    public Guid ConnectionId { get; init; }
    public bool Accept { get; init; }
}
