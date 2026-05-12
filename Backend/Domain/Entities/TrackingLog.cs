using System;

namespace Domain.Entities
{
    public class TrackingLog : BaseEntity
    {
        public int? UserId { get; set; }
        public int RestaurantId { get; set; }
        public string? SessionId { get; set; } // Nhóm hành vi theo phiên (SCR Theory)
        
        // Behavioral data
        public string ActionType { get; set; } = string.Empty; 
        public double Latitude { get; set; }
        public double Longitude { get; set; }
        public DateTime Timestamp { get; set; } = DateTime.UtcNow;

        // Contextual features for SCR
        public int MealSlot => CalculateMealSlot(Timestamp); // 0-47 (SCR Theory: 48 slots/week)
        public string DeviceInfo { get; set; } = string.Empty;

        private int CalculateMealSlot(DateTime dt)
        {
            int hour = dt.Hour;
            bool isWeekend = dt.DayOfWeek == DayOfWeek.Saturday || dt.DayOfWeek == DayOfWeek.Sunday;
            return isWeekend ? hour + 24 : hour; // 0-23: Weekday, 24-47: Weekend
        }
    }

}
