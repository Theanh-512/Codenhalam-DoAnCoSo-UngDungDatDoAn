using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Infrastructure.Data;
using Domain.Entities;
using Infrastructure.Services;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Linq;

namespace API.Controllers
{
    [ApiController]
    [Authorize(Roles = "Admin")]
    [Route("api/admin")]
    public class AdminController : ControllerBase
    {
        private readonly FoodAppDbContext _context;
        private readonly FoodImageUrlSyncService _imageSync;

        public AdminController(FoodAppDbContext context, FoodImageUrlSyncService imageSync)
        {
            _context = context;
            _imageSync = imageSync;
        }

        // --- RESTAURANTS ---

        [HttpGet("restaurants")]
        public async Task<ActionResult<IEnumerable<Restaurant>>> GetRestaurants()
        {
            return await _context.Restaurants.OrderByDescending(r => r.CreatedDate).ToListAsync();
        }

        [HttpPost("restaurants")]
        public async Task<ActionResult<Restaurant>> CreateRestaurant(Restaurant restaurant)
        {
            restaurant.CreatedDate = System.DateTime.UtcNow;
            _context.Restaurants.Add(restaurant);
            await _context.SaveChangesAsync();
            return CreatedAtAction(nameof(GetRestaurants), new { id = restaurant.Id }, restaurant);
        }

        [HttpPut("restaurants/{id}")]
        public async Task<IActionResult> UpdateRestaurant(int id, Restaurant restaurant)
        {
            if (id != restaurant.Id) return BadRequest();
            _context.Entry(restaurant).State = EntityState.Modified;
            await _context.SaveChangesAsync();
            return Ok(restaurant);
        }

        [HttpDelete("restaurants/{id}")]
        public async Task<IActionResult> DeleteRestaurant(int id)
        {
            var res = await _context.Restaurants.FindAsync(id);
            if (res == null) return NotFound();
            _context.Restaurants.Remove(res);
            await _context.SaveChangesAsync();
            return Ok(new { message = "Xóa nhà hàng thành công" });
        }

        // --- FOOD ITEMS ---

        [HttpGet("items")]
        public async Task<ActionResult<IEnumerable<FoodItem>>> GetItems([FromQuery] int? restaurantId)
        {
            var query = _context.FoodItems.AsQueryable();
            if (restaurantId.HasValue)
            {
                query = query.Where(f => f.RestaurantId == restaurantId.Value);
            }
            return await query.OrderByDescending(f => f.CreatedDate).ToListAsync();
        }

        [HttpPost("items")]
        public async Task<ActionResult<FoodItem>> CreateItem(FoodItem item)
        {
            item.CreatedDate = System.DateTime.UtcNow;
            _context.FoodItems.Add(item);
            await _context.SaveChangesAsync();
            return Ok(item);
        }

        [HttpPut("items/{id}")]
        public async Task<IActionResult> UpdateItem(int id, FoodItem item)
        {
            if (id != item.Id) return BadRequest();
            _context.Entry(item).State = EntityState.Modified;
            await _context.SaveChangesAsync();
            return Ok(item);
        }

        [HttpDelete("items/{id}")]
        public async Task<IActionResult> DeleteItem(int id)
        {
            var item = await _context.FoodItems.FindAsync(id);
            if (item == null) return NotFound();
            _context.FoodItems.Remove(item);
            await _context.SaveChangesAsync();
            return Ok(new { message = "Xóa món ăn thành công" });
        }

        // --- CATEGORIES ---
        [HttpGet("categories")]
        public async Task<ActionResult<IEnumerable<Category>>> GetCategories()
        {
            return await _context.Categories.ToListAsync();
        }

        // --- USERS (admin) ---
        // Frontend (admin_users_view) gọi GET /api/admin/users + PATCH /api/admin/users/{id}.
        // User entity hiện chưa có cột IsActive → DTO trả `is_active = true` cố định,
        // PATCH bỏ qua field is_active. Nếu sau này thêm IsActive cần migration riêng.
        [HttpGet("users")]
        public async Task<ActionResult> GetUsers()
        {
            var users = await _context.Users
                .OrderByDescending(u => u.CreatedDate)
                .Select(u => new
                {
                    id = u.Id,
                    email = u.Email,
                    fullname = u.FullName,
                    phone = u.PhoneNumber,
                    address = u.Address,
                    role = (u.UserRole ?? "User").ToLower(),
                    is_active = true,
                    created_at = u.CreatedDate,
                })
                .ToListAsync();
            return Ok(users);
        }

        public class UserPatchRequest
        {
            public string? Fullname { get; set; }
            public string? Phone { get; set; }
            public string? Address { get; set; }
            public string? Role { get; set; }
            public bool? Is_active { get; set; }
        }

        [HttpPatch("users/{id}")]
        public async Task<ActionResult> PatchUser(int id, [FromBody] UserPatchRequest req)
        {
            var u = await _context.Users.FindAsync(id);
            if (u == null) return NotFound(new { message = "Không tìm thấy người dùng" });

            if (req.Fullname != null) u.FullName = req.Fullname.Trim();
            if (req.Phone != null) u.PhoneNumber = req.Phone.Trim();
            if (req.Address != null) u.Address = req.Address.Trim();
            if (!string.IsNullOrWhiteSpace(req.Role))
            {
                var role = req.Role.Trim().ToLower();
                u.UserRole = role == "admin" ? "Admin" : "User";
            }
            u.UpdatedDate = System.DateTime.UtcNow;
            await _context.SaveChangesAsync();
            return Ok(new
            {
                id = u.Id,
                email = u.Email,
                fullname = u.FullName,
                phone = u.PhoneNumber,
                address = u.Address,
                role = (u.UserRole ?? "User").ToLower(),
                is_active = true,
            });
        }

        // --- ORDERS (admin) ---
        // Frontend (admin_orders_view) đọc DTO snake_case: id, total_price, status, created_at,
        // restaurant_name, receiver_name, receiver_phone, delivery_address, items[].{name,quantity}.
        [HttpGet("orders")]
        public async Task<ActionResult> GetOrders()
        {
            var orders = await _context.Orders
                .Include(o => o.OrderItems)
                    .ThenInclude(oi => oi.FoodItem)
                        .ThenInclude(f => f!.Restaurant)
                .Include(o => o.User)
                .OrderByDescending(o => o.OrderDate)
                .ToListAsync();

            var dto = orders.Select(o =>
            {
                var firstItem = o.OrderItems.FirstOrDefault(oi => oi.FoodItem?.Restaurant != null);
                var restaurant = firstItem?.FoodItem?.Restaurant;
                return new
                {
                    id = o.Id,
                    user_id = o.UserId,
                    user_email = o.User?.Email ?? string.Empty,
                    created_at = o.OrderDate,
                    status = (o.Status ?? "Pending").ToLower(),
                    total_price = o.TotalAmount,
                    payment_method = o.PaymentMethod ?? string.Empty,
                    voucher_code = o.VoucherCode ?? string.Empty,
                    receiver_name = o.ReceiverName ?? string.Empty,
                    receiver_phone = o.ReceiverPhone ?? string.Empty,
                    delivery_address = o.DeliveryAddress ?? string.Empty,
                    delivery_lat = o.DeliveryLatitude,
                    delivery_lng = o.DeliveryLongitude,
                    restaurant_id = restaurant?.Id,
                    restaurant_name = restaurant?.Name ?? string.Empty,
                    items = o.OrderItems.Select(oi => new
                    {
                        id = oi.Id,
                        name = oi.FoodItem?.Name ?? "(món đã ẩn)",
                        quantity = oi.Quantity,
                        unit_price = oi.UnitPrice,
                        line_total = oi.UnitPrice * oi.Quantity,
                    }).ToList(),
                };
            }).ToList();
            return Ok(dto);
        }

        public class OrderPatchRequest
        {
            public string? Status { get; set; }
        }

        [HttpPatch("orders/{id}")]
        public async Task<ActionResult> PatchOrder(int id, [FromBody] OrderPatchRequest req)
        {
            if (string.IsNullOrWhiteSpace(req.Status))
                return BadRequest(new { message = "Thiếu trạng thái" });

            var allowed = new[] { "pending", "confirmed", "preparing", "delivering", "completed", "cancelled" };
            var s = req.Status.Trim().ToLower();
            if (!allowed.Contains(s))
                return BadRequest(new { message = "Trạng thái không hợp lệ" });

            var order = await _context.Orders.FindAsync(id);
            if (order == null) return NotFound(new { message = "Không tìm thấy đơn" });

            order.Status = char.ToUpper(s[0]) + s.Substring(1);
            order.UpdatedDate = System.DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new { id = order.Id, status = order.Status.ToLower() });
        }

        /// <summary>
        /// Đồng bộ ImageUrl từ bucket Supabase food-images (khớp tên món / danh mục).
        /// </summary>
        [HttpPost("sync-food-images")]
        public async Task<ActionResult> SyncFoodImages(CancellationToken cancellationToken)
        {
            var result = await _imageSync.SyncAsync(cancellationToken);
            return Ok(result);
        }

        /// <summary>Sửa nhanh URL sai chữ hoa folder Storage (vd. Banh%20beo → banh%20beo).</summary>
        [HttpPost("fix-image-url-casing")]
        public async Task<ActionResult> FixImageUrlCasing(CancellationToken cancellationToken)
        {
            var pairs = new (string wrong, string right)[]
            {
                ("/food-images/Banh%20beo/", "/food-images/banh%20beo/"),
                ("/food-images/Banh%20Beo/", "/food-images/banh%20beo/"),
                ("/food-images/Pho/", "/food-images/pho/"),
                ("/food-images/Pizza/", "/food-images/pizza/"),
                ("/food-images/com%20tam/", "/food-images/Com%20tam/"),
                ("/food-images/xoi%20xeo/", "/food-images/Xoi%20xeo/"),
                ("/food-images/mi%20quang/", "/food-images/Mi%20quang/"),
                ("/food-images/goi%20cuon/", "/food-images/Goi%20cuon/"),
                ("/food-images/banh%20chung/", "/food-images/Banh%20chung/"),
                ("/food-images/banh%20tet/", "/food-images/Banh%20tet/"),
                ("/food-images/banh%20mi/", "/food-images/Banh%20mi/"),
                ("/food-images/banh%20cong/", "/food-images/Banh%20cong/"),
                ("/food-images/banh%20tieu/", "/food-images/Banh%20tieu/"),
                ("/food-images/banh%20khot/", "/food-images/Banh%20khot/"),
            };

            var food = 0;
            var rest = 0;
            foreach (var (wrong, right) in pairs)
            {
                food += await _context.Database.ExecuteSqlInterpolatedAsync($"""
                    UPDATE "FoodItems"
                    SET "ImageUrl" = REPLACE("ImageUrl", {wrong}, {right}),
                        "UpdatedDate" = NOW()
                    WHERE "ImageUrl" IS NOT NULL AND "ImageUrl" ILIKE ${"%" + wrong + "%"}
                    """);

                rest += await _context.Database.ExecuteSqlInterpolatedAsync($"""
                    UPDATE "Restaurants"
                    SET "ImageUrl" = REPLACE("ImageUrl", {wrong}, {right}),
                        "UpdatedDate" = NOW()
                    WHERE "ImageUrl" ILIKE ${"%" + wrong + "%"}
                    """);
            }

            return Ok(new
            {
                message = "Đã sửa chữ hoa trong URL ảnh",
                foodItemsUpdated = food,
                restaurantsUpdated = rest,
            });
        }
    }
}
