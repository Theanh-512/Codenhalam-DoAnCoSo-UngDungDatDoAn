using System;
using System.Net.Http;
using System.Text.Json;
using System.Threading.Tasks;
using System.Collections.Generic;

namespace AICore
{
    public class RecommendationEngine
    {
        private readonly HttpClient _httpClient;
        private readonly string _pythonServiceUrl = "http://localhost:8000"; // Địa chỉ mặc định của bản giả lập FastAPI 

        public RecommendationEngine()
        {
            _httpClient = new HttpClient();
        }

        // Tích hợp Model SCR (Deep Sequential Model)
        public async Task<int[]> PredictTopN(int userId, double lat, double lng, int n)
        {
            try
            {
                var currentTime = DateTime.Now;
                var requestBody = new
                {
                    user_id = userId,
                    lat = lat,
                    lng = lng,
                    time = currentTime.ToString("HH:mm"),
                    day_of_week = (int)currentTime.DayOfWeek
                };

                var content = new StringContent(JsonSerializer.Serialize(requestBody), System.Text.Encoding.UTF8, "application/json");
                var response = await _httpClient.PostAsync($"{_pythonServiceUrl}/api/ai/recommend-poi", content);

                if (response.IsSuccessStatusCode)
                {
                    var responseStr = await response.Content.ReadAsStringAsync();
                    var result = JsonSerializer.Deserialize<RecommendationResponse>(responseStr, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
                    return result?.Restaurant_ids?.ToArray() ?? new int[0];
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Lỗi gọi AI Service: {ex.Message}");
            }
            
            // Trả về Dummy data nếu Microservice Python chưa chạy (để tránh lỗi Crash)
            return new int[] { 1, 2, 3 };
        }
    }

    public class RecommendationResponse
    {
        public List<int>? Restaurant_ids { get; set; }
        public string? Reason { get; set; }
    }
}
