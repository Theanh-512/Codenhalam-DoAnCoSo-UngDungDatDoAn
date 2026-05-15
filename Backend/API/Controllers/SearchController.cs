using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Infrastructure.Data;
using System.Threading.Tasks;
using System.Linq;

namespace API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class SearchController : ControllerBase
    {
        private readonly FoodAppDbContext _context;

        public SearchController(FoodAppDbContext context)
        {
            _context = context;
        }

        // GET: api/Search?q=keyword
        [HttpGet]
        public async Task<ActionResult> SearchFood([FromQuery] string q)
        {
            if (string.IsNullOrWhiteSpace(q))
            {
                return Ok(new { restaurants = System.Array.Empty<object>(), foodItems = System.Array.Empty<object>() });
            }

            var keyword = q.Trim();

            var restaurants = await _context.Restaurants
                .AsNoTracking()
                .Where(r => r.IsActive && (
                    EF.Functions.ILike(r.Name, $"%{keyword}%")
                    || EF.Functions.ILike(r.Description ?? "", $"%{keyword}%")
                    || EF.Functions.ILike(r.Type1 ?? "", $"%{keyword}%")
                    || EF.Functions.ILike(r.Type2 ?? "", $"%{keyword}%")))
                .OrderBy(r => r.Name)
                .Take(20)
                .Select(r => new
                {
                    id = r.Id,
                    name = r.Name ?? "",
                    description = r.Description ?? "",
                    imageUrl = r.ImageUrl ?? "",
                    type1 = r.Type1 ?? "",
                    type2 = r.Type2 ?? "",
                    latitude = r.Latitude,
                    longitude = r.Longitude,
                    openingHours = r.OpeningHours ?? "",
                    isActive = r.IsActive,
                })
                .ToListAsync();

            var foodItems = await _context.FoodItems
                .AsNoTracking()
                .Where(f => f.IsAvailable && (
                    EF.Functions.ILike(f.Name, $"%{keyword}%")
                    || EF.Functions.ILike(f.Description ?? "", $"%{keyword}%")
                    || EF.Functions.ILike(f.Category!.Name, $"%{keyword}%")))
                .OrderBy(f => f.Name)
                .Take(50)
                .Select(f => new
                {
                    id = f.Id,
                    name = f.Name ?? "",
                    description = f.Description ?? "",
                    price = f.Price,
                    imageUrl = f.ImageUrl ?? "",
                    restaurantId = f.RestaurantId,
                    isAvailable = f.IsAvailable,
                    categoryId = f.CategoryId,
                    category = f.Category != null ? f.Category.Name : "",
                })
                .ToListAsync();

            return Ok(new
            {
                restaurants,
                foodItems
            });
        }
    }
}
