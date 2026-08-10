using GoldDesk.Application.Common.Interfaces;
using GoldDesk.Application.Common.Models;
using GoldDesk.Application.Features.Karigars.Dtos;
using GoldDesk.Domain.Entities;
using GoldDesk.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GoldDesk.Application.Features.Karigars.CreateKarigar;

public class CreateKarigarCommandHandler : IRequestHandler<CreateKarigarCommand, Result<KarigarDto>>
{
    private readonly IApplicationDbContext _context;
    private readonly IAuthProvider _authProvider;
    private readonly ICurrentUserService _currentUser;

    public CreateKarigarCommandHandler(
        IApplicationDbContext context,
        IAuthProvider authProvider,
        ICurrentUserService currentUser)
    {
        _context = context;
        _authProvider = authProvider;
        _currentUser = currentUser;
    }

    public async Task<Result<KarigarDto>> Handle(CreateKarigarCommand request, CancellationToken cancellationToken)
    {
        // Check if mobile already exists for this tenant
        var mobileExists = await _context.Karigars
            .AnyAsync(k => k.Mobile == request.Mobile, cancellationToken);

        if (mobileExists)
            return Result<KarigarDto>.Conflict("A Karigar with this mobile number already exists");

        User? user = null;

        // Create login user if requested
        if (request.CreateLogin)
        {
            var email = request.Email;
            if (string.IsNullOrEmpty(email))
            {
                // Generate email from mobile if not provided
                email = $"karigar.{request.Mobile}@golddesk.local";
            }

            // Check email uniqueness
            var emailExists = await _context.Users
                .IgnoreQueryFilters()
                .AnyAsync(u => u.Email == email, cancellationToken);

            if (emailExists)
                return Result<KarigarDto>.Conflict("A user with this email already exists");

            user = new User
            {
                TenantId = _currentUser.TenantId!.Value,
                Email = email,
                PasswordHash = _authProvider.HashPassword(request.Password!),
                FullName = request.Name,
                Mobile = request.Mobile,
                Role = UserRole.Karigar,
                Status = UserStatus.Active
            };

            _context.Users.Add(user);
        }

        var karigar = new Karigar
        {
            UserId = user?.Id,
            Name = request.Name,
            Mobile = request.Mobile,
            Email = request.Email,
            Address = request.Address,
            Specialization = request.Specialization,
            Status = KarigarStatus.Active
        };

        _context.Karigars.Add(karigar);
        await _context.SaveChangesAsync(cancellationToken);

        return Result<KarigarDto>.Created(new KarigarDto
        {
            Id = karigar.Id,
            Name = karigar.Name,
            Mobile = karigar.Mobile,
            Email = karigar.Email,
            Address = karigar.Address,
            Specialization = karigar.Specialization,
            Status = karigar.Status.ToString(),
            HasLoginAccess = user != null,
            CreatedAt = karigar.CreatedAt
        });
    }
}
