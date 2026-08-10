using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Karigars.Dtos;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Karigars.UpdateKarigar;

public class UpdateKarigarCommandHandler : IRequestHandler<UpdateKarigarCommand, Result<KarigarDto>>
{
    private readonly IApplicationDbContext _context;

    public UpdateKarigarCommandHandler(IApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<Result<KarigarDto>> Handle(UpdateKarigarCommand request, CancellationToken cancellationToken)
    {
        var karigar = await _context.Karigars
            .FirstOrDefaultAsync(k => k.Id == request.Id, cancellationToken);

        if (karigar == null)
            return Result<KarigarDto>.NotFound("Karigar not found");

        karigar.Name = request.Name;
        karigar.Mobile = request.Mobile;
        karigar.Email = request.Email;
        karigar.Address = request.Address;
        karigar.Specialization = request.Specialization;

        await _context.SaveChangesAsync(cancellationToken);

        return Result<KarigarDto>.Success(new KarigarDto
        {
            Id = karigar.Id,
            Name = karigar.Name,
            Mobile = karigar.Mobile,
            Email = karigar.Email,
            Address = karigar.Address,
            Specialization = karigar.Specialization,
            Status = karigar.Status.ToString(),
            HasLoginAccess = karigar.UserId != null,
            CreatedAt = karigar.CreatedAt
        });
    }
}
