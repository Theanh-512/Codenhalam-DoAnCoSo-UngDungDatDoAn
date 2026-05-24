using System;
using System.Collections.Generic;
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
    public class OrdersController : ControllerBase
    {
        private readonly FoodAppDbContext _context;

        public OrdersController(FoodAppDbContext context)
        {
            _context = context;
        }

        // GET /api/Orders - dành cho admin lấy toàn bộ đơn.
        [Authorize(Roles = "Admin")]
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Order>>> GetOrders()
            => await _context.Orders.AsNoTracking().OrderByDescending(o => o.OrderDate).ToListAsync();

        /// <summary>Tạo đơn hàng. Yêu cầu JWT hợp lệ.</summary>
        [Authorize]
        [HttpPost]
        public async Task<ActionResult<Order>> CreateOrder([FromBody] CreateOrderRequest request)
        {
            var userId = CurrentUser.GetUserId(User);
            if (userId == null) return Unauthorized();

            var user = await _context.Users.FindAsync(userId.Value);
            if (user == null) return Unauthorized(new { message = "Người dùng không tồn tại" });

            if (request.Items == null || request.Items.Count == 0)
                return BadRequest(new { message = "Đơn hàng phải có ít nhất 1 món" });

            decimal totalAmount = 0;
            var rawTotal = request.Total_Price ?? request.TotalAmount;
            if (rawTotal != null) decimal.TryParse(rawTotal.ToString(), out totalAmount);

            var address = request.Delivery_Address ?? request.DeliveryAddress ?? user.Address ?? "";
            var receiverName = request.Receiver_Name ?? request.ReceiverName ?? user.FullName ?? "";
            var receiverPhone = request.Receiver_Phone ?? request.ReceiverPhone ?? user.PhoneNumber ?? "";
            var paymentMethod = (request.Payment_Method ?? request.PaymentMethod ?? "cod").Trim().ToLowerInvariant();
            var voucherCode = (request.Voucher_Code ?? request.VoucherCode ?? "").Trim().ToUpperInvariant();

            var order = new Order
            {
                UserId = user.Id,
                TotalAmount = totalAmount,
                DeliveryAddress = address,
                ReceiverName = receiverName,
                ReceiverPhone = receiverPhone,
                DeliveryLatitude = request.Delivery_Lat,
                DeliveryLongitude = request.Delivery_Lng,
                PaymentMethod = paymentMethod,
                VoucherCode = voucherCode,
                OrderDate = DateTime.UtcNow,
                Status = "Pending",
            };
            _context.Orders.Add(order);
            await _context.SaveChangesAsync();

            foreach (var item in request.Items)
            {
                int foodItemId = 0;
                var rawFoodId = item.MenuItemId ?? item.FoodItemId;
                if (rawFoodId != null) int.TryParse(rawFoodId.ToString(), out foodItemId);
                if (foodItemId == 0) continue;

                int quantity = 1;
                if (item.Quantity != null) int.TryParse(item.Quantity.ToString(), out quantity);
                if (quantity <= 0) quantity = 1;

                decimal unitPrice = 0;
                var rawPrice = item.Price ?? item.UnitPrice;
                if (rawPrice != null) decimal.TryParse(rawPrice.ToString(), out unitPrice);

                _context.OrderItems.Add(new OrderItem
                {
                    OrderId = order.Id,
                    FoodItemId = foodItemId,
                    Quantity = quantity,
                    UnitPrice = unitPrice,
                });
            }
            await _context.SaveChangesAsync();

            return StatusCode(201, new
            {
                message = "Đặt hàng thành công!",
                orderId = order.Id,
                status = order.Status,
                total = order.TotalAmount,
            });
        }

        /// <summary>Lấy lịch sử đơn của user. Chỉ chính chủ hoặc admin xem được.</summary>
        [Authorize]
        [HttpGet("user/{userId}")]
        public async Task<ActionResult<IEnumerable<Order>>> GetUserOrders(int userId)
        {
            var me = CurrentUser.GetUserId(User);
            if (me == null) return Unauthorized();
            if (me.Value != userId && !User.IsInRole("Admin")) return Forbid();

            var orders = await _context.Orders
                .AsNoTracking()
                .Include(o => o.OrderItems)
                .ThenInclude(oi => oi.FoodItem)
                .Where(o => o.UserId == userId)
                .OrderByDescending(o => o.OrderDate)
                .ToListAsync();

            return orders;
        }

        /// <summary>Tối ưu lộ trình giao hàng (Greedy TSP). Chỉ admin/shipper.</summary>
        [Authorize(Roles = "Admin,Shipper")]
        [HttpGet("optimize-route")]
        public ActionResult GetOptimizedDeliveryRoute()
        {
            var deliveries = new List<AICore.RouteOptimizer.GeoLocation>
            {
                new() { OrderId = 1, Address = "Ký túc xá Bách Khoa", Lat = 21.0041, Lng = 105.8458 },
                new() { OrderId = 2, Address = "Time City", Lat = 20.9958, Lng = 105.8679 },
                new() { OrderId = 3, Address = "Vincom Phạm Ngọc Thạch", Lat = 21.0064, Lng = 105.8329 },
                new() { OrderId = 4, Address = "Royal City", Lat = 21.0028, Lng = 105.8152 },
            };
            var startLocation = new AICore.RouteOptimizer.GeoLocation
            {
                OrderId = 0, Address = "Nhà Hàng Gốc", Lat = 21.0285, Lng = 105.8542,
            };
            var optimizer = new AICore.RouteOptimizer();
            var optimizedPath = optimizer.GetOptimizedRoute(startLocation, deliveries);
            return Ok(new
            {
                Status = "Đã tối ưu",
                AlgorithmUsed = "Greedy Algorithm (TSP heuristic)",
                StartLocation = startLocation,
                OptimizedRoute = optimizedPath,
            });
        }
    }

    public class CreateOrderRequest
    {
        public object? UserId { get; set; }
        public object? TotalAmount { get; set; }
        public object? Total_Price { get; set; }
        public string? DeliveryAddress { get; set; }
        public string? Delivery_Address { get; set; }
        public string? ReceiverName { get; set; }
        public string? Receiver_Name { get; set; }
        public string? ReceiverPhone { get; set; }
        public string? Receiver_Phone { get; set; }
        public double? Delivery_Lat { get; set; }
        public double? Delivery_Lng { get; set; }
        public string? PaymentMethod { get; set; }
        public string? Payment_Method { get; set; }
        public string? VoucherCode { get; set; }
        public string? Voucher_Code { get; set; }
        public List<CreateOrderItemRequest> Items { get; set; } = new();
    }

    public class CreateOrderItemRequest
    {
        public object? FoodItemId { get; set; }
        public object? MenuItemId { get; set; }
        public object? Quantity { get; set; }
        public object? UnitPrice { get; set; }
        public object? Price { get; set; }
    }
}
