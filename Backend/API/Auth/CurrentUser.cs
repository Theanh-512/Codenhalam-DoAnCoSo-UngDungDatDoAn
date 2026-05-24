using System.Security.Claims;

namespace API.Auth
{
    public static class CurrentUser
    {
        /// <summary>Trả về Id user từ JWT (claim NameIdentifier hoặc sub).</summary>
        public static int? GetUserId(ClaimsPrincipal? principal)
        {
            if (principal == null) return null;
            var raw = principal.FindFirstValue(ClaimTypes.NameIdentifier)
                      ?? principal.FindFirstValue("sub");
            return int.TryParse(raw, out var id) ? id : null;
        }

        public static string? GetEmail(ClaimsPrincipal? principal)
            => principal?.FindFirstValue(ClaimTypes.Email)
               ?? principal?.FindFirstValue("email");
    }
}
