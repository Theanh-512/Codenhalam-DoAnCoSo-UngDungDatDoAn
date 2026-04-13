using System.Collections.Generic;

namespace Domain.Entities
{
    public class User : BaseEntity
    {
        public string Email { get; set; } = string.Empty;
        public string PasswordHash { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public string PhoneNumber { get; set; } = string.Empty;
        public string Address { get; set; } = string.Empty;
        
        // For AI/Location tracking
        public double? LastLatitude { get; set; }
        public double? LastLongitude { get; set; }

        public ICollection<Order> Orders { get; set; } = new List<Order>();
    }
}
