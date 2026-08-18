using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Karigars.Dtos;
using MediatR;

namespace GoldDesk.Application.Features.Karigars.CreateKarigar;

public class CreateKarigarCommandHandler : IRequestHandler<CreateKarigarCommand, Result<KarigarDto>>
{
    public Task<Result<KarigarDto>> Handle(CreateKarigarCommand request, CancellationToken cancellationToken)
    {
        return Task.FromResult(Result<KarigarDto>.Forbidden(
            "Shops cannot create Karigars. Connect a Karigar business from Connections."));
    }
}
