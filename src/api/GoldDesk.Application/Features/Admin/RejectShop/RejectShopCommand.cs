using GoldDesk.Application.Common.Models;
using MediatR;

namespace GoldDesk.Application.Features.Admin.RejectShop;

public record RejectShopCommand : IRequest<Result<RejectShopResponse>>
{
    public Guid TenantId { get; init; }
    public string Reason { get; init; } = string.Empty;
}

public record RejectShopResponse
{
    public Guid TenantId { get; init; }
    public string Message { get; init; } = string.Empty;
}
