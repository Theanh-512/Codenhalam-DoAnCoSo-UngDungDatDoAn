using System;
using System.Collections.Generic;
using System.Linq;

namespace AICore
{
    public class RouteOptimizer
    {
        public class GeoLocation
        {
            public int OrderId { get; set; }
            public double Lat { get; set; }
            public double Lng { get; set; }
            public string Address { get; set; } = string.Empty;
        }

        // Áp dụng Thuật toán Tham lam (Greedy Algorithm) để tối ưu lộ trình giao hàng (TSP - Traveling Salesperson Problem)
        public List<GeoLocation> GetOptimizedRoute(GeoLocation startLocation, List<GeoLocation> deliveries)
        {
            var optimizedRoute = new List<GeoLocation>();
            var unvisited = new List<GeoLocation>(deliveries);
            var currentLocation = startLocation;

            while (unvisited.Count > 0)
            {
                // Tìm điểm tiếp theo gần nhất
                var nearest = unvisited
                    .OrderBy(d => CalculateDistance(currentLocation.Lat, currentLocation.Lng, d.Lat, d.Lng))
                    .First();

                optimizedRoute.Add(nearest);
                unvisited.Remove(nearest);
                currentLocation = nearest; // Cập nhật điểm hiện tại
            }

            return optimizedRoute;
        }

        // Công thức Haversine để tính khoảng cách giữa hai tọa độ GPS (Đơn vị: km)
        private double CalculateDistance(double lat1, double lon1, double lat2, double lon2)
        {
            var R = 6371; // Earth's radius in km
            var dLat = ToRadians(lat2 - lat1);
            var dLon = ToRadians(lon2 - lon1);
            var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                    Math.Cos(ToRadians(lat1)) * Math.Cos(ToRadians(lat2)) *
                    Math.Sin(dLon / 2) * Math.Sin(dLon / 2);
            var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
            return R * c;
        }

        private double ToRadians(double angle)
        {
            return Math.PI * angle / 180.0;
        }
    }
}
