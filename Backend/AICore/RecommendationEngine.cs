using System;
using System.Threading.Tasks;
using System.Collections.Generic;
using Grpc.Net.Client;
using AICore.Grpc; // Namespace sinh ra từ file .proto

namespace AICore
{
    public class RecommendationEngine
    {
        private readonly string _grpcPythonServiceUrl = "http://localhost:50051"; // Cổng mặc định của gRPC Server Python

        public RecommendationEngine()
        {
        }

        // Tích hợp Model SCR (Deep Sequential Model) sử dụng gRPC
        public async Task<int[]> PredictTopN(int userId, double lat, double lng, int n)
        {
            try
            {
                var currentTime = DateTime.Now;
                
                // Mở kênh kết nối gRPC
                using var channel = GrpcChannel.ForAddress(_grpcPythonServiceUrl);
                var client = new RecommendationService.RecommendationServiceClient(channel);

                // Chuẩn bị Request chuẩn hóa float (theo Báo cáo tuần 8)
                var request = new VectorContextRequest
                {
                    UserId = userId,
                    Lat = (float)lat, // Ép kiểu về float32 để đồng nhất với Python (float64)
                    Lng = (float)lng, // Ép kiểu về float32
                    Time = currentTime.ToString("HH:mm"),
                    DayOfWeek = (int)currentTime.DayOfWeek
                };

                // Gọi gRPC
                var response = await client.GetRecommendationsAsync(request);

                return response.RestaurantIds.ToArray();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Lỗi gọi AI Service qua gRPC: {ex.Message}");
            }
            
            // Fallback trả về Empty Array để API Controller xử lý bằng KNN (theo Báo cáo tuần 8)
            return new int[0];
        }
    }
}
