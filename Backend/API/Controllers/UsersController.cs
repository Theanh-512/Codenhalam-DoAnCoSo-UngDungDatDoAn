using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Infrastructure.Data;
using Domain.Entities;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class UsersController : ControllerBase
    {
        private readonly FoodAppDbContext _context;

        public UsersController(FoodAppDbContext context)
        {
            _context = context;
        }

        // GET: api/Users
        [HttpGet]
        public async Task<ActionResult<IEnumerable<User>>> GetUsers()
        {
            return await _context.Users.ToListAsync();
        }

        // POST: api/Users/seed
        [HttpPost("seed")]
        public async Task<IActionResult> SeedUsers()
        {
            if (await _context.Users.AnyAsync()) return BadRequest("Users already exist");

            var testUsers = new List<User>
            {
                new User { Email = "test1@gmail.com", FullName = "Nguyễn Văn A", PasswordHash = "123456", PhoneNumber = "0123456781" },
                new User { Email = "test2@gmail.com", FullName = "Trần Thị B", PasswordHash = "123456", PhoneNumber = "0123456782" },
                new User { Email = "admin@foodapp.com", FullName = "Admin Hệ Thống", PasswordHash = "admin123", PhoneNumber = "0999999999" }
            };

            _context.Users.AddRange(testUsers);
            await _context.SaveChangesAsync();

            return Ok("Đã tạo 3 tài khoản test thành công!");
        }
        // POST: api/Users/login
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.Email == request.Email && u.PasswordHash == request.Password);

            if (user == null)
            {
                return Unauthorized(new { message = "Email hoặc mật khẩu không chính xác" });
            }

            // In a real app, return a JWT token here
            return Ok(new { 
                id = user.Id, 
                email = user.Email, 
                fullName = user.FullName,
                message = "Đăng nhập thành công" 
            });
        }
        // POST: api/Users/register
        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterRequest request)
        {
            if (await _context.Users.AnyAsync(u => u.Email == request.Email))
            {
                return BadRequest(new { message = "Email này đã được sử dụng" });
            }

            var newUser = new User 
            { 
                Email = request.Email, 
                PasswordHash = request.Password, // Simple for now
                FullName = request.FullName,
                PhoneNumber = request.PhoneNumber,
                Address = "",
                CreatedDate = System.DateTime.UtcNow
            };

            _context.Users.Add(newUser);
            await _context.SaveChangesAsync();

            return Ok(new { 
                message = "Đăng ký thành công",
                id = newUser.Id,
                email = newUser.Email,
                fullName = newUser.FullName
            });
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
}
