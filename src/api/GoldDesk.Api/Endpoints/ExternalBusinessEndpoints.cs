using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.ExternalBusinesses;
using MediatR;

namespace GoldDesk.Api.Endpoints;

public static class ExternalBusinessEndpoints
{
    public static void MapExternalBusinessEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/external-businesses")
            .WithTags("External Businesses")
            .RequireAuthorization();

        group.MapGet("/", async (IMediator mediator) =>
        {
            var result = await mediator.Send(new GetExternalBusinessesQuery());
            return ToResponse(result);
        })
        .WithName("GetExternalBusinesses");

        group.MapPost("/", async (CreateExternalBusinessCommand command, IMediator mediator) =>
        {
            if (string.IsNullOrWhiteSpace(command.Name))
                return Results.BadRequest(new { error = "Business name is required." });
            if (string.IsNullOrWhiteSpace(command.CustomerCode))
                return Results.BadRequest(new { error = "Customer code is required." });

            var result = await mediator.Send(command);
            return result.IsSuccess
                ? Results.Created($"/api/external-businesses/{result.Data!.Id}", result.Data)
                : result.StatusCode == 409
                    ? Results.Conflict(new { error = result.Error })
                    : ToResponse(result);
        })
        .WithName("CreateExternalBusiness");

        group.MapPut("/{id:guid}", async (
            Guid id,
            UpdateExternalBusinessRequest request,
            IMediator mediator) =>
        {
            if (string.IsNullOrWhiteSpace(request.Name))
                return Results.BadRequest(new { error = "Business name is required." });
            if (string.IsNullOrWhiteSpace(request.CustomerCode))
                return Results.BadRequest(new { error = "Customer code is required." });

            var result = await mediator.Send(new UpdateExternalBusinessCommand
            {
                Id = id,
                CustomerCode = request.CustomerCode,
                Name = request.Name,
                ContactPerson = request.ContactPerson,
                Mobile = request.Mobile,
                Email = request.Email,
                Address = request.Address
            });
            return result.StatusCode == 409
                ? Results.Conflict(new { error = result.Error })
                : ToResponse(result);
        })
        .WithName("UpdateExternalBusiness");

        group.MapPost("/{id:guid}/link", async (
            Guid id,
            LinkExternalBusinessRequest request,
            IMediator mediator) =>
        {
            var result = await mediator.Send(new LinkExternalBusinessCommand
            {
                ExternalBusinessId = id,
                GoldDeskId = request.GoldDeskId
            });
            return ToResponse(result);
        })
        .WithName("LinkExternalBusiness");
    }

    private static IResult ToResponse<T>(Result<T> result) => result.StatusCode switch
    {
        200 when result.IsSuccess => Results.Ok(result.Data),
        401 => Results.Unauthorized(),
        404 => Results.NotFound(new { error = result.Error }),
        _ => Results.BadRequest(new { error = result.Error })
    };
}

public record UpdateExternalBusinessRequest
{
    public string CustomerCode { get; init; } = string.Empty;
    public string Name { get; init; } = string.Empty;
    public string? ContactPerson { get; init; }
    public string? Mobile { get; init; }
    public string? Email { get; init; }
    public string? Address { get; init; }
}

public record LinkExternalBusinessRequest
{
    public string GoldDeskId { get; init; } = string.Empty;
}
