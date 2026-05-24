using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Domain.Entities;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;

namespace API.Auth
{
    public interface IJwtTokenService
    {
        string CreateToken(User user);
        TokenValidationParameters GetValidationParameters();
        DateTime DefaultExpiry { get; }
    }

    public class JwtTokenService : IJwtTokenService
    {
        private readonly string _issuer;
        private readonly string _audience;
        private readonly string _key;
        private readonly int _expireMinutes;

        public JwtTokenService(IConfiguration config)
        {
            var section = config.GetSection("Jwt");
            _issuer = section.GetValue<string>("Issuer") ?? "FoodApp";
            _audience = section.GetValue<string>("Audience") ?? "FoodAppClient";
            _key = section.GetValue<string>("Key") ?? string.Empty;
            _expireMinutes = section.GetValue<int?>("ExpireMinutes") ?? 1440;

            if (string.IsNullOrWhiteSpace(_key) || Encoding.UTF8.GetByteCount(_key) < 32)
            {
                throw new InvalidOperationException(
                    "Jwt:Key chưa được cấu hình hoặc ngắn hơn 32 byte. " +
                    "Hãy đặt trong appsettings.Development.json (đã .gitignore).");
            }
        }

        public DateTime DefaultExpiry => DateTime.UtcNow.AddMinutes(_expireMinutes);

        public string CreateToken(User user)
        {
            var role = NormalizeRole(user.UserRole);
            var claims = new List<Claim>
            {
                new(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
                new(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new(JwtRegisteredClaimNames.Email, user.Email ?? string.Empty),
                new(ClaimTypes.Email, user.Email ?? string.Empty),
                new(ClaimTypes.Name, user.FullName ?? string.Empty),
                new(ClaimTypes.Role, role),
                new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            };

            var creds = new SigningCredentials(
                new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_key)),
                SecurityAlgorithms.HmacSha256);

            var token = new JwtSecurityToken(
                issuer: _issuer,
                audience: _audience,
                claims: claims,
                expires: DefaultExpiry,
                signingCredentials: creds);

            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        public TokenValidationParameters GetValidationParameters() => new()
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = _issuer,
            ValidAudience = _audience,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_key)),
            ClockSkew = TimeSpan.FromMinutes(2),
            NameClaimType = ClaimTypes.Name,
            RoleClaimType = ClaimTypes.Role,
        };

        /// <summary>Chuẩn hoá role lưu trong DB sang giá trị dùng cho [Authorize(Roles=...)].</summary>
        public static string NormalizeRole(string? raw)
        {
            if (string.IsNullOrWhiteSpace(raw)) return "User";
            var v = raw.Trim().ToLowerInvariant();
            return v switch
            {
                "admin" => "Admin",
                "shipper" or "driver" => "Shipper",
                _ => "User",
            };
        }
    }
}
