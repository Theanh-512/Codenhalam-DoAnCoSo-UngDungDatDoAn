using System;
using System.IO;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace Infrastructure.Data
{
    /// <summary>
    /// Design-time factory cho `dotnet ef migrations` — không phụ thuộc Host/JWT.
    /// Đọc connection theo thứ tự ưu tiên:
    ///   1. env DEFAULT_CONNECTION
    ///   2. Backend/API/appsettings.Development.json (gitignored)
    ///   3. Backend/API/appsettings.Local.json
    ///   4. Backend/API/appsettings.json
    /// </summary>
    public class FoodAppDbContextFactory : IDesignTimeDbContextFactory<FoodAppDbContext>
    {
        public FoodAppDbContext CreateDbContext(string[] args)
        {
            var conn = Environment.GetEnvironmentVariable("DEFAULT_CONNECTION");
            if (string.IsNullOrWhiteSpace(conn))
            {
                var apiDir = ResolveApiDir();
                foreach (var name in new[]
                {
                    "appsettings.Development.json",
                    "appsettings.Local.json",
                    "appsettings.json",
                })
                {
                    var path = Path.Combine(apiDir, name);
                    if (!File.Exists(path)) continue;
                    try
                    {
                        using var doc = JsonDocument.Parse(File.ReadAllText(path));
                        if (doc.RootElement.TryGetProperty("ConnectionStrings", out var cs)
                            && cs.TryGetProperty("DefaultConnection", out var dc)
                            && dc.ValueKind == JsonValueKind.String)
                        {
                            var v = dc.GetString();
                            if (!string.IsNullOrWhiteSpace(v))
                            {
                                conn = v;
                                break;
                            }
                        }
                    }
                    catch (JsonException) { /* skip */ }
                }
            }

            if (string.IsNullOrWhiteSpace(conn))
            {
                throw new InvalidOperationException(
                    "DefaultConnection chưa cấu hình. " +
                    "Tạo Backend/API/appsettings.Development.json (copy từ appsettings.Example.json) " +
                    "hoặc set env DEFAULT_CONNECTION trước khi chạy `dotnet ef`.");
            }

            var options = new DbContextOptionsBuilder<FoodAppDbContext>()
                .UseNpgsql(conn)
                .Options;
            return new FoodAppDbContext(options);
        }

        private static string ResolveApiDir()
        {
            var dir = new DirectoryInfo(Directory.GetCurrentDirectory());
            for (var i = 0; i < 6 && dir != null; i++)
            {
                var sibling = Path.Combine(dir.FullName, "API");
                if (Directory.Exists(sibling)
                    && File.Exists(Path.Combine(sibling, "API.csproj")))
                {
                    return sibling;
                }
                dir = dir.Parent;
            }
            return Directory.GetCurrentDirectory();
        }
    }
}
