using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Connections.Dtos;
using MediatR;

namespace GoldDesk.Application.Features.Connections.SearchBusiness;

public record SearchBusinessQuery : IRequest<Result<BusinessSummaryDto>>
{
    public string GoldDeskId { get; init; } = string.Empty;
}
