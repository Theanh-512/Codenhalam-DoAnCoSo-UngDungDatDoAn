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
            // if (context.Database.IsRelational())
            // {
            //     await context.Database.MigrateAsync();
            // }

            // Seed Users if empty
            if (!await context.Users.AnyAsync())
            {
                var users = new List<User>
                {
                    new User { Email = "admin@gmail.com", FullName = "Admin Hệ Thống", PasswordHash = "Admin@123", PhoneNumber = "0999999999", UserRole = "Admin", CreatedDate = System.DateTime.UtcNow },
                    new User { Email = "test1@gmail.com", FullName = "Nguyễn Văn A", PasswordHash = "123456", PhoneNumber = "0123456781", UserRole = "User", CreatedDate = System.DateTime.UtcNow },
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
                        Name = "Nhà Hàng BBQ Chicken", 
                        Description = "Phục vụ các món Địa điểm ăn uống", 
                        Address = "Hồ Chí Minh",
                        ImageUrl = "https://images.unsplash.com/photo-1552566626-52f8b828add9?w=500",
                        Latitude = 10.768208, Longitude = 106.6841501,
                        OpeningHours = "08:00-22:00",
                        IsActive = true,
                        CreatedDate = System.DateTime.UtcNow
                    },
                    new Restaurant 
                    { 
                        Name = "Nhà Hàng Au Tresor", 
                        Description = "Phục vụ các món Địa điểm ăn uống", 
                        Address = "Hồ Chí Minh",
                        ImageUrl = "https://images.unsplash.com/photo-1552566626-52f8b828add9?w=500",
                        Latitude = 10.772698, Longitude = 106.7048299,
                        OpeningHours = "08:00-22:00",
                        IsActive = true,
                        CreatedDate = System.DateTime.UtcNow
                    },
                    new Restaurant 
                    { 
                        Name = "Nhà Hàng Bờ Sông", 
                        Description = "Phục vụ các món Địa điểm ăn uống", 
                        Address = "Hồ Chí Minh",
                        ImageUrl = "https://images.unsplash.com/photo-1552566626-52f8b828add9?w=500",
                        Latitude = 10.789502, Longitude = 106.711158,
                        OpeningHours = "08:00-22:00",
                        IsActive = true,
                        CreatedDate = System.DateTime.UtcNow
                    },
                    new Restaurant 
                    { 
                        Name = "Nhà Hàng Riverside Saigon", 
                        Description = "Phục vụ các món Địa điểm ăn uống", 
                        Address = "Hồ Chí Minh",
                        ImageUrl = "https://images.unsplash.com/photo-1552566626-52f8b828add9?w=500",
                        Latitude = 10.7728736, Longitude = 106.7062835,
                        OpeningHours = "08:00-22:00",
                        IsActive = true,
                        CreatedDate = System.DateTime.UtcNow
                    },
                    new Restaurant 
                    { 
                        Name = "Nhà Hàng Hai Lúa Sài Gòn", 
                        Description = "Phục vụ các món Địa điểm ăn uống", 
                        Address = "Hồ Chí Minh",
                        ImageUrl = "https://images.unsplash.com/photo-1552566626-52f8b828add9?w=500",
                        Latitude = 10.7807008, Longitude = 106.7067111,
                        OpeningHours = "08:00-22:00",
                        IsActive = true,
                        CreatedDate = System.DateTime.UtcNow
                    },
                    new Restaurant 
                    { 
                        Name = "Nhà Hàng Wrap&Roll", 
                        Description = "Phục vụ các món Địa điểm ăn uống", 
                        Address = "Hồ Chí Minh",
                        ImageUrl = "https://images.unsplash.com/photo-1552566626-52f8b828add9?w=500",
                        Latitude = 10.7732882, Longitude = 106.7040253,
                        OpeningHours = "08:00-22:00",
                        IsActive = true,
                        CreatedDate = System.DateTime.UtcNow
                    },
                    new Restaurant 
                    { 
                        Name = "Quán Ăn Gia Đình", 
                        Description = "Phục vụ các món Địa điểm ăn uống", 
                        Address = "Hồ Chí Minh",
                        ImageUrl = "https://images.unsplash.com/photo-1552566626-52f8b828add9?w=500",
                        Latitude = 10.8029924, Longitude = 106.6995844,
                        OpeningHours = "08:00-22:00",
                        IsActive = true,
                        CreatedDate = System.DateTime.UtcNow
                    },
                    new Restaurant 
                    { 
                        Name = "Nhà Hàng Đồ Chay", 
                        Description = "Phục vụ các món Địa điểm ăn uống", 
                        Address = "Hồ Chí Minh",
                        ImageUrl = "https://images.unsplash.com/photo-1552566626-52f8b828add9?w=500",
                        Latitude = 10.8062565, Longitude = 106.6949559,
                        OpeningHours = "08:00-22:00",
                        IsActive = true,
                        CreatedDate = System.DateTime.UtcNow
                    },
                    new Restaurant 
                    { 
                        Name = "Nhà Hàng Crazy Buffalo", 
                        Description = "Phục vụ các món Địa điểm ăn uống", 
                        Address = "Hồ Chí Minh",
                        ImageUrl = "https://images.unsplash.com/photo-1552566626-52f8b828add9?w=500",
                        Latitude = 10.767375, Longitude = 106.6941425,
                        OpeningHours = "08:00-22:00",
                        IsActive = true,
                        CreatedDate = System.DateTime.UtcNow
                    },
                    new Restaurant 
                    { 
                        Name = "Nhà Hàng Pizza Fixme", 
                        Description = "Phục vụ các món Địa điểm ăn uống", 
                        Address = "Hồ Chí Minh",
                        ImageUrl = "https://images.unsplash.com/photo-1552566626-52f8b828add9?w=500",
                        Latitude = 10.7680337, Longitude = 106.6938158,
                        OpeningHours = "08:00-22:00",
                        IsActive = true,
                        CreatedDate = System.DateTime.UtcNow
                    },
                    new Restaurant 
                    { 
                        Name = "Nhà Hàng Đồ Ăn Việt Nam Aroma", 
                        Description = "Phục vụ các món vietnamese", 
                        Address = "175/10-12 Đường Phạm Ngũ Lão, Hồ Chí Minh",
                        ImageUrl = "https://images.unsplash.com/photo-1552566626-52f8b828add9?w=500",
                        Latitude = 10.7684684, Longitude = 106.6938884,
                        OpeningHours = "08:00-22:00",
                        IsActive = true,
                        CreatedDate = System.DateTime.UtcNow
                    },
                    new Restaurant 
                    { 
                        Name = "Bánh Canh Hoàng Ty", 
                        Description = "Phục vụ các món regional", 
                        Address = "Hồ Chí Minh",
                        ImageUrl = "https://images.unsplash.com/photo-1552566626-52f8b828add9?w=500",
                        Latitude = 10.7917311, Longitude = 106.6915979,
                        OpeningHours = "08:00-22:00",
                        IsActive = true,
                        CreatedDate = System.DateTime.UtcNow
                    },
                    new Restaurant 
                    { 
                        Name = "Quán Ăn 7777", 
                        Description = "Phục vụ các món asian", 
                        Address = "Hồ Chí Minh",
                        ImageUrl = "https://images.unsplash.com/photo-1552566626-52f8b828add9?w=500",
                        Latitude = 10.8184173, Longitude = 106.7047992,
                        OpeningHours = "08:00-22:00",
                        IsActive = true,
                        CreatedDate = System.DateTime.UtcNow
                    },
                    new Restaurant 
                    { 
                        Name = "Nhà Hàng Tiệc Cưới Ngọc Trâm", 
                        Description = "Phục vụ các món Địa điểm ăn uống", 
                        Address = "948 Nguyễn Văn Quá, Hồ Chí Minh",
                        ImageUrl = "https://images.unsplash.com/photo-1552566626-52f8b828add9?w=500",
                        Latitude = 10.8491522, Longitude = 106.6365739,
                        OpeningHours = "08:00-22:00",
                        IsActive = true,
                        CreatedDate = System.DateTime.UtcNow
                    },
                    new Restaurant 
                    { 
                        Name = "Nhà Hàng Vietnamese Kitchen", 
                        Description = "Phục vụ các món Địa điểm ăn uống", 
                        Address = "Hồ Chí Minh",
                        ImageUrl = "https://images.unsplash.com/photo-1552566626-52f8b828add9?w=500",
                        Latitude = 10.7666137, Longitude = 106.6922676,
                        OpeningHours = "08:00-22:00",
                        IsActive = true,
                        CreatedDate = System.DateTime.UtcNow
                    },
                    new Restaurant 
                    { 
                        Name = "Nhà Hàng Lẩu Cua", 
                        Description = "Phục vụ các món Địa điểm ăn uống", 
                        Address = "Hồ Chí Minh",
                        ImageUrl = "https://images.unsplash.com/photo-1552566626-52f8b828add9?w=500",
                        Latitude = 10.8184378, Longitude = 106.6990062,
                        OpeningHours = "08:00-22:00",
                        IsActive = true,
                        CreatedDate = System.DateTime.UtcNow
                    },
                    new Restaurant 
                    { 
                        Name = "Nhà Hàng Jaspas", 
                        Description = "Phục vụ các món Địa điểm ăn uống", 
                        Address = "Hồ Chí Minh",
                        ImageUrl = "https://images.unsplash.com/photo-1552566626-52f8b828add9?w=500",
                        Latitude = 10.778168, Longitude = 106.7037041,
                        OpeningHours = "08:00-22:00",
                        IsActive = true,
                        CreatedDate = System.DateTime.UtcNow
                    },
                    new Restaurant 
                    { 
                        Name = "Nhà Hàng Shri Lounge", 
                        Description = "Phục vụ các món international", 
                        Address = "72-74 Nguyễn Thị Minh Khai, Hồ Chí Minh",
                        ImageUrl = "https://images.unsplash.com/photo-1552566626-52f8b828add9?w=500",
                        Latitude = 10.7826304, Longitude = 106.6972822,
                        OpeningHours = "08:00-22:00",
                        IsActive = true,
                        CreatedDate = System.DateTime.UtcNow
                    },
                    new Restaurant 
                    { 
                        Name = "Nhà Hàng Ấn Độ Curry Rice", 
                        Description = "Phục vụ các món indian", 
                        Address = "66 Đông Du, Hồ Chí Minh",
                        ImageUrl = "https://images.unsplash.com/photo-1552566626-52f8b828add9?w=500",
                        Latitude = 10.7762829, Longitude = 106.7042247,
                        OpeningHours = "08:00-22:00",
                        IsActive = true,
                        CreatedDate = System.DateTime.UtcNow
                    },
                    new Restaurant 
                    { 
                        Name = "Nhà Hàng Halal Sai Gon", 
                        Description = "Phục vụ các món asian", 
                        Address = "31 Đông Du, Hồ Chí Minh",
                        ImageUrl = "https://images.unsplash.com/photo-1552566626-52f8b828add9?w=500",
                        Latitude = 10.7760297, Longitude = 106.7047293,
                        OpeningHours = "08:00-22:00",
                        IsActive = true,
                        CreatedDate = System.DateTime.UtcNow
                    },
                    new Restaurant 
                    { 
                        Name = "Nhà Hàng Cung Đình Rex", 
                        Description = "Phục vụ các món vietnamese", 
                        Address = "146 Đường Pasteur, Hồ Chí Minh",
                        ImageUrl = "https://images.unsplash.com/photo-1552566626-52f8b828add9?w=500",
                        Latitude = 10.7754972, Longitude = 106.7007063,
                        OpeningHours = "08:00-22:00",
                        IsActive = true,
                        CreatedDate = System.DateTime.UtcNow
                    },
                    new Restaurant 
                    { 
                        Name = "Nhà Hàng Tiệc Cưới 108 Nguyễn Du", 
                        Description = "Phục vụ các món vietnamese", 
                        Address = "Hồ Chí Minh",
                        ImageUrl = "https://images.unsplash.com/photo-1552566626-52f8b828add9?w=500",
                        Latitude = 10.7754764, Longitude = 106.6956779,
                        OpeningHours = "08:00-22:00",
                        IsActive = true,
                        CreatedDate = System.DateTime.UtcNow
                    },
                    new Restaurant 
                    { 
                        Name = "Nhà Hàng Alibaba", 
                        Description = "Phục vụ các món international;grill;coffee_shop;persian;asian;steak_house;beef_bowl;russian;donut;pancake;fish_and_chips;chicken;vietnamese;oriental;breakfast;savory_pancakes;tea;seafood;friture;chinese;kebab;barbecue", 
                        Address = "90 Hung Vuong, Hồ Chí Minh",
                        ImageUrl = "https://images.unsplash.com/photo-1552566626-52f8b828add9?w=500",
                        Latitude = 10.7743953, Longitude = 106.7040996,
                        OpeningHours = "08:00-22:00",
                        IsActive = true,
                        CreatedDate = System.DateTime.UtcNow
                    },
                    new Restaurant 
                    { 
                        Name = "Nhà Hàng Hải Cảng", 
                        Description = "Phục vụ các món chinese", 
                        Address = "Hồ Chí Minh",
                        ImageUrl = "https://images.unsplash.com/photo-1552566626-52f8b828add9?w=500",
                        Latitude = 10.7662887, Longitude = 106.7077614,
                        OpeningHours = "08:00-22:00",
                        IsActive = true,
                        CreatedDate = System.DateTime.UtcNow
                    },
                    new Restaurant 
                    { 
                        Name = "Nhà Hàng Honeymoon", 
                        Description = "Phục vụ các món Địa điểm ăn uống", 
                        Address = "Đường Hoàng Diệu, Hồ Chí Minh",
                        ImageUrl = "https://images.unsplash.com/photo-1552566626-52f8b828add9?w=500",
                        Latitude = 10.7602951, Longitude = 106.6991702,
                        OpeningHours = "08:00-22:00",
                        IsActive = true,
                        CreatedDate = System.DateTime.UtcNow
                    },
                    new Restaurant 
                    { 
                        Name = "Cửa Hàng Xôi Chè Bùi Thị Xuân", 
                        Description = "Phục vụ các món Địa điểm ăn uống", 
                        Address = "Hồ Chí Minh",
                        ImageUrl = "https://images.unsplash.com/photo-1552566626-52f8b828add9?w=500",
                        Latitude = 10.7675882, Longitude = 106.6863944,
                        OpeningHours = "08:00-22:00",
                        IsActive = true,
                        CreatedDate = System.DateTime.UtcNow
                    },
                    new Restaurant 
                    { 
                        Name = "Topping Beef", 
                        Description = "Phục vụ các món Địa điểm ăn uống", 
                        Address = "106 Nguyễn Thị Minh Khai, Hồ Chí Minh",
                        ImageUrl = "https://images.unsplash.com/photo-1552566626-52f8b828add9?w=500",
                        Latitude = 10.7797991, Longitude = 106.6949139,
                        OpeningHours = "08:00-22:00",
                        IsActive = true,
                        CreatedDate = System.DateTime.UtcNow
                    },
                    new Restaurant 
                    { 
                        Name = "Nhà Hàng Bornga", 
                        Description = "Phục vụ các món korean", 
                        Address = "Hồ Chí Minh",
                        ImageUrl = "https://images.unsplash.com/photo-1552566626-52f8b828add9?w=500",
                        Latitude = 10.7788067, Longitude = 106.7020073,
                        OpeningHours = "08:00-22:00",
                        IsActive = true,
                        CreatedDate = System.DateTime.UtcNow
                    },
                    new Restaurant 
                    { 
                        Name = "Quán Phở 2000", 
                        Description = "Phục vụ các món vietnamese", 
                        Address = "Hồ Chí Minh",
                        ImageUrl = "https://images.unsplash.com/photo-1552566626-52f8b828add9?w=500",
                        Latitude = 10.7718157, Longitude = 106.697747,
                        OpeningHours = "08:00-22:00",
                        IsActive = true,
                        CreatedDate = System.DateTime.UtcNow
                    },
                    new Restaurant 
                    { 
                        Name = "Nhà Hàng Lion Beer", 
                        Description = "Phục vụ các món international", 
                        Address = "11-13 Công trường Lam Sơn, Hồ Chí Minh",
                        ImageUrl = "https://images.unsplash.com/photo-1552566626-52f8b828add9?w=500",
                        Latitude = 10.776619, Longitude = 106.7039069,
                        OpeningHours = "08:00-22:00",
                        IsActive = true,
                        CreatedDate = System.DateTime.UtcNow
                    },
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
                var allRestaurants = await context.Restaurants.Take(3).ToListAsync();
                if (allRestaurants.Count >= 3)
                {
                    var store1 = allRestaurants[0];
                    var store2 = allRestaurants[1];
                    var store3 = allRestaurants[2];

                    var catPho = await context.Categories.FirstOrDefaultAsync(c => c.Name == "Phở");
                    var catPizza = await context.Categories.FirstOrDefaultAsync(c => c.Name == "Pizza & Đồ Âu");
                    var catBun = await context.Categories.FirstOrDefaultAsync(c => c.Name == "Bún & Phở");

                    if (catPho != null && catPizza != null && catBun != null)
                    {
                        var foodItems = new List<FoodItem>
                        {
                            new FoodItem { Name = "Phở Bò Tái Lăn", Description = "Đặc sản Sài Gòn", Price = 70000, CategoryId = catPho.Id, RestaurantId = store1.Id, ImageUrl = "https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=500", CreatedDate = System.DateTime.UtcNow },
                            new FoodItem { Name = "Phở Bò Chín", Description = "Thơm ngon nước thanh", Price = 65000, CategoryId = catPho.Id, RestaurantId = store1.Id, ImageUrl = "https://images.unsplash.com/photo-1626804475297-41609ea8eb4b?w=500", CreatedDate = System.DateTime.UtcNow },
                            
                            new FoodItem { Name = "Pizza Hải Sản", Description = "Hải sản tươi sống", Price = 250000, CategoryId = catPizza.Id, RestaurantId = store2.Id, ImageUrl = "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500", CreatedDate = System.DateTime.UtcNow },
                            new FoodItem { Name = "Mì Ý Cua", Description = "Mì Ý tôm cua sốt kem", Price = 180000, CategoryId = catPizza.Id, RestaurantId = store2.Id, ImageUrl = "https://images.unsplash.com/photo-1516100882582-96c3a05fe590?w=500", CreatedDate = System.DateTime.UtcNow },
                            
                            new FoodItem { Name = "Cơm Tấm Sườn Bì Chả", Description = "Đặc sản chính gốc", Price = 90000, CategoryId = catBun.Id, RestaurantId = store3.Id, ImageUrl = "https://images.unsplash.com/photo-1541529086526-db283c563270?w=500", CreatedDate = System.DateTime.UtcNow },
                            new FoodItem { Name = "Cơm Tấm Đặc Biệt", Description = "Đầy đủ topping", Price = 50000, CategoryId = catBun.Id, RestaurantId = store3.Id, ImageUrl = "https://images.unsplash.com/photo-1596704177526-66380c2f30b9?w=500", CreatedDate = System.DateTime.UtcNow }
                        };
                        context.FoodItems.AddRange(foodItems);
                        await context.SaveChangesAsync();
                    }
                }
            }

            // Tạo tracking logs giả để demo AI
            if (!await context.TrackingLogs.AnyAsync())
            {
                var logs = new List<TrackingLog>();
                var random = new System.Random(42);
                
                var userA = await context.Users.FirstOrDefaultAsync(u => u.Email == "test1@gmail.com");
                var allRestaurants = await context.Restaurants.Take(2).ToListAsync();

                if (userA != null && allRestaurants.Count >= 2)
                {
                    var store1 = allRestaurants[0];
                    var store2 = allRestaurants[1];

                    for (int i = 0; i < 20; i++)
                    {
                        logs.Add(new TrackingLog {
                            UserId = userA.Id,
                            RestaurantId = store1.Id,
                            ActionType = i % 3 == 0 ? "AddToCart" : "View",
                            Latitude = store1.Latitude,
                            Longitude = store1.Longitude,
                            Timestamp = System.DateTime.UtcNow.AddDays(-random.Next(30)),
                            DeviceInfo = "Android"
                        });
                    }
                    for (int i = 0; i < 8; i++)
                    {
                        logs.Add(new TrackingLog {
                            UserId = userA.Id, 
                            RestaurantId = store2.Id,
                            ActionType = "View",
                            Latitude = store2.Latitude, 
                            Longitude = store2.Longitude,
                            Timestamp = System.DateTime.UtcNow.AddDays(-random.Next(15)),
                            DeviceInfo = "Android"
                        });
                    }
                    context.TrackingLogs.AddRange(logs);
                    await context.SaveChangesAsync();
                }
            }
        }
    }
}

