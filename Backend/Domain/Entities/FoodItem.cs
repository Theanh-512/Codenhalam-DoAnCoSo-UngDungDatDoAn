namespace Domain.Entities
{
    public class FoodItem : BaseEntity
    {
        public string Name { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public string ImageUrl { get; set; } = string.Empty;
        public double Rating { get; set; } = 5.0;
        public bool IsAvailable { get; set; } = true;
        public int CategoryId { get; set; }
        public Category? Category { get; set; }
        
        public int RestaurantId { get; set; }
        public Restaurant? Restaurant { get; set; }

        // Multi-modal Features (SCR Theory)
        public string? VisualFeatureVector { get; set; } // Giả lập vector trích xuất từ DenseNet201
        public string? TextualFeatureVector { get; set; } // Giả lập vector trích xuất từ BERT/RoBERTa
    }
}

