using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using API.Auth;
using Domain.Entities;
using Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using BCryptNet = BCrypt.Net.BCrypt;

namespace API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class UsersController : ControllerBase
    {
        private readonly FoodAppDbContext _context;
        private readonly IJwtTokenService _jwt;

        public UsersController(FoodAppDbContext context, IJwtTokenService jwt)
        {
            _context = context;
            _jwt = jwt;
        }

        // GET /api/Users  (chỉ admin xem được).
        [Authorize(Roles = "Admin")]
        [HttpGet]
        public async Task<ActionResult<IEnumerable<User>>> GetUsers()
            => await _context.Users.AsNoTracking().ToListAsync();

        // POST /api/Users/seed - tạo nhanh tài khoản test khi DB rỗng.
        [HttpPost("seed")]
        public async Task<IActionResult> SeedUsers()
        {
            if (await _context.Users.AnyAsync()) return BadRequest("Users already exist");

            var seeds = new[]
            {
                new { Email = "test1@gmail.com",       Pw = "123456", Name = "Nguyễn Văn A",  Phone = "0123456781", Role = "User"  },
                new { Email = "test2@gmail.com",       Pw = "123456", Name = "Trần Thị B",    Phone = "0123456782", Role = "User"  },
                new { Email = "admin@foodapp.com",     Pw = "admin123", Name = "Admin Hệ Thống", Phone = "0999999999", Role = "Admin" },
            };
            foreach (var s in seeds)
            {
                _context.Users.Add(new User
                {
                    Email = s.Email,
                    PasswordHash = BCryptNet.HashPassword(s.Pw),
                    FullName = s.Name,
                    PhoneNumber = s.Phone,
                    UserRole = s.Role,
                });
            }
            await _context.SaveChangesAsync();
            return Ok("Đã tạo 3 tài khoản test thành công!");
        }

        // POST /api/Users/login
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Password))
                return BadRequest(new { message = "Vui lòng nhập email và mật khẩu" });

            var email = request.Email.Trim().ToLowerInvariant();
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email.ToLower() == email);
            if (user == null || !VerifyPassword(request.Password, user.PasswordHash))
            {
                return Unauthorized(new { message = "Email hoặc mật khẩu không chính xác" });
            }

            var token = _jwt.CreateToken(user);
            return Ok(new
            {
                token,
                expiresAt = _jwt.DefaultExpiry,
                id = user.Id,
                email = user.Email,
                fullName = user.FullName,
                userRole = user.UserRole,
                role = JwtTokenService.NormalizeRole(user.UserRole),
                message = "Đăng nhập thành công"
            });
        }

        // POST /api/Users/register
        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Password))
                return BadRequest(new { message = "Email và mật khẩu là bắt buộc" });
            if (request.Password.Length < 6)
                return BadRequest(new { message = "Mật khẩu tối thiểu 6 ký tự" });

            var email = request.Email.Trim();
            if (await _context.Users.AnyAsync(u => u.Email.ToLower() == email.ToLower()))
                return BadRequest(new { message = "Email này đã được sử dụng" });

            var user = new User
            {
                Email = email,
                PasswordHash = BCryptNet.HashPassword(request.Password),
                FullName = request.FullName ?? "",
                PhoneNumber = request.PhoneNumber ?? "",
                Address = "",
                UserRole = "User",
                CreatedDate = DateTime.UtcNow,
            };
            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            var token = _jwt.CreateToken(user);
            return Ok(new
            {
                token,
                expiresAt = _jwt.DefaultExpiry,
                id = user.Id,
                email = user.Email,
                fullName = user.FullName,
                userRole = user.UserRole,
                role = JwtTokenService.NormalizeRole(user.UserRole),
                message = "Đăng ký thành công",
            });
        }

        // GET /api/Users/profile  - đọc đúng người đang đăng nhập.
        [Authorize]
        [HttpGet("profile")]
        public async Task<IActionResult> GetProfile()
        {
            var id = CurrentUser.GetUserId(User);
            if (id == null) return Unauthorized();

            var user = await _context.Users.FindAsync(id.Value);
            if (user == null) return NotFound();

            // Trả về dạng Dictionary để gửi đồng thời nhiều alias (fullName/fullname,
            // phoneNumber/phone) cho cả client mới và cũ mà không bị JSON property collision.
            return Ok(new Dictionary<string, object?>
            {
                ["id"] = user.Id,
                ["email"] = user.Email,
                ["fullName"] = user.FullName,
                ["fullname"] = user.FullName,
                ["phoneNumber"] = user.PhoneNumber,
                ["phone"] = user.PhoneNumber,
                ["address"] = user.Address,
                ["userRole"] = user.UserRole,
                ["role"] = JwtTokenService.NormalizeRole(user.UserRole),
                ["created_at"] = user.CreatedDate,
            });
        }

        // PATCH /api/Users/profile  - cập nhật thông tin cá nhân.
        [Authorize]
        [HttpPatch("profile")]
        public async Task<IActionResult> UpdateProfile([FromBody] UpdateProfileRequest req)
        {
            var id = CurrentUser.GetUserId(User);
            if (id == null) return Unauthorized();
            var user = await _context.Users.FindAsync(id.Value);
            if (user == null) return NotFound();

            var name = req.ResolveName();
            var phone = req.ResolvePhone();
            if (name != null) user.FullName = name.Trim();
            if (phone != null) user.PhoneNumber = phone.Trim();
            if (req.Address != null) user.Address = req.Address.Trim();
            user.UpdatedDate = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            return Ok(new Dictionary<string, object?>
            {
                ["id"] = user.Id,
                ["email"] = user.Email,
                ["fullName"] = user.FullName,
                ["fullname"] = user.FullName,
                ["phoneNumber"] = user.PhoneNumber,
                ["phone"] = user.PhoneNumber,
                ["address"] = user.Address,
            });
        }

        // POST /api/Users/change-password  - đổi mật khẩu (cần JWT).
        [Authorize]
        [HttpPost("change-password")]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest req)
        {
            var id = CurrentUser.GetUserId(User);
            if (id == null) return Unauthorized();
            if (string.IsNullOrEmpty(req.NewPassword) || req.NewPassword.Length < 6)
                return BadRequest(new { message = "Mật khẩu mới tối thiểu 6 ký tự" });

            var user = await _context.Users.FindAsync(id.Value);
            if (user == null) return NotFound();
            if (!VerifyPassword(req.OldPassword ?? "", user.PasswordHash))
                return BadRequest(new { message = "Mật khẩu cũ không đúng" });

            user.PasswordHash = BCryptNet.HashPassword(req.NewPassword);
            user.UpdatedDate = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            return Ok(new { message = "Đổi mật khẩu thành công" });
        }

        // POST /api/Users/forgot-password  - stub để Flutter không 404.
        [HttpPost("forgot-password")]
        public Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequest _)
        {
            // TODO: gửi email mã OTP / link reset. Hiện trả OK cho UI khỏi vỡ.
            return Task.FromResult<IActionResult>(Ok(new
            {
                message = "Nếu email tồn tại, hệ thống đã gửi hướng dẫn đặt lại mật khẩu.",
            }));
        }

        // POST /api/Users/reset-password  - đặt lại mật khẩu khi quên.
        // Hiện chấp nhận email + mật khẩu mới (chưa làm OTP). Production cần token OTP.
        [HttpPost("reset-password")]
        public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequest req)
        {
            if (string.IsNullOrWhiteSpace(req.Email) || string.IsNullOrWhiteSpace(req.NewPassword))
                return BadRequest(new { message = "Thiếu email hoặc mật khẩu mới" });

            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email.ToLower() == req.Email.Trim().ToLower());
            if (user == null) return Ok(new { message = "Đã xử lý" }); // không lộ user tồn tại
            user.PasswordHash = BCryptNet.HashPassword(req.NewPassword);
            user.UpdatedDate = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            return Ok(new { message = "Đặt lại mật khẩu thành công" });
        }

        // POST /api/Users/social - login bằng tài khoản social (Google/Apple). Stub: tạo nếu chưa có.
        [HttpPost("social")]
        public async Task<IActionResult> SocialLogin([FromBody] SocialLoginRequest req)
        {
            if (string.IsNullOrWhiteSpace(req.Email))
                return BadRequest(new { message = "Thiếu email" });

            var email = req.Email.Trim();
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email.ToLower() == email.ToLower());
            if (user == null)
            {
                user = new User
                {
                    Email = email,
                    FullName = req.FullName ?? email,
                    PhoneNumber = "",
                    Address = "",
                    UserRole = "User",
                    PasswordHash = BCryptNet.HashPassword(Guid.NewGuid().ToString()),
                    CreatedDate = DateTime.UtcNow,
                };
                _context.Users.Add(user);
                await _context.SaveChangesAsync();
            }
            var token = _jwt.CreateToken(user);
            return Ok(new
            {
                token,
                expiresAt = _jwt.DefaultExpiry,
                id = user.Id,
                email = user.Email,
                fullName = user.FullName,
                userRole = user.UserRole,
                role = JwtTokenService.NormalizeRole(user.UserRole),
                provider = req.Provider,
            });
        }

        /// <summary>
        /// So khớp mật khẩu nhập với hash trong DB.
        /// Hỗ trợ ngược dữ liệu cũ lưu plain-text bằng cách upgrade dần khi đăng nhập đúng.
        /// </summary>
        private bool VerifyPassword(string raw, string stored)
        {
            if (string.IsNullOrEmpty(stored)) return false;

            // BCrypt hash bắt đầu bằng "$2a$" / "$2b$" / "$2y$".
            if (stored.StartsWith("$2a$") || stored.StartsWith("$2b$") || stored.StartsWith("$2y$"))
            {
                try { return BCryptNet.Verify(raw, stored); }
                catch { return false; }
            }

            // Legacy plain-text — so sánh trực tiếp; nếu trùng ta tự upgrade thành hash.
            if (stored == raw)
            {
                try
                {
                    var user = _context.Users.FirstOrDefault(u => u.PasswordHash == stored);
                    if (user != null)
                    {
                        user.PasswordHash = BCryptNet.HashPassword(raw);
                        user.UpdatedDate = DateTime.UtcNow;
                        _context.SaveChanges();
                    }
                }
                catch { /* upgrade là best effort */ }
                return true;
            }
            return false;
        }
    }

    public class LoginRequest
    {
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
    }

    public class RegisterRequest
    {
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public string PhoneNumber { get; set; } = string.Empty;
    }

    public class UpdateProfileRequest
    {
        public string? FullName { get; set; }
        public string? Fullname { get; set; }
        public string? PhoneNumber { get; set; }
        public string? Phone { get; set; }
        public string? Address { get; set; }

        /// <summary>Lấy giá trị họ tên ưu tiên fullName → fullname.</summary>
        public string? ResolveName() => FullName ?? Fullname;
        public string? ResolvePhone() => PhoneNumber ?? Phone;
    }

    public class ChangePasswordRequest
    {
        public string? OldPassword { get; set; }
        public string NewPassword { get; set; } = string.Empty;
    }

    public class ForgotPasswordRequest
    {
        public string Email { get; set; } = string.Empty;
    }

    public class ResetPasswordRequest
    {
        public string Email { get; set; } = string.Empty;
        public string NewPassword { get; set; } = string.Empty;
        public string? Otp { get; set; }
    }

    public class SocialLoginRequest
    {
        public string Provider { get; set; } = "google";
        public string Email { get; set; } = string.Empty;
        public string? FullName { get; set; }
    }
}
