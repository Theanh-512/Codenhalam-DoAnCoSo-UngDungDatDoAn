using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Infrastructure.Data;
using Domain.Entities;
using System.Collections.Generic;
using System.Threading.Tasks;
using System;
using System.Linq;

namespace API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class RestaurantsController : ControllerBase
    {
        private readonly FoodAppDbContext _context;
        private readonly IMemoryCache _cache;

        public RestaurantsController(FoodAppDbContext context, IMemoryCache cache)
        {
            _context = context;
            _cache = cache;
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
            // THEO BÁO CÁO: Tối ưu hóa cơ chế Caching cho dữ liệu Long-term
            var cacheKey = $"User_{userId}_Lat_{lat}_Lng_{lng}_Recs";
            if (_cache.TryGetValue(cacheKey, out List<Restaurant> cachedRestaurants))
            {
                return cachedRestaurants;
            }

            // THEO BÁO CÁO: Giới hạn bán kính không gian (Spatial filtering 5km-10km)
            var allRestaurants = await _context.Restaurants.ToListAsync();
            var nearbyRestaurants = allRestaurants
                .Where(r => CalculateDistance(lat, lng, r.Latitude, r.Longitude) <= 10.0)
                .ToList();

            if (!nearbyRestaurants.Any())
            {
                return NotFound(new { message = "Không tìm thấy nhà hàng nào trong bán kính 10km." });
            }

            var aiEngine = new AICore.RecommendationEngine();
            // Gọi AI Service (Sẽ gọi gRPC trong thực tế) để lấy Top-N
            var topIds = await aiEngine.PredictTopN(userId, lat, lng, 5);

            List<Restaurant> recommendedRestaurants;

            if (topIds == null || topIds.Length == 0)
            {
                // THEO BÁO CÁO: Vấn đề Cold Start -> Cơ chế Fallback sử dụng KNN (khoảng cách thuần túy)
                recommendedRestaurants = nearbyRestaurants
                    .OrderBy(r => CalculateDistance(lat, lng, r.Latitude, r.Longitude))
                    .Take(5)
                    .ToList();
            }
            else
            {
                recommendedRestaurants = nearbyRestaurants
                    .Where(r => topIds.Contains(r.Id))
                    .ToList();

                if (!recommendedRestaurants.Any()) 
                {
                    recommendedRestaurants = nearbyRestaurants
                        .OrderBy(r => CalculateDistance(lat, lng, r.Latitude, r.Longitude))
                        .Take(5)
                        .ToList();
                }
            }

            // Lưu vào Memory Cache với TTL 30 phút (Giảm tải truy vấn SQL)
            var cacheEntryOptions = new MemoryCacheEntryOptions()
                .SetAbsoluteExpiration(TimeSpan.FromMinutes(30));
            _cache.Set(cacheKey, recommendedRestaurants, cacheEntryOptions);

            return recommendedRestaurants;
        }

        private double CalculateDistance(double lat1, double lon1, double lat2, double lon2)
        {
            var R = 6371; // Bán kính trái đất (km)
            var dLat = Deg2Rad(lat2 - lat1);
            var dLon = Deg2Rad(lon2 - lon1);
            var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                    Math.Cos(Deg2Rad(lat1)) * Math.Cos(Deg2Rad(lat2)) *
                    Math.Sin(dLon / 2) * Math.Sin(dLon / 2);
            var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
            var d = R * c; 
            return d;
        }

        private double Deg2Rad(double deg)
        {
            return deg * (Math.PI / 180);
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
