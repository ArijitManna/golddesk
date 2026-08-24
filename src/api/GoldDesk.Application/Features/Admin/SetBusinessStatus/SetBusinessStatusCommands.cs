using GoldDesk.Application.Common.Models;
using MediatR;

namespace GoldDesk.Application.Features.Admin.SetBusinessStatus;

public record DeactivateBusinessCommand : IRequest<Result<BusinessStatusResponse>>
{
    public Guid TenantId { get; init; }
}

public record ActivateBusinessCommand : IRequest<Result<BusinessStatusResponse>>
{
    public Guid TenantId { get; init; }
}

public record BusinessStatusResponse
{
    public Guid TenantId { get; init; }
    public string ShopName { get; init; } = string.Empty;
    public string Status { get; init; } = string.Empty;
    public string Message { get; init; } = string.Empty;
}
