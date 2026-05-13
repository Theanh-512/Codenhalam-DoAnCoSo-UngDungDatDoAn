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
    public class FoodItemsController : ControllerBase
    {
        private readonly FoodAppDbContext _context;

        public FoodItemsController(FoodAppDbContext context)
        {
            _context = context;
        }

        // GET: api/FoodItems
        [HttpGet]
        public async Task<ActionResult<IEnumerable<FoodItem>>> GetFoodItems([FromQuery] int? categoryId, [FromQuery] int? restaurantId)
        {
            var query = _context.FoodItems.AsQueryable();

            if (categoryId.HasValue)
            {
                query = query.Where(f => f.CategoryId == categoryId.Value);
            }

            if (restaurantId.HasValue)
            {
                query = query.Where(f => f.RestaurantId == restaurantId.Value);
            }

            return await query.ToListAsync();
        }

        // GET: api/FoodItems/{id}
        [HttpGet("{id}")]
        public async Task<ActionResult<FoodItem>> GetFoodItem(int id)
        {
            var item = await _context.FoodItems.FindAsync(id);
            if (item == null) return NotFound();
            return item;
        }

        // POST: api/FoodItems
        [HttpPost]
        public async Task<ActionResult<FoodItem>> PostFoodItem(FoodItem item)
        {
            _context.FoodItems.Add(item);
            await _context.SaveChangesAsync();
            return CreatedAtAction(nameof(GetFoodItem), new { id = item.Id }, item);
        }

        // PUT: api/FoodItems/{id}
        [HttpPut("{id}")]
        public async Task<IActionResult> PutFoodItem(int id, FoodItem item)
        {
            if (id != item.Id) return BadRequest();

            _context.Entry(item).State = EntityState.Modified;
            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!await _context.FoodItems.AnyAsync(e => e.Id == id)) return NotFound();
                else throw;
            }
            return NoContent();
        }

        // DELETE: api/FoodItems/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteFoodItem(int id)
        {
            var item = await _context.FoodItems.FindAsync(id);
            if (item == null) return NotFound();

            _context.FoodItems.Remove(item);
            await _context.SaveChangesAsync();
            return NoContent();
        }
    }
}
