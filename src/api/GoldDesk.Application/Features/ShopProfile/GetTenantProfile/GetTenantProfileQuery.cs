using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.ShopProfile.Dtos;
using MediatR;

namespace GoldDesk.Application.Features.ShopProfile.GetTenantProfile;

public record GetTenantProfileQuery : IRequest<Result<TenantProfileDto>>;
