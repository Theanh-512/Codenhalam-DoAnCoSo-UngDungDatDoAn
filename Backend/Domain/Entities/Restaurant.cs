using System.Collections.Generic;

namespace Domain.Entities
{
    public class Restaurant : BaseEntity
    {
        public string Name { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public string Address { get; set; } = string.Empty;
        public string ImageUrl { get; set; } = string.Empty;
        
        // Location-Based properties
        public double Latitude { get; set; }
        public double Longitude { get; set; }
        
        public string OpeningHours { get; set; } = string.Empty; // e.g., "08:00-22:00"
        public bool IsActive { get; set; } = true;

        public ICollection<FoodItem> FoodItems { get; set; } = new List<FoodItem>();
    }
}
