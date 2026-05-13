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
                return BadRequest("Keyword is required");
            }

            var keyword = q.ToLower();

            // Search in Restaurants
            var restaurants = await _context.Restaurants
                .Where(r => r.Name.ToLower().Contains(keyword) || (r.Description != null && r.Description.ToLower().Contains(keyword)))
                .ToListAsync();

            // Search in FoodItems
            var foodItems = await _context.FoodItems
                .Where(f => f.Name.ToLower().Contains(keyword) || (f.Description != null && f.Description.ToLower().Contains(keyword)))
                .ToListAsync();

            return Ok(new
            {
                Restaurants = restaurants,
                FoodItems = foodItems
            });
        }
    }
}
