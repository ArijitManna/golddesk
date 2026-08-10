using GoldDesk.Application.Common.Models;
using MediatR;

namespace GoldDesk.Application.Features.Items.DeleteItem;

public record DeleteItemCommand(Guid Id) : IRequest<Result<bool>>;
