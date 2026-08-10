namespace GoldDesk.Application.Features.Items.Dtos;

public record ItemDto
{
    public Guid Id { get; init; }
    public string Name { get; init; } = string.Empty;
    public string? Category { get; init; }
    public string? Purity { get; init; }
    public decimal? DefaultRate { get; init; }
    public decimal? DefaultMakingCharge { get; init; }
    public bool IsActive { get; init; }
    public DateTime CreatedAt { get; init; }
}
