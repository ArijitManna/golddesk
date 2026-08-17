namespace GoldDesk.Application.Features.Orders.Dtos;

public record OrderDto
{
    public Guid Id { get; init; }
    public string OrderNo { get; init; } = string.Empty;
    public Guid? OrderFromBusinessId { get; init; }
    public Guid? OrderFromExternalBusinessId { get; init; }
    public string OrderFromBusinessName { get; init; } = string.Empty;
    public string OrderDate { get; init; } = string.Empty;
    public string? DeliveryDate { get; init; }
    public string Status { get; init; } = string.Empty;
    public string AcceptanceStatus { get; init; } = string.Empty;
    public string? AcceptanceNote { get; init; }
    public decimal TotalWeight { get; init; }
    public decimal MakingCharges { get; init; }
    public decimal AdvancePaid { get; init; }
    public decimal EstimatedAmount { get; init; }
    public string? Notes { get; init; }
    public string? KarigarName { get; init; }
    public string? AssignmentStatus { get; init; }
    public string? DueDate { get; init; }
    public string? FirstItemImage { get; init; }
    public string Source { get; init; } = "Direct";
    public Guid CreatedByBusinessId { get; init; }
    public string CreatedByBusinessName { get; init; } = string.Empty;
    public Guid CreatedForBusinessId { get; init; }
    public string CreatedForBusinessName { get; init; } = string.Empty;
    public DateTime CreatedAt { get; init; }
}

public record OrderDetailDto : OrderDto
{
    public List<OrderItemDto> Items { get; init; } = new();
    public List<AssignmentDto> Assignments { get; init; } = new();
    public List<StatusHistoryDto> StatusHistory { get; init; } = new();
}

public record OrderItemDto
{
    public Guid Id { get; init; }
    public Guid? ItemMasterId { get; init; }
    public string ItemName { get; init; } = string.Empty;
    public decimal Weight { get; init; }
    public int Quantity { get; init; }
    public string? Purity { get; init; }
    public decimal Rate { get; init; }
    public decimal MakingCharge { get; init; }
    public decimal Amount { get; init; }
    public string? Size { get; init; }
    public string? ImagePath { get; init; }
}

public record AssignmentDto
{
    public Guid Id { get; init; }
    public string KarigarName { get; init; } = string.Empty;
    public Guid KarigarId { get; init; }
    public string GivenDate { get; init; } = string.Empty;
    public string DueDate { get; init; } = string.Empty;
    public string Status { get; init; } = string.Empty;
    public string? Notes { get; init; }
    public bool IsActive { get; init; }
    public DateTime CreatedAt { get; init; }
}

public record StatusHistoryDto
{
    public string FromStatus { get; init; } = string.Empty;
    public string ToStatus { get; init; } = string.Empty;
    public string? Remarks { get; init; }
    public DateTime ChangedAt { get; init; }
}
