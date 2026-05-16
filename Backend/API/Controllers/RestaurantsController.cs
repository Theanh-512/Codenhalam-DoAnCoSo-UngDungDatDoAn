using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Infrastructure.Data;
using Domain.Entities;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.IO;
using System.Text.Json;
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
                .AsNoTracking()
                .Include(f => f.Category)
                .Where(f => f.RestaurantId == id && f.IsAvailable)
                .Select(f => new FoodItem {
                    Id = f.Id,
                    Name = f.Name,
                    Description = f.Description,
                    Price = f.Price,
                    ImageUrl = f.ImageUrl,
                    CategoryId = f.CategoryId,
                    RestaurantId = f.RestaurantId,
                    Rating = f.Rating,
                    Category = f.Category,
                    IsAvailable = f.IsAvailable,
                    CreatedDate = f.CreatedDate
                })
                .ToListAsync();

            return menu ?? new List<FoodItem>();
        }

        // POST: api/Restaurants/{id}/menu
        [HttpPost("{id}/menu")]
        public async Task<ActionResult<FoodItem>> AddMenuItem(int id, FoodItem item)
        {
            var restaurant = await _context.Restaurants.FindAsync(id);
            if (restaurant == null) return NotFound("Restaurant not found");

            item.RestaurantId = id;
            if (item.CategoryId == 0) item.CategoryId = 1; // Default category if not provided
            
            _context.FoodItems.Add(item);
            await _context.SaveChangesAsync();

            return Ok(item);
        }

        // GET: api/Restaurants/recommend
        [HttpGet("recommend")]
        public async Task<ActionResult<IEnumerable<Restaurant>>> GetRecommendedRestaurants([FromQuery] int userId, [FromQuery] double lat, [FromQuery] double lng)
        {
            var allRestaurants = await _context.Restaurants.ToListAsync();
            var nearbyRestaurants = allRestaurants
                .Where(r => CalculateDistance(lat, lng, r.Latitude, r.Longitude) <= 10.0)
                .ToList();

            if (!nearbyRestaurants.Any()) return Ok(new List<Restaurant>());

            var aiEngine = new AICore.RecommendationEngine();
            var topIds = await aiEngine.PredictTopN(userId, lat, lng, 10);

            if (topIds == null || topIds.Length == 0)
            {
                return nearbyRestaurants.OrderBy(r => CalculateDistance(lat, lng, r.Latitude, r.Longitude)).Take(10).ToList();
            }

            return nearbyRestaurants.Where(r => topIds.Contains(r.Id)).ToList();
        }

        // 1. Gợi ý quán gần nhất (Bán kính 10km)
        [HttpGet("map/nearby")]
        public async Task<ActionResult<IEnumerable<Restaurant>>> GetNearby([FromQuery] double lat, [FromQuery] double lng)
        {
            var restaurants = await _context.Restaurants.ToListAsync();
            var nearby = restaurants
                .Where(r => CalculateDistance(lat, lng, r.Latitude, r.Longitude) <= 10.0)
                .OrderBy(r => CalculateDistance(lat, lng, r.Latitude, r.Longitude))
                .Take(20)
                .ToList();
            return Ok(nearby);
        }

        // 2. Gợi ý theo thói quen & Khung giờ
        [HttpGet("map/contextual")]
        public async Task<ActionResult<IEnumerable<Restaurant>>> GetContextual([FromQuery] int userId, [FromQuery] double lat, [FromQuery] double lng)
        {
            var hour = DateTime.Now.Hour;
            var restaurants = await _context.Restaurants.ToListAsync();
            var nearby = restaurants.Where(r => CalculateDistance(lat, lng, r.Latitude, r.Longitude) <= 15.0).ToList();

            // Logic gợi ý theo khung giờ (Simple Rule-based AI)
            IEnumerable<Restaurant> filtered;
            if (hour >= 6 && hour <= 10) // Sáng
                filtered = nearby.Where(r => r.Name.Contains("Phở") || r.Name.Contains("Bánh mì") || r.Name.Contains("Café") || r.Name.Contains("Coffee"));
            else if (hour >= 11 && hour <= 14) // Trưa
                filtered = nearby.Where(r => r.Name.Contains("Cơm") || r.Name.Contains("Bún"));
            else if (hour >= 17 && hour <= 21) // Tối
                filtered = nearby.Where(r => r.Name.Contains("BBQ") || r.Name.Contains("Lẩu") || r.Name.Contains("Nhà hàng"));
            else // Đêm
                filtered = nearby.Take(10);

            var result = filtered.OrderBy(r => Guid.NewGuid()).Take(15).ToList();
            if (!result.Any()) result = nearby.Take(10).ToList();

            return Ok(result);
        }

        // 3. Gợi ý quán tốt nên thử (Rating cao)
        [HttpGet("map/top-rated")]
        public async Task<ActionResult<IEnumerable<Restaurant>>> GetTopRated([FromQuery] double lat, [FromQuery] double lng)
        {
            var restaurants = await _context.Restaurants.ToListAsync();
            var topRated = restaurants
                .Where(r => r.Rating >= 4.5 && CalculateDistance(lat, lng, r.Latitude, r.Longitude) <= 20.0)
                .OrderByDescending(r => r.Rating)
                .Take(15)
                .ToList();
            return Ok(topRated);
        }

        // GET: api/Restaurants/by-category/{categoryName}
        [HttpGet("by-category/{categoryName}")]
        public async Task<ActionResult<IEnumerable<Restaurant>>> GetRestaurantsByCategory(string categoryName)
        {
            var restaurants = await _context.Restaurants
                .Where(r => _context.FoodItems.Any(f => f.RestaurantId == r.Id && f.Category!.Name == categoryName))
                .ToListAsync();

            if (restaurants == null || !restaurants.Any())
            {
                // Fallback: Try partial match or just return empty
                return Ok(new List<Restaurant>());
            }

            return restaurants;
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
            // 1. Lấy mã loại "Món Chính" động
            var mainCategory = await _context.Categories.FirstOrDefaultAsync(c => c.Name.Contains("Chính"));
            int catId = mainCategory?.Id ?? 1;

            if (await _context.Restaurants.AnyAsync()) 
            {
                 _context.FoodItems.RemoveRange(_context.FoodItems);
                 _context.Restaurants.RemoveRange(_context.Restaurants);
                 await _context.SaveChangesAsync();
            }

            // 2. Danh sách nhà hàng (Tập trung Thủ Đức - Nơi người dùng đang đứng)
            var testRestaurants = new List<Restaurant>
            {
                new Restaurant { Name = "Phở Gia Truyền - Bình Thái", Description = "Phở bò gia truyền 3 đời", Address = "68 Kha Vạn Cân, Thủ Đức", ImageUrl = "https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=500", Latitude = 10.840, Longitude = 106.760, OpeningHours = "06:00-22:00" },
                new Restaurant { Name = "Bún Bò Huế O Xuân - Thủ Đức", Description = "Bún bò Huế chuẩn vị", Address = "123 Võ Văn Ngân, Thủ Đức", ImageUrl = "https://images.unsplash.com/photo-1625398407796-82650a8c135f?w=500", Latitude = 10.850, Longitude = 106.770, OpeningHours = "07:00-22:00" },
                new Restaurant { Name = "Cơm Tấm Thuận Kiều - Thủ Đức", Description = "Cơm tấm Sài Gòn đặc biệt", Address = "Đặng Văn Bi, Thủ Đức", ImageUrl = "https://images.unsplash.com/photo-1606491956689-2ea84b725c81?w=500", Latitude = 10.842, Longitude = 106.762, OpeningHours = "06:00-21:00" },
                new Restaurant { Name = "Bánh Mì Huỳnh Hoa", Description = "Bánh mì trứ danh Sài Gòn", Address = "Lê Thị Riêng, Quận 1", ImageUrl = "https://images.unsplash.com/photo-1626074353765-517a681e40be?w=500", Latitude = 10.772, Longitude = 106.692, OpeningHours = "14:00-23:00" },
                new Restaurant { Name = "Hủ Tiếu Thành Đạt", Description = "Hủ tiếu Nam Vang", Address = "Quận 10, TP.HCM", ImageUrl = "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?q=80&w=500", Latitude = 10.774, Longitude = 106.669, OpeningHours = "24/24" }
            };

            _context.Restaurants.AddRange(testRestaurants);
            await _context.SaveChangesAsync();

            // 3. Nạp Menu cho từng quán (Đảm bảo ID khớp)
            var foodItems = new List<FoodItem>();
            foreach (var res in testRestaurants)
            {
                foodItems.Add(new FoodItem { 
                    Name = $"Món đặc sản tại {res.Name}", 
                    Description = "Hương vị truyền thống, nguyên liệu tươi ngon mỗi ngày.",
                    Price = (decimal)(45000 + (new Random().Next(1, 5) * 5000)), 
                    RestaurantId = res.Id, 
                    CategoryId = catId, 
                    ImageUrl = res.ImageUrl, 
                    IsAvailable = true 
                });
                
                foodItems.Add(new FoodItem { 
                    Name = "Phần Thêm Đặc Biệt", 
                    Description = "Thêm topping, hương vị đậm đà hơn.",
                    Price = 15000m, 
                    RestaurantId = res.Id, 
                    CategoryId = catId, 
                    ImageUrl = "https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?q=80&w=200", 
                    IsAvailable = true 
                });
            }

            _context.FoodItems.AddRange(foodItems);
            await _context.SaveChangesAsync();

            return Ok(new { message = $"Đã nạp {testRestaurants.Count} nhà hàng và {foodItems.Count} món ăn thành công!" });
        }
        // POST: api/Restaurants/seed-geojson
        [HttpPost("seed-geojson")]
        public async Task<IActionResult> SeedGeoJson()
        {
            var geoJsonPath = Path.Combine(Directory.GetCurrentDirectory(), "..", "..", "export.geojson");
            if (!System.IO.File.Exists(geoJsonPath)) return NotFound("Không tìm thấy file export.geojson");

            var mainCategory = await _context.Categories.FirstOrDefaultAsync(c => c.Name.Contains("Chính"));
            int catId = mainCategory?.Id ?? 1;

            try {
                var jsonString = await System.IO.File.ReadAllTextAsync(geoJsonPath);
                using var doc = JsonDocument.Parse(jsonString);
                var features = doc.RootElement.GetProperty("features");

                var newRestaurants = new List<Restaurant>();
                int count = 0;

                foreach (var feature in features.EnumerateArray())
                {
                    var props = feature.GetProperty("properties");
                    var geom = feature.GetProperty("geometry");
                    
                    if (props.TryGetProperty("name", out var nameProp))
                    {
                        string name = nameProp.GetString() ?? "";
                        var coords = geom.GetProperty("coordinates");
                        double lng = coords[0].GetDouble();
                        double lat = coords[1].GetDouble();

                        // Rules: Mở rộng vùng TP.HCM
                        if (lat < 10.2 || lat > 11.1 || lng < 106.2 || lng > 107.1) continue;

                        newRestaurants.Add(new Restaurant 
                        { 
                            Name = name, 
                            Description = $"Địa điểm ẩm thực uy tín tại TP.HCM", 
                            Address = "Hồ Chí Minh",
                            ImageUrl = GetRandomFoodImage(name),
                            Latitude = lat, Longitude = lng,
                            OpeningHours = "06:00-23:00"
                        });
                        count++;
                    }
                    if (count >= 500) break; // Nạp 500 quán cho cực kỳ phong phú
                }

                if (await _context.Restaurants.AnyAsync()) 
                {
                     _context.FoodItems.RemoveRange(_context.FoodItems);
                     _context.Restaurants.RemoveRange(_context.Restaurants);
                     await _context.SaveChangesAsync();
                }

                _context.Restaurants.AddRange(newRestaurants);
                await _context.SaveChangesAsync();

                // NẠP MENU PHONG PHÚ (Đảm bảo ID khớp 100%)
                var foodItems = new List<FoodItem>();
                foreach (var res in newRestaurants)
                {
                    var menu = GetMenuForRestaurant(res.Name);
                    foreach (var item in menu)
                    {
                        foodItems.Add(new FoodItem { 
                            Name = item.name, 
                            Description = "Nguyên liệu tươi sạch, chế biến trong ngày, hương vị đậm đà.",
                            Price = item.price, 
                            RestaurantId = res.Id, 
                            CategoryId = catId, 
                            ImageUrl = item.img, 
                            IsAvailable = true 
                        });
                    }
                    
                    // Thêm các món phụ
                    foodItems.Add(new FoodItem { Name = "Nước Giải Khát", Price = 15000m, RestaurantId = res.Id, CategoryId = catId, ImageUrl = "https://images.unsplash.com/photo-1544145945-f904253d0c7b?w=200", IsAvailable = true });
                    foodItems.Add(new FoodItem { Name = "Trái Cây Tráng Miệng", Price = 30000m, RestaurantId = res.Id, CategoryId = catId, ImageUrl = "https://images.unsplash.com/photo-1563729784474-d77dbb933a9e?w=200", IsAvailable = true });
                }
                
                _context.FoodItems.AddRange(foodItems);
                await _context.SaveChangesAsync();

                return Ok(new { message = $"Đã nạp thành công {newRestaurants.Count} nhà hàng TP.HCM và {foodItems.Count} món ăn vào Menu!" });
            }
            catch (Exception ex)
            {
                return BadRequest($"Lỗi: {ex.Message}");
            }
        }

        private string GetRandomFoodImage(string name) {
            if (name.Contains("BBQ") || name.Contains("Nướng")) return "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=500";
            if (name.Contains("Phở")) return "https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=500";
            if (name.Contains("Bún")) return "https://images.unsplash.com/photo-1625398407796-82650a8c135f?w=500";
            if (name.Contains("Coffee") || name.Contains("Cafe")) return "https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=500";
            return "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=500";
        }

        private List<(string name, decimal price, string img)> GetMenuForRestaurant(string resName) {
            var items = new List<(string name, decimal price, string img)>();
            string name = resName.ToLower();

            if (name.Contains("phở")) {
                items.Add(("Phở Bò Tái Nạm", 55000m, "https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=300"));
                items.Add(("Phở Đặc Biệt (Gân, Bò Viên)", 75000m, "https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=300"));
                items.Add(("Phở Gà Ta Thả Vườn", 50000m, "https://images.unsplash.com/photo-1625398407796-82650a8c135f?w=300"));
            } else if (name.Contains("bún") || name.Contains("mì")) {
                items.Add(("Bún Bò Huế (Giò, Chả, Nạm)", 65000m, "https://images.unsplash.com/photo-1588633906622-f95e2436b04f?w=300"));
                items.Add(("Bún Chả Hà Nội", 50000m, "https://images.unsplash.com/photo-1562967914-608f82629710?w=300"));
                items.Add(("Mì Quảng Gà", 45000m, "https://images.unsplash.com/photo-1512058564366-18510be2db19?w=300"));
            } else if (name.Contains("cơm")) {
                items.Add(("Cơm Tấm Sườn Bì Chả", 45000m, "https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=300"));
                items.Add(("Cơm Gà Xối Mỡ Giòn", 50000m, "https://images.unsplash.com/photo-1623961988350-66b064faf29f?w=300"));
                items.Add(("Cơm Chiên Dương Châu", 40000m, "https://images.unsplash.com/photo-1512058564366-18510be2db19?w=300"));
            } else if (name.Contains("bbq") || name.Contains("nướng")) {
                items.Add(("Dẻ Sườn Bò Nướng Tảng", 185000m, "https://images.unsplash.com/photo-1544025162-d76694265947?w=300"));
                items.Add(("Thịt Ba Chỉ Sốt Cay", 95000m, "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=300"));
                items.Add(("Lẩu Thái Tomyum", 250000m, "https://images.unsplash.com/photo-1547928521-d8a4367f08b8?w=300"));
            } else if (name.Contains("cafe") || name.Contains("coffee") || name.Contains("trà")) {
                items.Add(("Cà Phê Muối", 35000m, "https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=300"));
                items.Add(("Trà Đào Cam Sả", 45000m, "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=300"));
                items.Add(("Bạc Xỉu Sài Gòn", 32000m, "https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=300"));
            } else {
                items.Add(("Món Ngon Đặc Sản Quán", 85000m, "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=300"));
                items.Add(("Khai Vị Thập Cẩm", 55000m, "https://images.unsplash.com/photo-1541014741259-df549fa9bc27?w=300"));
                items.Add(("Tráng Miệng Trái Cây", 30000m, "https://images.unsplash.com/photo-1579954115545-a95591f28bee?w=300"));
            }
            return items;
        }
        // GET: api/Restaurants/item-mapping
        [HttpGet("item-mapping")]
        public async Task<ActionResult<Dictionary<string, List<int>>>> GetItemMapping()
        {
            var restaurants = await _context.Restaurants
                .Include(r => r.FoodItems)
                .ToListAsync();

            var mapping = new Dictionary<string, List<int>>();

            foreach (var res in restaurants)
            {
                foreach (var item in res.FoodItems)
                {
                    // Chuẩn hóa tên món để AI dễ nhận diện (ví dụ: "Phở Bò" -> "Pho")
                    string key = item.Name.ToLower();
                    if (key.Contains("phở")) key = "Pho";
                    else if (key.Contains("bún bò")) key = "Bun_bo_Hue";
                    else if (key.Contains("cơm tấm")) key = "Com_tam";
                    else if (key.Contains("bánh mì")) key = "Banh_mi";
                    else if (key.Contains("bbq") || key.Contains("nướng")) key = "BBQ";
                    else if (key.Contains("cafe") || key.Contains("coffee")) key = "Coffee";

                    if (!mapping.ContainsKey(key)) mapping[key] = new List<int>();
                    if (!mapping[key].Contains(res.Id)) mapping[key].Add(res.Id);
                }
            }

            return Ok(mapping);
        }
    }
}
