using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Domain.Entities;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.ExternalBusinesses;

public record CreateExternalBusinessCommand : IRequest<Result<ExternalBusinessDto>>
{
    public string CustomerCode { get; init; } = string.Empty;
    public string Name { get; init; } = string.Empty;
    public BusinessType BusinessType { get; init; } = BusinessType.Shop;
    public string? ContactPerson { get; init; }
    public string? Mobile { get; init; }
    public string? Email { get; init; }
    public string? Address { get; init; }
}

public record UpdateExternalBusinessCommand : IRequest<Result<ExternalBusinessDto>>
{
    public Guid Id { get; init; }
    public string CustomerCode { get; init; } = string.Empty;
    public string Name { get; init; } = string.Empty;
    public string? ContactPerson { get; init; }
    public string? Mobile { get; init; }
    public string? Email { get; init; }
    public string? Address { get; init; }
}

public record GetExternalBusinessesQuery : IRequest<Result<List<ExternalBusinessDto>>>;

public record ExternalBusinessDto
{
    public Guid Id { get; init; }
    public string CustomerCode { get; init; } = string.Empty;
    public string Name { get; init; } = string.Empty;
    public string BusinessType { get; init; } = string.Empty;
    public string? ContactPerson { get; init; }
    public string? Mobile { get; init; }
    public string? Email { get; init; }
    public string? Address { get; init; }
    public Guid? LinkedBusinessId { get; init; }
}

public class CreateExternalBusinessCommandHandler
    : IRequestHandler<CreateExternalBusinessCommand, Result<ExternalBusinessDto>>
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;

    public CreateExternalBusinessCommandHandler(IApplicationDbContext context, ICurrentUserService currentUser)
    {
        _context = context;
        _currentUser = currentUser;
    }

    public async Task<Result<ExternalBusinessDto>> Handle(CreateExternalBusinessCommand request, CancellationToken cancellationToken)
    {
        if (!_currentUser.TenantId.HasValue)
            return Result<ExternalBusinessDto>.Unauthorized();

        var customerCode = request.CustomerCode.Trim();
        var codeExists = await _context.ExternalBusinesses
            .AnyAsync(b => b.CustomerCode == customerCode, cancellationToken);
        if (codeExists)
            return Result<ExternalBusinessDto>.Conflict($"Customer code '{customerCode}' already exists");

        var business = new ExternalBusiness
        {
            TenantId = _currentUser.TenantId.Value,
            CustomerCode = customerCode,
            Name = request.Name.Trim(),
            BusinessType = request.BusinessType,
            ContactPerson = request.ContactPerson?.Trim(),
            Mobile = request.Mobile?.Trim(),
            Email = request.Email?.Trim(),
            Address = request.Address?.Trim()
        };

        _context.ExternalBusinesses.Add(business);
        await _context.SaveChangesAsync(cancellationToken);
        return Result<ExternalBusinessDto>.Created(ToDto(business));
    }

    internal static ExternalBusinessDto ToDto(ExternalBusiness business) => new()
    {
        Id = business.Id,
        CustomerCode = business.CustomerCode,
        Name = business.Name,
        BusinessType = business.BusinessType.ToString(),
        ContactPerson = business.ContactPerson,
        Mobile = business.Mobile,
        Email = business.Email,
        Address = business.Address,
        LinkedBusinessId = business.LinkedBusinessId
    };
}

public class GetExternalBusinessesQueryHandler
    : IRequestHandler<GetExternalBusinessesQuery, Result<List<ExternalBusinessDto>>>
{
    private readonly IApplicationDbContext _context;

    public GetExternalBusinessesQueryHandler(IApplicationDbContext context) => _context = context;

    public async Task<Result<List<ExternalBusinessDto>>> Handle(GetExternalBusinessesQuery request, CancellationToken cancellationToken)
    {
        var businesses = await _context.ExternalBusinesses
            .AsNoTracking()
            .OrderBy(b => b.Name)
            .Select(b => new ExternalBusinessDto
            {
                Id = b.Id,
                CustomerCode = b.CustomerCode,
                Name = b.Name,
                BusinessType = b.BusinessType.ToString(),
                ContactPerson = b.ContactPerson,
                Mobile = b.Mobile,
                Email = b.Email,
                Address = b.Address,
                LinkedBusinessId = b.LinkedBusinessId
            })
            .ToListAsync(cancellationToken);

        return Result<List<ExternalBusinessDto>>.Success(businesses);
    }
}

public class UpdateExternalBusinessCommandHandler
    : IRequestHandler<UpdateExternalBusinessCommand, Result<ExternalBusinessDto>>
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;

    public UpdateExternalBusinessCommandHandler(IApplicationDbContext context, ICurrentUserService currentUser)
    {
        _context = context;
        _currentUser = currentUser;
    }

    public async Task<Result<ExternalBusinessDto>> Handle(UpdateExternalBusinessCommand request, CancellationToken cancellationToken)
    {
        if (!_currentUser.TenantId.HasValue)
            return Result<ExternalBusinessDto>.Unauthorized();

        var business = await _context.ExternalBusinesses
            .FirstOrDefaultAsync(b => b.Id == request.Id, cancellationToken);
        if (business == null)
            return Result<ExternalBusinessDto>.NotFound("External business not found.");

        var customerCode = request.CustomerCode.Trim();
        var codeExists = await _context.ExternalBusinesses
            .AnyAsync(b => b.Id != request.Id && b.CustomerCode == customerCode, cancellationToken);
        if (codeExists)
            return Result<ExternalBusinessDto>.Conflict($"Customer code '{customerCode}' already exists");

        business.CustomerCode = customerCode;
        business.Name = request.Name.Trim();
        business.ContactPerson = request.ContactPerson?.Trim();
        business.Mobile = request.Mobile?.Trim();
        business.Email = request.Email?.Trim();
        business.Address = request.Address?.Trim();

        await _context.SaveChangesAsync(cancellationToken);
        return Result<ExternalBusinessDto>.Success(CreateExternalBusinessCommandHandler.ToDto(business));
    }
}
