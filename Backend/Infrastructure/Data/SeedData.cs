using Domain.Entities;
using Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Infrastructure.Data
{
    public static class SeedData
    {
        public static async Task InitializeAsync(FoodAppDbContext context)
        {
            // Apply any pending migrations automatically when the app starts
            if (context.Database.IsRelational())
            {
                await context.Database.MigrateAsync();
            }

            // Seed Users if empty
            if (!await context.Users.AnyAsync())
            {
                var users = new List<User>
                {
                    new User { Email = "admin@foodapp.com", FullName = "Admin Hệ Thống", PasswordHash = "123456", PhoneNumber = "0999999999", CreatedDate = System.DateTime.UtcNow },
                    new User { Email = "test1@gmail.com", FullName = "Nguyễn Văn A", PasswordHash = "123456", PhoneNumber = "0123456781", CreatedDate = System.DateTime.UtcNow },
                };
                context.Users.AddRange(users);
                await context.SaveChangesAsync();
            }

            // Seed Restaurants if empty
            if (!await context.Restaurants.AnyAsync())
            {
                var restaurants = new List<Restaurant>
                {
                    new Restaurant 
                    { 
                        Name = "Phở Thìn Lò Đúc", 
                        Description = "Phở truyền thống nổi tiếng Hà Nội", 
                        Address = "13 Lò Đúc, Hai Bà Trưng, Hà Nội",
                        ImageUrl = "https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=500",
                        Latitude = 21.018, Longitude = 105.856,
                        OpeningHours = "06:00-21:00",
                        IsActive = true,
                        CreatedDate = System.DateTime.UtcNow
                    },
                    new Restaurant 
                    { 
                        Name = "Pizza 4P's", 
                        Description = "Pizza nướng lò củi phong cách Nhật", 
                        Address = "Tràng Tiền, Hoàn Kiếm, Hà Nội",
                        ImageUrl = "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500",
                        Latitude = 21.025, Longitude = 105.853,
                        OpeningHours = "10:00-22:00",
                        IsActive = true,
                        CreatedDate = System.DateTime.UtcNow
                    },
                    new Restaurant 
                    { 
                        Name = "Bún Chả Hương Liên", 
                        Description = "Bún chả Obama nổi tiếng", 
                        Address = "24 Lê Văn Hưu, Hai Bà Trưng, Hà Nội",
                        ImageUrl = "https://images.unsplash.com/photo-1541529086526-db283c563270?w=500",
                        Latitude = 21.019, Longitude = 105.848,
                        OpeningHours = "08:00-20:00",
                        IsActive = true,
                        CreatedDate = System.DateTime.UtcNow
                    }
                };
                context.Restaurants.AddRange(restaurants);
                await context.SaveChangesAsync();
            }
        }
    }
}
