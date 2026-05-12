using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Infrastructure.Data;
using Domain.Entities;
using AICore;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Linq;
using System;

namespace API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class RecommendationsController : ControllerBase
    {
        private readonly FoodAppDbContext _context;
        private readonly RecommendationEngine _engine;

        public RecommendationsController(FoodAppDbContext context, RecommendationEngine engine)
        {
            _context = context;
            _engine = engine;
        }

        [HttpGet("{userId}")]
        public async Task<IActionResult> GetRecommendations(int userId, [FromQuery] int topN = 5)
        {
            try
            {
                // Lấy 50 log gần nhất của người dùng để phân tích sở thích
                var userLogs = await _context.TrackingLogs
                    .Where(t => t.UserId == userId)
                    .OrderByDescending(t => t.Timestamp)
                    .Take(50)
                    .ToListAsync();

                // Lấy danh sách ID nhà hàng gợi ý từ Engine
                var recommendedIds = _engine.GetTopNRestaurants(userId, userLogs, null, topN);
                
                // Nếu chưa có lịch sử (người dùng mới), trả về nhà hàng phổ biến nhất dựa trên tracking logs chung
                if (!recommendedIds.Any())
                {
                    recommendedIds = await _context.TrackingLogs
                        .GroupBy(t => t.RestaurantId)
                        .OrderByDescending(g => g.Count())
                        .Take(topN)
                        .Select(g => g.Key)
                        .ToListAsync();
                }

                // Lấy thông tin chi tiết các nhà hàng
                var restaurants = await _context.Restaurants
                    .Where(r => recommendedIds.Contains(r.Id))
                    .ToListAsync();

                // 5. LLM Reranker & Explainability (SCR Framework)
                // Giả lập LLM phân tích ngữ cảnh để tinh chỉnh thứ tự và đưa ra lời giải thích
                var finalResults = recommendedIds
                    .Select(id => restaurants.FirstOrDefault(r => r.Id == id))
                    .Where(r => r != null)
                    .Select(r => new {
                        Restaurant = r,
                        Explanation = GetAiExplanation(r!.Name, userLogs.Any() ? userLogs.First().ActionType : "Popular")
                    })
                    .ToList();

                return Ok(new {
                    userId,
                    framework = "SCR (Improved Deep Sequential Model)",
                    algorithm = userLogs.Any() ? "Long-term & Short-term Sequential Fusion" : "Popularity-based (Fallback)",
                    recommendations = finalResults,
                    generatedAt = DateTime.UtcNow,
                    note = "Dữ liệu được tối ưu hóa bởi Multi-head Attention và Spatio-temporal Context."
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Lỗi xử lý gợi ý AI theo khung lý thuyết SCR: {ex.Message}");
            }
        }

        private string GetAiExplanation(string restaurantName, string lastAction)
        {
            var hour = DateTime.Now.Hour;
            string timeContext = hour < 11 ? "bữa sáng" : (hour < 15 ? "bữa trưa" : (hour < 19 ? "bữa chiều" : "bữa tối"));
            
            return lastAction switch {
                "AddToCart" => $"Dựa trên việc bạn vừa thêm món vào giỏ hàng, chúng tôi gợi ý {restaurantName} cho {timeContext} này.",
                "View" => $"Bạn vừa xem các món tương tự, {restaurantName} có thực đơn phù hợp với sở thích hiện tại của bạn.",
                _ => $"{restaurantName} là lựa chọn phổ biến nhất trong khu vực của bạn vào {timeContext}."
            };
        }
    }
}

