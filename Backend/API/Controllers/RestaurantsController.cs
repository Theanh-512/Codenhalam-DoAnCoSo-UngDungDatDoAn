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
    public class RestaurantsController : ControllerBase
    {
        private readonly FoodAppDbContext _context;

        public RestaurantsController(FoodAppDbContext context)
        {
            _context = context;
        }

        // GET: api/Restaurants
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Restaurant>>> GetRestaurants()
        {
            // Demo retrieving data from Supabase
            return await _context.Restaurants.ToListAsync();
        }

        // GET: api/Restaurants/{id}/menu
        [HttpGet("{id}/menu")]
        public async Task<ActionResult<IEnumerable<FoodItem>>> GetMenu(int id)
        {
            var menu = await _context.FoodItems
                .Include(f => f.Category)
                .Where(f => f.RestaurantId == id && f.IsAvailable)
                .ToListAsync();

            if (menu == null || !menu.Any())
            {
                return NotFound(new { message = "Không tìm thấy món ăn cho nhà hàng này." });
            }

            return menu;
        }

        // GET: api/Restaurants/recommend
        [HttpGet("recommend")]
        public async Task<ActionResult<IEnumerable<Restaurant>>> GetRecommendedRestaurants([FromQuery] int userId, [FromQuery] double lat, [FromQuery] double lng)
        {
            var aiEngine = new AICore.RecommendationEngine();
            // Lấy danh sách ID từ SCR Python Model
            var topIds = await aiEngine.PredictTopN(userId, lat, lng, 5);

            if (topIds == null || topIds.Length == 0)
            {
                return await _context.Restaurants.Take(5).ToListAsync(); // Fallback
            }

            var recommendedRestaurants = await _context.Restaurants
                .Where(r => topIds.Contains(r.Id))
                .ToListAsync();

            return recommendedRestaurants;
        }

        // POST: api/Restaurants
        [HttpPost]
        public async Task<ActionResult<Restaurant>> PostRestaurant(Restaurant restaurant)
        {
            _context.Restaurants.Add(restaurant);
            await _context.SaveChangesAsync();
            return CreatedAtAction(nameof(GetRestaurants), new { id = restaurant.Id }, restaurant);
        }

        // PUT: api/Restaurants/{id}
        [HttpPut("{id}")]
        public async Task<IActionResult> PutRestaurant(int id, Restaurant restaurant)
        {
            if (id != restaurant.Id) return BadRequest();

            _context.Entry(restaurant).State = EntityState.Modified;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!await _context.Restaurants.AnyAsync(er => er.Id == id)) return NotFound();
                else throw;
            }

            return NoContent();
        }

        // DELETE: api/Restaurants/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteRestaurant(int id)
        {
            var restaurant = await _context.Restaurants.FindAsync(id);
            if (restaurant == null) return NotFound();

            _context.Restaurants.Remove(restaurant);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        // POST: api/Restaurants/seed
        [HttpPost("seed")]
        public async Task<IActionResult> SeedRestaurants()
        {
            if (await _context.Restaurants.AnyAsync()) return BadRequest("Restaurants already exist");

            var testRestaurants = new List<Restaurant>
            {
                new Restaurant 
                { 
                    Name = "Phở Thìn Lò Đúc", 
                    Description = "Phở truyền thống nổi tiếng Hà Nội", 
                    Address = "13 Lò Đúc, Hai Bà Trưng, Hà Nội",
                    ImageUrl = "https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=500",
                    Latitude = 21.018, Longitude = 105.856,
                    OpeningHours = "06:00-21:00"
                },
                new Restaurant 
                { 
                    Name = "Pizza 4P's", 
                    Description = "Pizza nướng lò củi phong cách Nhật", 
                    Address = "Tràng Tiền, Hoàn Kiếm, Hà Nội",
                    ImageUrl = "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500",
                    Latitude = 21.025, Longitude = 105.853,
                    OpeningHours = "10:00-22:00"
                },
                new Restaurant 
                { 
                    Name = "Bún Chả Hương Liên", 
                    Description = "Bún chả Obama nổi tiếng", 
                    Address = "24 Lê Văn Hưu, Hai Bà Trưng, Hà Nội",
                    ImageUrl = "https://images.unsplash.com/photo-1541529086526-db283c563270?w=500",
                    Latitude = 21.019, Longitude = 105.848,
                    OpeningHours = "08:00-20:00"
                }
            };

            _context.Restaurants.AddRange(testRestaurants);
            await _context.SaveChangesAsync();

            return Ok("Đã tạo 3 nhà hàng test thành công!");
        }
    }
}
