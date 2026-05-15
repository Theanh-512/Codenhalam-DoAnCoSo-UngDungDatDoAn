using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Infrastructure.Data;
using Domain.Entities;
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

        public AdminController(FoodAppDbContext context)
        {
            _context = context;
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
    }
}
