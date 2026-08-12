using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.ShopProfile.Dtos;
using MediatR;

namespace GoldDesk.Application.Features.ShopProfile.UpdateTenantProfile;

public record UpdateTenantProfileCommand : IRequest<Result<TenantProfileDto>>
{
    public string ShopName { get; init; } = string.Empty;
    public string OwnerName { get; init; } = string.Empty;
    public string Mobile { get; init; } = string.Empty;
    public string? Address { get; init; }
    public string? GstNumber { get; init; }
}
