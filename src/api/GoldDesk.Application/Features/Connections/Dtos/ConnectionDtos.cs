namespace GoldDesk.Application.Features.Connections.Dtos;

public record BusinessConnectionDto
{
    public Guid Id { get; init; }
    public Guid CounterpartyBusinessId { get; init; }
    public string CounterpartyName { get; init; } = string.Empty;
    public string CounterpartyGoldDeskId { get; init; } = string.Empty;
    public string CounterpartyBusinessType { get; init; } = string.Empty;
    public string ConnectionType { get; init; } = string.Empty;
    public string Status { get; init; } = string.Empty;
    public bool IsIncoming { get; init; }
    public DateTime CreatedAt { get; init; }
    public DateTime? AcceptedAt { get; init; }
}

public record BusinessSummaryDto
{
    public Guid Id { get; init; }
    public string Name { get; init; } = string.Empty;
    public string GoldDeskId { get; init; } = string.Empty;
    public string BusinessType { get; init; } = string.Empty;
    public string? Mobile { get; init; }
    public string? Address { get; init; }
}
