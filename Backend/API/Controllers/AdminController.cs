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
                ("/food-images/Xoi%20xeo/", "/food-images/Com%20tam/"),
                ("/food-images/xoi%20xeo/", "/food-images/Com%20tam/"),
                ("/food-images/Xoi%20Xeo/", "/food-images/Com%20tam/"),
                ("/food-images/com%20tam/", "/food-images/Com%20tam/"),
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
