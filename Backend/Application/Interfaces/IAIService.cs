using System.Threading.Tasks;

namespace Application.Interfaces
{
    public interface IAIService
    {
        /// <summary>
        /// For Long-term and Short-term preference prediction
        /// </summary>
        Task<int[]> GetTopNRestaurantsAsync(int userId, double? latitude, double? longitude, int topN);
    }
}
