using System;
using System.Threading.Tasks;
using System.Collections.Generic;
using System.Linq;
using Grpc.Net.Client;
using AICore.Grpc;
using Domain.Entities;

namespace AICore
{
    public class RecommendationEngine
    {
        private readonly string _grpcPythonServiceUrl = "http://localhost:50051";

        public RecommendationEngine()
        {
        }

        // SCR Framework: Phân tách sở thích Dài hạn và Ngắn hạn
        public List<int> GetTopNRestaurants(
            int userId, 
            List<TrackingLog> userLogs, 
            List<Restaurant>? allRestaurants, 
            int topN = 5)
        {
            if (userLogs == null || !userLogs.Any()) return new List<int>();

            var currentSlot = CalculateMealSlot(DateTime.UtcNow);
            var longTermScores = new Dictionary<int, double>();
            var shortTermScores = new Dictionary<int, double>();

            // 1. Phân tách Dài hạn (Lịch sử cũ) và Ngắn hạn (Các phiên gần nhất)
            var recentSessionLogs = userLogs
                .OrderByDescending(l => l.Timestamp)
                .Take(5) // Lấy 5 tương tác gần nhất làm Short-term
                .ToList();

            var historicalLogs = userLogs
                .Except(recentSessionLogs)
                .ToList();

            // 2. Tính điểm Dài hạn (Long-term Preference) kết hợp Ngữ cảnh thời gian (MealSlot)
            foreach (var log in historicalLogs)
            {
                double weight = GetActionWeight(log.ActionType);
                
                // Nếu cùng MealSlot (ví dụ: cùng là bữa trưa), tăng trọng số (SCR Theory)
                if (log.MealSlot == currentSlot) weight *= 1.5;

                if (!longTermScores.ContainsKey(log.RestaurantId))
                    longTermScores[log.RestaurantId] = 0;
                longTermScores[log.RestaurantId] += weight;
            }

            // 3. Tính điểm Ngắn hạn (Short-term Preference) - Trọng số cao hơn
            foreach (var log in recentSessionLogs)
            {
                double weight = GetActionWeight(log.ActionType) * 2.5; // Trọng số ý định tức thời cao hơn
                if (!shortTermScores.ContainsKey(log.RestaurantId))
                    shortTermScores[log.RestaurantId] = 0;
                shortTermScores[log.RestaurantId] += weight;
            }

            // 4. Fusion (Hợp nhất hai tầng sở thích)
            var finalScores = new Dictionary<int, double>();
            var allRestaurantIds = longTermScores.Keys.Union(shortTermScores.Keys);

            foreach (var id in allRestaurantIds)
            {
                double longTerm = longTermScores.GetValueOrDefault(id, 0);
                double shortTerm = shortTermScores.GetValueOrDefault(id, 0);
                finalScores[id] = (longTerm * 0.4) + (shortTerm * 0.6); // SCR: Kết hợp Alpha/Beta weights
            }

            return finalScores
                .OrderByDescending(x => x.Value)
                .Take(topN)
                .Select(x => x.Key)
                .ToList();
        }

        private double GetActionWeight(string actionType) => actionType switch {
            "AddToCart" => 3.0,
            "View"      => 1.5,
            "Click"     => 1.0,
            _           => 0.5
        };

        private int CalculateMealSlot(DateTime dt)
        {
            int hour = dt.Hour;
            bool isWeekend = dt.DayOfWeek == DayOfWeek.Saturday || dt.DayOfWeek == DayOfWeek.Sunday;
            return isWeekend ? hour + 24 : hour;
        }


        // Tích hợp Model SCR (Deep Sequential Model) sử dụng gRPC
        public async Task<int[]> PredictTopN(int userId, double lat, double lng, int n)
        {
            try
            {
                var currentTime = DateTime.Now;
                
                using var channel = GrpcChannel.ForAddress(_grpcPythonServiceUrl);
                var client = new RecommendationService.RecommendationServiceClient(channel);

                var request = new VectorContextRequest
                {
                    UserId = userId,
                    Lat = (float)lat,
                    Lng = (float)lng,
                    Time = currentTime.ToString("HH:mm"),
                    DayOfWeek = (int)currentTime.DayOfWeek
                };

                var response = await client.GetRecommendationsAsync(request);
                return response.RestaurantIds.ToArray();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Lỗi gọi AI Service qua gRPC: {ex.Message}");
            }
            
            return new int[0];
        }
    }
}

