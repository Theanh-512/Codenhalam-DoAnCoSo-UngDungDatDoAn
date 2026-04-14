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
    public class OrdersController : ControllerBase
    {
        private readonly FoodAppDbContext _context;

        public OrdersController(FoodAppDbContext context)
        {
            _context = context;
        }

        // POST: api/Orders
        [HttpPost]
        public async Task<ActionResult<Order>> CreateOrder([FromBody] CreateOrderRequest request)
        {
            var user = await _context.Users.FindAsync(request.UserId);
            if (user == null) return BadRequest("Người dùng không tồn tại");

            var order = new Order
            {
                UserId = request.UserId,
                TotalAmount = request.TotalAmount,
                DeliveryAddress = request.DeliveryAddress ?? user.Address,
                OrderDate = System.DateTime.UtcNow,
                Status = "Pending"
            };

            _context.Orders.Add(order);
            await _context.SaveChangesAsync();

            foreach (var item in request.Items)
            {
                _context.OrderItems.Add(new OrderItem
                {
                    OrderId = order.Id,
                    FoodItemId = item.FoodItemId,
                    Quantity = item.Quantity,
                    UnitPrice = item.UnitPrice
                });
            }
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đặt hàng thành công!", orderId = order.Id });
        }

        // GET: api/Orders/user/{userId}
        [HttpGet("user/{userId}")]
        public async Task<ActionResult<IEnumerable<Order>>> GetUserOrders(int userId)
        {
            var orders = await _context.Orders
                .Include(o => o.OrderItems)
                .ThenInclude(oi => oi.FoodItem)
                .Where(o => o.UserId == userId)
                .OrderByDescending(o => o.OrderDate)
                .ToListAsync();

            return orders;
        }

        // CHỨC NĂNG III: Tối ưu hóa lộ trình giao hàng (Greedy Algorithm)
        // GET: api/Orders/optimize-route
        [HttpGet("optimize-route")]
        public ActionResult GetOptimizedDeliveryRoute()
        {
            // Dummy Data - Giả lập 5 đơn hàng cần giao hôm nay
            var deliveries = new List<AICore.RouteOptimizer.GeoLocation>
            {
                new AICore.RouteOptimizer.GeoLocation { OrderId = 1, Address = "Ký túc xá Bách Khoa", Lat = 21.0041, Lng = 105.8458 },
                new AICore.RouteOptimizer.GeoLocation { OrderId = 2, Address = "Time City", Lat = 20.9958, Lng = 105.8679 },
                new AICore.RouteOptimizer.GeoLocation { OrderId = 3, Address = "Vincom Phạm Ngọc Thạch", Lat = 21.0064, Lng = 105.8329 },
                new AICore.RouteOptimizer.GeoLocation { OrderId = 4, Address = "Royal City", Lat = 21.0028, Lng = 105.8152 }
            };

            // Vị trí cửa hàng / Shipper xuất phát
            var startLocation = new AICore.RouteOptimizer.GeoLocation { OrderId = 0, Address = "Nhà Hàng Gốc", Lat = 21.0285, Lng = 105.8542 }; 

            var optimizer = new AICore.RouteOptimizer();
            var optimizedPath = optimizer.GetOptimizedRoute(startLocation, deliveries);

            return Ok(new {
                Status = "Đã tối ưu",
                AlgorithmUsed = "Greedy Algorithm (TSP heuristic)",
                StartLocation = startLocation,
                OptimizedRoute = optimizedPath
            });
        }
    }

    public class CreateOrderRequest
    {
        public int UserId { get; set; }
        public decimal TotalAmount { get; set; }
        public string DeliveryAddress { get; set; } = string.Empty;
        public List<CreateOrderItemRequest> Items { get; set; } = new();
    }

    public class CreateOrderItemRequest
    {
        public int FoodItemId { get; set; }
        public int Quantity { get; set; }
        public decimal UnitPrice { get; set; }
    }
}
