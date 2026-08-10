using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Orders.Dtos;
using MediatR;

namespace GoldDesk.Application.Features.Orders.GetOrderById;

public record GetOrderByIdQuery(Guid Id) : IRequest<Result<OrderDetailDto>>;
