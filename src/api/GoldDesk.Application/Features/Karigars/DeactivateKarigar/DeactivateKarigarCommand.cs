using GoldDesk.Application.Common.Models;
using MediatR;

namespace GoldDesk.Application.Features.Karigars.DeactivateKarigar;

public record DeactivateKarigarCommand(Guid Id) : IRequest<Result<bool>>;
