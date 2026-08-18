using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Karigars.Dtos;
using MediatR;

namespace GoldDesk.Application.Features.Karigars.UpdateKarigar;

public class UpdateKarigarCommandHandler : IRequestHandler<UpdateKarigarCommand, Result<KarigarDto>>
{
    public Task<Result<KarigarDto>> Handle(UpdateKarigarCommand request, CancellationToken cancellationToken)
    {
        return Task.FromResult(Result<KarigarDto>.Forbidden(
            "Shops cannot edit Karigars. Manage the connection instead."));
    }
}
