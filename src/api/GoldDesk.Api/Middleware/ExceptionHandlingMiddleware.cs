using System.Net;
using System.Text.Json;
using FluentValidation;

namespace GoldDesk.Api.Middleware;

public class ExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionHandlingMiddleware> _logger;

    public ExceptionHandlingMiddleware(RequestDelegate next, ILogger<ExceptionHandlingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (ValidationException ex)
        {
            _logger.LogWarning(ex, "Validation error occurred");
            context.Response.StatusCode = (int)HttpStatusCode.BadRequest;
            context.Response.ContentType = "application/json";

            var errors = ex.Errors.Select(e => new { field = e.PropertyName, message = e.ErrorMessage });
            var response = new { error = "Validation failed", errors };

            await context.Response.WriteAsync(JsonSerializer.Serialize(response));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "An unhandled exception occurred");
            context.Response.StatusCode = (int)HttpStatusCode.InternalServerError;
            context.Response.ContentType = "application/json";

            var response = context.RequestServices.GetRequiredService<IWebHostEnvironment>().IsDevelopment()
                ? new { error = "Internal server error", detail = ex.Message }
                : new { error = "Internal server error", detail = (string?)null };

            await context.Response.WriteAsync(JsonSerializer.Serialize(response));
        }
    }
}
