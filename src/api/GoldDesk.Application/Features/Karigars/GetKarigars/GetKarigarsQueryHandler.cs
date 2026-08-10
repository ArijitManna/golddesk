using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Karigars.Dtos;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Karigars.GetKarigars;

public class GetKarigarsQueryHandler : IRequestHandler<GetKarigarsQuery, Result<PagedResult<KarigarDto>>>
{
    private readonly IApplicationDbContext _context;

    public GetKarigarsQueryHandler(IApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<Result<PagedResult<KarigarDto>>> Handle(GetKarigarsQuery request, CancellationToken cancellationToken)
    {
        var query = _context.Karigars.AsQueryable();

        if (request.ActiveOnly == true)
        {
            query = query.Where(k => k.Status == KarigarStatus.Active);
        }

        if (!string.IsNullOrWhiteSpace(request.Search))
        {
            var search = request.Search.ToLower();
            query = query.Where(k =>
                k.Name.ToLower().Contains(search) ||
                k.Mobile.Contains(search) ||
                (k.Specialization != null && k.Specialization.ToLower().Contains(search)));
        }

        var totalCount = await query.CountAsync(cancellationToken);

        var items = await query
            .OrderBy(k => k.Name)
            .Skip((request.Page - 1) * request.PageSize)
            .Take(request.PageSize)
            .Select(k => new KarigarDto
            {
                Id = k.Id,
                Name = k.Name,
                Mobile = k.Mobile,
                Email = k.Email,
                Address = k.Address,
                Specialization = k.Specialization,
                Status = k.Status.ToString(),
                HasLoginAccess = k.UserId != null,
                CreatedAt = k.CreatedAt
            })
            .ToListAsync(cancellationToken);

        return Result<PagedResult<KarigarDto>>.Success(
            new PagedResult<KarigarDto>(items, totalCount, request.Page, request.PageSize));
    }
}
