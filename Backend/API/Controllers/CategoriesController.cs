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
    public class CategoriesController : ControllerBase
    {
        private readonly FoodAppDbContext _context;

        public CategoriesController(FoodAppDbContext context)
        {
            _context = context;
        }

        // GET: api/Categories
        [HttpGet]
        public async Task<ActionResult<IEnumerable<object>>> GetCategories()
        {
            var categories = await _context.Categories
                .Select(c => new {
                    id = c.Id,
                    name = c.Name,
                    description = c.Description,
                    imageUrl = c.ImageUrl,
                    items_count = c.FoodItems.Count()
                })
                .ToListAsync();
            return Ok(categories);
        }

        // GET: api/Categories/{id}
        [HttpGet("{id}")]
        public async Task<ActionResult<Category>> GetCategory(int id)
        {
            var category = await _context.Categories.FindAsync(id);
            if (category == null) return NotFound();
            return category;
        }

        // POST: api/Categories
        [HttpPost]
        public async Task<ActionResult<Category>> PostCategory(Category category)
        {
            _context.Categories.Add(category);
            await _context.SaveChangesAsync();
            return CreatedAtAction(nameof(GetCategory), new { id = category.Id }, category);
        }

        // PUT: api/Categories/{id}
        [HttpPut("{id}")]
        public async Task<IActionResult> PutCategory(int id, Category category)
        {
            if (id != category.Id) return BadRequest();

            _context.Entry(category).State = EntityState.Modified;
            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!await _context.Categories.AnyAsync(e => e.Id == id)) return NotFound();
                else throw;
            }
            return NoContent();
        }

        // DELETE: api/Categories/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteCategory(int id)
        {
            var category = await _context.Categories.FindAsync(id);
            if (category == null) return NotFound();

            _context.Categories.Remove(category);
            await _context.SaveChangesAsync();
            return NoContent();
        }

        // POST: api/Categories/seed
        [HttpPost("seed")]
        public async Task<IActionResult> SeedCategories()
        {
            if (await _context.Categories.AnyAsync()) return BadRequest("Categories already exist");

            var categories = new List<Category>
            {
                new Category { Name = "Món Chính", Description = "Các món ăn no, chính trong bữa", ImageUrl = "https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=200" },
                new Category { Name = "Khai Vị", Description = "Các món ăn nhẹ đầu bữa", ImageUrl = "https://images.unsplash.com/photo-1541529086526-db283c563270?w=200" },
                new Category { Name = "Tráng Miệng", Description = "Đồ ngọt, trái cây", ImageUrl = "https://images.unsplash.com/photo-1563729784474-d77dbb933a9e?w=200" },
                new Category { Name = "Đồ Uống", Description = "Nước giải khát, trà, cafe", ImageUrl = "https://images.unsplash.com/photo-1544145945-f904253d0c7b?w=200" }
            };

            _context.Categories.AddRange(categories);
            await _context.SaveChangesAsync();

            return Ok("Đã nạp 4 danh mục thành công!");
        }
    }
}
