using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Karigars.Dtos;
using MediatR;

namespace GoldDesk.Application.Features.Karigars.CreateKarigar;

public record CreateKarigarCommand : IRequest<Result<KarigarDto>>
{
    public string Name { get; init; } = string.Empty;
    public string Mobile { get; init; } = string.Empty;
    public string? Email { get; init; }
    public string? Address { get; init; }
    public string? Specialization { get; init; }
    public bool CreateLogin { get; init; }
    public string? Password { get; init; }
}
