using System.Threading.Tasks;
using Domain.Entities;

namespace Application.Interfaces
{
    public interface ITrackingService
    {
        Task LogBehaviorAsync(TrackingLog log);
    }
    
    public interface IAIService
    {
        // For Long-term and Short-term preference prediction
        Task<int[]> GetTopNRestaurantsAsync(int userId, double? latitude, double? longitude, int topN);
    }
}
