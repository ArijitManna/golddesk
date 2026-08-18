using GoldDesk.Application.Common.Models;
using MediatR;

namespace GoldDesk.Application.Features.Karigars.DeactivateKarigar;

public class DeactivateKarigarCommandHandler : IRequestHandler<DeactivateKarigarCommand, Result<bool>>
{
    public Task<Result<bool>> Handle(DeactivateKarigarCommand request, CancellationToken cancellationToken)
    {
        return Task.FromResult(Result<bool>.Forbidden(
            "Shops cannot deactivate Karigars. Manage the connection instead."));
    }
}
