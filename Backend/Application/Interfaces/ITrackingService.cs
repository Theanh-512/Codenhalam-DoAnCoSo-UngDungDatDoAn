using System.Threading.Tasks;
using Domain.Entities;

namespace Application.Interfaces
{
    public interface ITrackingService
    {
        Task LogBehaviorAsync(TrackingLog log);
    }
}
