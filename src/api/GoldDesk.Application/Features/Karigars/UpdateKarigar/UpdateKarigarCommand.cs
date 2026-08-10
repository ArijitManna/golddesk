using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Karigars.Dtos;
using MediatR;

namespace GoldDesk.Application.Features.Karigars.UpdateKarigar;

public record UpdateKarigarCommand : IRequest<Result<KarigarDto>>
{
    public Guid Id { get; init; }
    public string Name { get; init; } = string.Empty;
    public string Mobile { get; init; } = string.Empty;
    public string? Email { get; init; }
    public string? Address { get; init; }
    public string? Specialization { get; init; }
}
