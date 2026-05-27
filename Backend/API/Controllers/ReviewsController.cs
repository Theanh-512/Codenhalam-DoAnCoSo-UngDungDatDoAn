using System;
using System.Linq;
using System.Threading.Tasks;
using API.Auth;
using Domain.Entities;
using Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ReviewsController : ControllerBase
    {
        private readonly FoodAppDbContext _context;

        public ReviewsController(FoodAppDbContext context)
        {
            _context = context;
        }

        public class CreateReviewRequest
        {
            public int RestaurantId { get; set; }
            public int? OrderId { get; set; }
            public int Rating { get; set; }
            public string? Comment { get; set; }
        }

        /// <summary>
        /// Tạo review cho 1 nhà hàng. Khi save xong sẽ cập nhật
        /// Restaurants.Rating (trung bình tất cả review) + ReviewCount.
        /// </summary>
        [Authorize]
        [HttpPost]
        public async Task<ActionResult> Create([FromBody] CreateReviewRequest req)
        {
            var userId = CurrentUser.GetUserId(User);
            if (userId == null) return Unauthorized();

            if (req.RestaurantId <= 0)
                return BadRequest(new { message = "RestaurantId không hợp lệ" });
            if (req.Rating < 1 || req.Rating > 5)
                return BadRequest(new { message = "Rating phải từ 1 đến 5 sao" });

            var restaurant = await _context.Restaurants.FindAsync(req.RestaurantId);
            if (restaurant == null)
                return NotFound(new { message = "Không tìm thấy nhà hàng" });

            var review = new Review
            {
                UserId = userId.Value,
                RestaurantId = req.RestaurantId,
                OrderId = req.OrderId,
                Rating = req.Rating,
                Comment = (req.Comment ?? string.Empty).Trim(),
                CreatedDate = DateTime.UtcNow,
            };
            _context.Reviews.Add(review);
            await _context.SaveChangesAsync();

            // Cập nhật điểm trung bình + số lượng review cho nhà hàng.
            var stats = await _context.Reviews
                .Where(r => r.RestaurantId == req.RestaurantId)
                .GroupBy(r => r.RestaurantId)
                .Select(g => new { Avg = g.Average(r => (double)r.Rating), Count = g.Count() })
                .FirstOrDefaultAsync();
            if (stats != null)
            {
                restaurant.Rating = Math.Round(stats.Avg, 2);
                restaurant.ReviewCount = stats.Count;
                restaurant.UpdatedDate = DateTime.UtcNow;
                await _context.SaveChangesAsync();
            }

            return StatusCode(201, new
            {
                message = "Cảm ơn đánh giá của bạn!",
                reviewId = review.Id,
                restaurantRating = restaurant.Rating,
                restaurantReviewCount = restaurant.ReviewCount,
            });
        }

        /// <summary>Lấy tất cả review của 1 nhà hàng.</summary>
        [HttpGet("restaurant/{restaurantId}")]
        public async Task<ActionResult> GetByRestaurant(int restaurantId)
        {
            var list = await _context.Reviews
                .AsNoTracking()
                .Include(r => r.User)
                .Where(r => r.RestaurantId == restaurantId)
                .OrderByDescending(r => r.CreatedDate)
                .Select(r => new
                {
                    id = r.Id,
                    rating = r.Rating,
                    comment = r.Comment,
                    createdDate = r.CreatedDate,
                    userId = r.UserId,
                    userName = r.User != null ? r.User.FullName : "Ẩn danh",
                })
                .ToListAsync();
            return Ok(list);
        }
    }
}
