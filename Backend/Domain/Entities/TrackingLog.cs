using System;

namespace Domain.Entities
{
    public class TrackingLog : BaseEntity
    {
        public int? UserId { get; set; }
        public int RestaurantId { get; set; }
        
        // Behavioral data
        public string ActionType { get; set; } = string.Empty; // "Click", "View", "AddToCart"
        public double Latitude { get; set; }
        public double Longitude { get; set; }
        public DateTime Timestamp { get; set; } = DateTime.UtcNow;

        // Metadata for AI
        public string DeviceInfo { get; set; } = string.Empty;
    }
}
