using System;
using System.Collections.Generic;

namespace Domain.Entities
{
    public class Order : BaseEntity
    {
        public int UserId { get; set; }
        public User? User { get; set; }
        
        public DateTime OrderDate { get; set; } = DateTime.UtcNow;
        public decimal TotalAmount { get; set; }
        public string Status { get; set; } = "Pending"; // Pending, Confirmed, Preparing, Delivering, Completed, Cancelled
        public string DeliveryAddress { get; set; } = string.Empty;

        // Thông tin người nhận (Flutter checkout gửi lên).
        public string ReceiverName { get; set; } = string.Empty;
        public string ReceiverPhone { get; set; } = string.Empty;

        // Toạ độ giao hàng (optional).
        public double? DeliveryLatitude { get; set; }
        public double? DeliveryLongitude { get; set; }

        // cod | ewallet | bank
        public string PaymentMethod { get; set; } = "cod";

        // Mã voucher đã áp dụng (nếu có).
        public string VoucherCode { get; set; } = string.Empty;

        public ICollection<OrderItem> OrderItems { get; set; } = new List<OrderItem>();
    }

    public class OrderItem : BaseEntity
    {
        public int OrderId { get; set; }
        public Order? Order { get; set; }
        
        public int FoodItemId { get; set; }
        public FoodItem? FoodItem { get; set; }
        
        public int Quantity { get; set; }
        public decimal UnitPrice { get; set; }
    }
}
