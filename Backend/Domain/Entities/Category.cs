using System.Collections.Generic;

namespace Domain.Entities
{
    public class Category : BaseEntity
    {
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string? ImageUrl { get; set; }
        public ICollection<FoodItem> FoodItems { get; set; } = new List<FoodItem>();
    }
}
