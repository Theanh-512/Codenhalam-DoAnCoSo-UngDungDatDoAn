using Microsoft.EntityFrameworkCore;
using Domain.Entities;

namespace Infrastructure.Data
{
    public class FoodAppDbContext : DbContext
    {
        public FoodAppDbContext(DbContextOptions<FoodAppDbContext> options) : base(options)
        {
        }

        public DbSet<User> Users { get; set; }
        public DbSet<Restaurant> Restaurants { get; set; }
        public DbSet<FoodItem> FoodItems { get; set; }
        public DbSet<Category> Categories { get; set; }
        public DbSet<Order> Orders { get; set; }
        public DbSet<OrderItem> OrderItems { get; set; }
        public DbSet<TrackingLog> TrackingLogs { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // ===== Decimal Precision =====
            modelBuilder.Entity<FoodItem>()
                .Property(f => f.Price)
                .HasPrecision(18, 2);

            modelBuilder.Entity<Order>()
                .Property(o => o.TotalAmount)
                .HasPrecision(18, 2);

            modelBuilder.Entity<OrderItem>()
                .Property(oi => oi.UnitPrice)
                .HasPrecision(18, 2);

            // ===== Restaurant → FoodItems (1-N) =====
            modelBuilder.Entity<Restaurant>()
                .HasMany(r => r.FoodItems)
                .WithOne(f => f.Restaurant)
                .HasForeignKey(f => f.RestaurantId)
                .OnDelete(DeleteBehavior.Cascade);

            // ===== Category → FoodItems (1-N) =====
            modelBuilder.Entity<Category>()
                .HasMany(c => c.FoodItems)
                .WithOne(f => f.Category)
                .HasForeignKey(f => f.CategoryId)
                .OnDelete(DeleteBehavior.Cascade);

            // ===== User → Orders (1-N) =====
            modelBuilder.Entity<User>()
                .HasMany(u => u.Orders)
                .WithOne(o => o.User)
                .HasForeignKey(o => o.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            // ===== Order → OrderItems (1-N) =====
            modelBuilder.Entity<Order>()
                .HasMany(o => o.OrderItems)
                .WithOne(oi => oi.Order)
                .HasForeignKey(oi => oi.OrderId)
                .OnDelete(DeleteBehavior.Cascade);

            // ===== TrackingLog → User (optional N-1) =====
            modelBuilder.Entity<TrackingLog>()
                .HasOne<User>()
                .WithMany()
                .HasForeignKey(t => t.UserId)
                .IsRequired(false)
                .OnDelete(DeleteBehavior.SetNull);

            // ===== TrackingLog → Restaurant (N-1) =====
            modelBuilder.Entity<TrackingLog>()
                .HasOne<Restaurant>()
                .WithMany()
                .HasForeignKey(t => t.RestaurantId)
                .OnDelete(DeleteBehavior.Cascade);

            // ===== Ignore computed property (not a DB column) =====
            modelBuilder.Entity<TrackingLog>()
                .Ignore(t => t.MealSlot);
        }
    }
}
