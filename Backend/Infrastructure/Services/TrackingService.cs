using Application.Interfaces;
using Domain.Entities;
using Infrastructure.Data;
using System.Threading.Tasks;

namespace Infrastructure.Services
{
    public class TrackingService : ITrackingService
    {
        private readonly FoodAppDbContext _context;

        public TrackingService(FoodAppDbContext context)
        {
            _context = context;
        }

        public async Task LogBehaviorAsync(TrackingLog log)
        {
            _context.TrackingLogs.Add(log);
            await _context.SaveChangesAsync();
        }
    }
}
