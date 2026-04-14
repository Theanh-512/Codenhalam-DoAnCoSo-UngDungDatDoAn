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

            // Seed Categories if empty
            if (!await context.Categories.AnyAsync())
            {
                var categories = new List<Category>
                {
                    new Category { Name = "Phở", Description = "Các loại phở truyền thống", CreatedDate = System.DateTime.UtcNow },
                    new Category { Name = "Pizza & Đồ Âu", Description = "Pizza, mỳ Ý và đồ nướng", CreatedDate = System.DateTime.UtcNow },
                    new Category { Name = "Bún & Phở", Description = "Bún, miến, phở các loại", CreatedDate = System.DateTime.UtcNow }
                };
                context.Categories.AddRange(categories);
                await context.SaveChangesAsync();
            }

            // Seed FoodItems if empty
            if (!await context.FoodItems.AnyAsync())
            {
                var phoStore = await context.Restaurants.FirstOrDefaultAsync(r => r.Name == "Phở Thìn Lò Đúc");
                var pizzaStore = await context.Restaurants.FirstOrDefaultAsync(r => r.Name == "Pizza 4P's");
                var bunChaStore = await context.Restaurants.FirstOrDefaultAsync(r => r.Name == "Bún Chả Hương Liên");
                var catPho = await context.Categories.FirstOrDefaultAsync(c => c.Name == "Phở");
                var catPizza = await context.Categories.FirstOrDefaultAsync(c => c.Name == "Pizza & Đồ Âu");
                var catBun = await context.Categories.FirstOrDefaultAsync(c => c.Name == "Bún & Phở");

                if (phoStore != null && pizzaStore != null && bunChaStore != null && catPho != null && catPizza != null && catBun != null)
                {
                    var foodItems = new List<FoodItem>
                    {
                        new FoodItem { Name = "Phở Bò Tái Lăn", Description = "Đặc sản Phở Thìn nhiều hành", Price = 70000, CategoryId = catPho.Id, RestaurantId = phoStore.Id, ImageUrl = "https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=500", CreatedDate = System.DateTime.UtcNow },
                        new FoodItem { Name = "Phở Bò Chín", Description = "Thơm ngon nước thanh", Price = 65000, CategoryId = catPho.Id, RestaurantId = phoStore.Id, ImageUrl = "https://images.unsplash.com/photo-1626804475297-41609ea8eb4b?w=500", CreatedDate = System.DateTime.UtcNow },
                        
                        new FoodItem { Name = "Pizza Half-Half", Description = "Phô mai Burrata & Thịt nguội", Price = 250000, CategoryId = catPizza.Id, RestaurantId = pizzaStore.Id, ImageUrl = "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500", CreatedDate = System.DateTime.UtcNow },
                        new FoodItem { Name = "Mì Ý Cua", Description = "Mì Ý tôm cua sốt kem rong biển", Price = 180000, CategoryId = catPizza.Id, RestaurantId = pizzaStore.Id, ImageUrl = "https://images.unsplash.com/photo-1516100882582-96c3a05fe590?w=500", CreatedDate = System.DateTime.UtcNow },
                        
                        new FoodItem { Name = "Bún Chả Nem Cua Bể", Description = "Suất Obama đầy đủ", Price = 90000, CategoryId = catBun.Id, RestaurantId = bunChaStore.Id, ImageUrl = "https://images.unsplash.com/photo-1541529086526-db283c563270?w=500", CreatedDate = System.DateTime.UtcNow },
                        new FoodItem { Name = "Bún Chả Thường", Description = "Chả băm và chả miếng", Price = 50000, CategoryId = catBun.Id, RestaurantId = bunChaStore.Id, ImageUrl = "https://images.unsplash.com/photo-1596704177526-66380c2f30b9?w=500", CreatedDate = System.DateTime.UtcNow }
                    };
                    context.FoodItems.AddRange(foodItems);
                    await context.SaveChangesAsync();
                }
            }
        }
    }
}
