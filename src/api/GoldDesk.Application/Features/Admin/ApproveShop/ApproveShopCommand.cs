using GoldDesk.Application.Common.Models;
using MediatR;

namespace GoldDesk.Application.Features.Admin.ApproveShop;

public record ApproveShopCommand : IRequest<Result<ApproveShopResponse>>
{
    public Guid TenantId { get; init; }
    public string? AdminNote { get; init; }
}

public record ApproveShopResponse
{
    public Guid TenantId { get; init; }
    public string ShopName { get; init; } = string.Empty;
    public string Message { get; init; } = string.Empty;
}
