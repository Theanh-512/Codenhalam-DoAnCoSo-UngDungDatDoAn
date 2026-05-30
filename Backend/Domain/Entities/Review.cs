using System;

namespace Domain.Entities
{
    /// <summary>
    /// Đánh giá của user dành cho một nhà hàng. Mỗi user có thể đánh giá
    /// nhiều lần (mỗi đơn hoàn tất → 1 review). Rating thang 1-5 sao.
    /// SentimentScore dùng cho phân tích AI (range 0-1), null nếu chưa
    /// chạy pipeline NLP.
    /// </summary>
    public class Review : BaseEntity
    {
        public int UserId { get; set; }
        public User? User { get; set; }

        public int RestaurantId { get; set; }
        public Restaurant? Restaurant { get; set; }

        /// <summary>OrderId là optional — review có thể đến từ đơn hoặc free-form.</summary>
        public int? OrderId { get; set; }

        public int Rating { get; set; } = 5; // 1..5
        public string Comment { get; set; } = string.Empty;

        public double? SentimentScore { get; set; }
    }
}
