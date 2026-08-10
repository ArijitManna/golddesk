using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Customers.CreateCustomer;
using GoldDesk.Application.Features.Customers.DeleteCustomer;
using GoldDesk.Application.Features.Customers.GetCustomers;
using GoldDesk.Application.Features.Customers.UpdateCustomer;
using MediatR;

namespace GoldDesk.Api.Endpoints;

public static class CustomerEndpoints
{
    public static void MapCustomerEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/customers")
            .WithTags("Customers")
            .RequireAuthorization();

        group.MapGet("/", async (string? search, int? page, int? pageSize, IMediator mediator) =>
        {
            var result = await mediator.Send(new GetCustomersQuery
            {
                Search = search,
                Page = page ?? 1,
                PageSize = pageSize ?? 20
            });
            return ToResponse(result);
        })
        .WithName("GetCustomers");

        group.MapPost("/", async (CreateCustomerCommand command, IMediator mediator) =>
        {
            var result = await mediator.Send(command);
            return result.IsSuccess
                ? Results.Created($"/api/customers/{result.Data!.Id}", result.Data)
                : ToBadRequest(result);
        })
        .WithName("CreateCustomer");

        group.MapPut("/{id:guid}", async (Guid id, UpdateCustomerRequest request, IMediator mediator) =>
        {
            var result = await mediator.Send(new UpdateCustomerCommand
            {
                Id = id,
                Name = request.Name,
                Mobile = request.Mobile,
                Email = request.Email,
                Address = request.Address,
                Notes = request.Notes
            });
            return ToResponse(result);
        })
        .WithName("UpdateCustomer");

        group.MapDelete("/{id:guid}", async (Guid id, IMediator mediator) =>
        {
            var result = await mediator.Send(new DeleteCustomerCommand(id));
            return result.IsSuccess ? Results.NoContent() : Results.NotFound(new { error = result.Error });
        })
        .WithName("DeleteCustomer");
    }

    private static IResult ToResponse<T>(Result<T> result)
    {
        if (result.IsSuccess) return Results.Ok(result.Data);
        return result.StatusCode switch
        {
            404 => Results.NotFound(new { error = result.Error }),
            _ => Results.BadRequest(new { error = result.Error })
        };
    }

    private static IResult ToBadRequest<T>(Result<T> result) =>
        Results.BadRequest(new { error = result.Error });
}

public record UpdateCustomerRequest
{
    public string Name { get; init; } = string.Empty;
    public string? Mobile { get; init; }
    public string? Email { get; init; }
    public string? Address { get; init; }
    public string? Notes { get; init; }
}
