using Microsoft.AspNetCore.Mvc;
using Application.Interfaces;
using Domain.Entities;
using System.Threading.Tasks;

namespace API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class TrackingController : ControllerBase
    {
        private readonly ITrackingService _trackingService;

        public TrackingController(ITrackingService trackingService)
        {
            _trackingService = trackingService;
        }

        [HttpPost("log")]
        public async Task<IActionResult> LogBehavior([FromBody] TrackingLog log)
        {
            if (log == null) return BadRequest();
            
            await _trackingService.LogBehaviorAsync(log);
            return Ok(new { message = "Behavior logged successfully" });
        }
    }
}
