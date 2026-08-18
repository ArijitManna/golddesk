using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Karigars.GetKarigars;
using MediatR;

namespace GoldDesk.Api.Endpoints;

public static class KarigarEndpoints
{
    public static void MapKarigarEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/karigars")
            .WithTags("Karigars")
            .RequireAuthorization();

        group.MapGet("/", async (string? search, bool? activeOnly, int? page, int? pageSize, IMediator mediator) =>
        {
            var result = await mediator.Send(new GetKarigarsQuery
            {
                Search = search,
                ActiveOnly = activeOnly ?? true,
                Page = page ?? 1,
                PageSize = pageSize ?? 20
            });
            return ToResponse(result);
        })
        .WithName("GetKarigars")
        .WithDescription("List Karigars connected to this Shop");
    }

    private static IResult ToResponse<T>(Result<T> result)
    {
        if (result.IsSuccess) return Results.Ok(result.Data);
        return result.StatusCode switch
        {
            403 => Results.Json(new { error = result.Error }, statusCode: 403),
            404 => Results.NotFound(new { error = result.Error }),
            _ => Results.BadRequest(new { error = result.Error })
        };
    }
}
