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

        // POST: api/Restaurants
        [HttpPost]
        public async Task<ActionResult<Restaurant>> PostRestaurant(Restaurant restaurant)
        {
            _context.Restaurants.Add(restaurant);
            await _context.SaveChangesAsync();
            return CreatedAtAction(nameof(GetRestaurants), new { id = restaurant.Id }, restaurant);
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
