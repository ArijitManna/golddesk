using System.Text;
using System.Text.Json.Serialization;
using GoldDesk.Api.Endpoints;
using GoldDesk.Api.Services;
using GoldDesk.Application;
using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Infrastructure;
using GoldDesk.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.FileProviders;
using Microsoft.IdentityModel.Tokens;
using Scalar.AspNetCore;
using Serilog;

var builder = WebApplication.CreateBuilder(args);

// Configure Serilog
Log.Logger = new LoggerConfiguration()
    .ReadFrom.Configuration(builder.Configuration)
    .Enrich.FromLogContext()
    .WriteTo.Console()
    .WriteTo.File("logs/golddesk-.log", rollingInterval: RollingInterval.Day)
    .CreateLogger();

builder.Host.UseSerilog();

// Add services
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<ICurrentUserService, CurrentUserService>();
builder.Services.ConfigureHttpJsonOptions(options =>
{
    options.SerializerOptions.Converters.Add(new JsonStringEnumConverter());
});

// Add Application & Infrastructure layers
builder.Services.AddApplication();
builder.Services.AddInfrastructure(builder.Configuration);

// Configure JWT Authentication
var jwtKey = builder.Configuration["Jwt:Key"] ?? throw new InvalidOperationException("JWT Key not configured");
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = builder.Configuration["Jwt:Issuer"],
        ValidAudience = builder.Configuration["Jwt:Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
        ClockSkew = TimeSpan.Zero
    };
});

builder.Services.AddAuthorization();

// CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

// OpenAPI
builder.Services.AddOpenApi();

// Database Seeder
builder.Services.AddScoped<DatabaseSeeder>();

var app = builder.Build();

// Apply migrations and seed database
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    try
    {
        var context = services.GetRequiredService<ApplicationDbContext>();
        await context.Database.MigrateAsync();
        Log.Information("Database migrations applied successfully");

        var seeder = services.GetRequiredService<DatabaseSeeder>();
        await seeder.SeedAsync();
        Log.Information("Database seeding completed");
    }
    catch (Exception ex)
    {
        Log.Error(ex, "An error occurred while migrating/seeding the database");
    }
}

// Configure middleware pipeline
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference(options =>
    {
        options.WithTitle("GoldDesk API");
        options.WithTheme(ScalarTheme.BluePlanet);
        options.WithDefaultHttpClient(ScalarTarget.CSharp, ScalarClient.HttpClient);
    });
}

app.UseSerilogRequestLogging();
app.UseMiddleware<GoldDesk.Api.Middleware.ExceptionHandlingMiddleware>();
app.UseCors("AllowAll");
app.UseAuthentication();
app.UseAuthorization();

// Health check endpoint
app.MapGet("/api/health", () => Results.Ok(new
{
    Status = "Healthy",
    Service = "GoldDesk API",
    Version = "1.0.0",
    Timestamp = DateTime.UtcNow
}))
.WithName("HealthCheck")
.WithTags("System");

// Feature endpoints
app.MapAuthEndpoints();
app.MapAdminEndpoints();
app.MapTenantEndpoints();
app.MapCustomerEndpoints();
app.MapItemEndpoints();
app.MapKarigarEndpoints();
app.MapTeamUserEndpoints();
app.MapOrderEndpoints();
app.MapConnectionEndpoints();
app.MapExternalBusinessEndpoints();
app.MapDashboardEndpoints();
app.MapNotificationEndpoints();
app.MapFileEndpoints();

// Serve uploaded files as static files
var uploadsPath = Path.Combine(app.Environment.ContentRootPath, "uploads");
Directory.CreateDirectory(uploadsPath);
app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new PhysicalFileProvider(uploadsPath),
    RequestPath = "/uploads"
});

// Root endpoint
app.MapGet("/", () => Results.Ok(new
{
    Application = "GoldDesk API",
    Description = "Gold Shop Order Management - Digital Partner for Gold Shop",
    Version = "1.0.0",
    Docs = "/scalar/v1"
}));

app.Run();
