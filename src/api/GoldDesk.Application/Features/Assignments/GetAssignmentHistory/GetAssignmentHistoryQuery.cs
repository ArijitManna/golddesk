using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Orders.Dtos;
using MediatR;

namespace GoldDesk.Application.Features.Assignments.GetAssignmentHistory;

public record GetAssignmentHistoryQuery(Guid OrderId) : IRequest<Result<List<AssignmentDto>>>;
