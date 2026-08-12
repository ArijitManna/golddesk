using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Api.Endpoints;

public static class FileEndpoints
{
    public static void MapFileEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/files")
            .WithTags("Files")
            .RequireAuthorization();

        // Upload image for an order item
        group.MapPost("/upload/order-item/{orderItemId:guid}", async (
            Guid orderItemId,
            IFormFile file,
            IApplicationDbContext context,
            IWebHostEnvironment env) =>
        {
            if (file.Length == 0)
                return Results.BadRequest(new { error = "No file uploaded" });

            if (file.Length > 5 * 1024 * 1024) // 5MB max
                return Results.BadRequest(new { error = "File size exceeds 5MB limit" });

            var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".webp" };
            var ext = Path.GetExtension(file.FileName).ToLower();
            if (!allowedExtensions.Contains(ext))
                return Results.BadRequest(new { error = "Only jpg, png, webp images are allowed" });

            // Find the order item
            var orderItem = await context.OrderItems
                .IgnoreQueryFilters()
                .FirstOrDefaultAsync(oi => oi.Id == orderItemId);

            if (orderItem == null)
                return Results.NotFound(new { error = "Order item not found" });

            // Create uploads directory
            var uploadsFolder = Path.Combine(env.ContentRootPath, "uploads", "order-items");
            Directory.CreateDirectory(uploadsFolder);

            // Generate unique filename
            var fileName = $"{orderItemId}_{DateTime.UtcNow:yyyyMMddHHmmss}{ext}";
            var filePath = Path.Combine(uploadsFolder, fileName);

            // Delete old file if exists
            if (!string.IsNullOrEmpty(orderItem.ImagePath))
            {
                var oldPath = Path.Combine(env.ContentRootPath, orderItem.ImagePath.TrimStart('/'));
                if (File.Exists(oldPath)) File.Delete(oldPath);
            }

            // Save file
            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await file.CopyToAsync(stream);
            }

            // Update DB with relative path
            var relativePath = $"/uploads/order-items/{fileName}";
            orderItem.ImagePath = relativePath;
            await context.SaveChangesAsync();

            return Results.Ok(new { imagePath = relativePath });
        })
        .DisableAntiforgery()
        .WithName("UploadOrderItemImage")
        .WithDescription("Upload an image for an order item");

        // General image upload (returns path, can be attached later)
        group.MapPost("/upload/item/{itemId:guid}", async (
            Guid itemId,
            IFormFile file,
            IApplicationDbContext context,
            IWebHostEnvironment env) =>
        {
            if (file.Length == 0)
                return Results.BadRequest(new { error = "No file uploaded" });

            if (file.Length > 5 * 1024 * 1024)
                return Results.BadRequest(new { error = "File size exceeds 5MB limit" });

            var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".webp" };
            var ext = Path.GetExtension(file.FileName).ToLower();
            if (!allowedExtensions.Contains(ext))
                return Results.BadRequest(new { error = "Only jpg, png, webp images are allowed" });

            var item = await context.Items.FindAsync(new object[] { itemId });
            if (item == null)
                return Results.NotFound(new { error = "Item not found" });

            var uploadsFolder = Path.Combine(env.ContentRootPath, "uploads", "items");
            Directory.CreateDirectory(uploadsFolder);

            var fileName = $"{itemId}_{DateTime.UtcNow:yyyyMMddHHmmss}{ext}";
            var filePath = Path.Combine(uploadsFolder, fileName);

            if (!string.IsNullOrEmpty(item.ImagePath))
            {
                var oldPath = Path.Combine(env.ContentRootPath, item.ImagePath.TrimStart('/'));
                if (File.Exists(oldPath)) File.Delete(oldPath);
            }

            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await file.CopyToAsync(stream);
            }

            var relativePath = $"/uploads/items/{fileName}";
            item.ImagePath = relativePath;
            await context.SaveChangesAsync();

            return Results.Ok(new { imagePath = relativePath });
        })
        .DisableAntiforgery()
        .WithName("UploadItemImage")
        .WithDescription("Upload an image for an item master");

        // General image upload (returns path, can be attached later)
        group.MapPost("/upload", async (
            IFormFile file,
            IWebHostEnvironment env) =>
        {
            if (file.Length == 0)
                return Results.BadRequest(new { error = "No file uploaded" });

            if (file.Length > 5 * 1024 * 1024)
                return Results.BadRequest(new { error = "File size exceeds 5MB limit" });

            var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".webp" };
            var ext = Path.GetExtension(file.FileName).ToLower();
            if (!allowedExtensions.Contains(ext))
                return Results.BadRequest(new { error = "Only jpg, png, webp images are allowed" });

            var uploadsFolder = Path.Combine(env.ContentRootPath, "uploads", "images");
            Directory.CreateDirectory(uploadsFolder);

            var fileName = $"{Guid.NewGuid()}{ext}";
            var filePath = Path.Combine(uploadsFolder, fileName);

            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await file.CopyToAsync(stream);
            }

            var relativePath = $"/uploads/images/{fileName}";
            return Results.Ok(new { imagePath = relativePath });
        })
        .DisableAntiforgery()
        .WithName("UploadImage")
        .WithDescription("Upload a general image file");

        group.MapPost("/upload/tenant-logo", async (
            IFormFile file,
            IApplicationDbContext context,
            ICurrentUserService currentUser,
            IWebHostEnvironment env) =>
        {
            if (currentUser.Role != UserRole.ShopOwner || !currentUser.TenantId.HasValue)
                return Results.Json(new { error = "Only shop owners can upload shop logo" }, statusCode: 403);

            if (file.Length == 0)
                return Results.BadRequest(new { error = "No file uploaded" });

            if (file.Length > 5 * 1024 * 1024)
                return Results.BadRequest(new { error = "File size exceeds 5MB limit" });

            var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".webp" };
            var ext = Path.GetExtension(file.FileName).ToLower();
            if (!allowedExtensions.Contains(ext))
                return Results.BadRequest(new { error = "Only jpg, png, webp images are allowed" });

            var tenant = await context.Tenants.FindAsync(new object[] { currentUser.TenantId.Value });
            if (tenant == null)
                return Results.NotFound(new { error = "Shop profile not found" });

            var uploadsFolder = Path.Combine(env.ContentRootPath, "uploads", "logos");
            Directory.CreateDirectory(uploadsFolder);

            var fileName = $"{tenant.Id}_{DateTime.UtcNow:yyyyMMddHHmmss}{ext}";
            var filePath = Path.Combine(uploadsFolder, fileName);

            if (!string.IsNullOrEmpty(tenant.LogoPath))
            {
                var oldPath = Path.Combine(env.ContentRootPath, tenant.LogoPath.TrimStart('/'));
                if (File.Exists(oldPath)) File.Delete(oldPath);
            }

            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await file.CopyToAsync(stream);
            }

            var relativePath = $"/uploads/logos/{fileName}";
            tenant.LogoPath = relativePath;
            await context.SaveChangesAsync();

            return Results.Ok(new { logoPath = relativePath });
        })
        .DisableAntiforgery()
        .RequireAuthorization(policy => policy.RequireRole("ShopOwner"))
        .WithName("UploadTenantLogo")
        .WithDescription("Upload company logo for receipts");
    }
}
