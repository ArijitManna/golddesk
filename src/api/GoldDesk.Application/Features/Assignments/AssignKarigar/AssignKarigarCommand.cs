using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Orders.Dtos;
using MediatR;

namespace GoldDesk.Application.Features.Assignments.AssignKarigar;

public record AssignKarigarCommand : IRequest<Result<AssignmentDto>>
{
    public Guid OrderId { get; init; }
    public Guid KarigarId { get; init; }
    public string GivenDate { get; init; } = string.Empty;
    public string DueDate { get; init; } = string.Empty;
    public string? Notes { get; init; }
}
