namespace GoldDesk.Application.Features.Karigars.Dtos;

public record KarigarDto
{
    public Guid Id { get; init; }
    public string Name { get; init; } = string.Empty;
    public string Mobile { get; init; } = string.Empty;
    public string? Email { get; init; }
    public string? Address { get; init; }
    public string? Specialization { get; init; }
    public string Status { get; init; } = string.Empty;
    public bool HasLoginAccess { get; init; }
    public DateTime CreatedAt { get; init; }
}
