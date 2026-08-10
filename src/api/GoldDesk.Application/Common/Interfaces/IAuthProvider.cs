namespace GoldDesk.Application.Common.Interfaces;

public interface IAuthProvider
{
    string HashPassword(string password);
    bool VerifyPassword(string password, string passwordHash);
    string GenerateAccessToken(Guid userId, Guid tenantId, string email, string role);
    string GenerateRefreshToken();
}
