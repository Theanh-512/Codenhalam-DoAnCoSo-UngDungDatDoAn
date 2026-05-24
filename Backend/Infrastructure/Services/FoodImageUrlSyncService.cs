using System.Globalization;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Infrastructure.Data;

namespace Infrastructure.Services;

/// <summary>
/// Gắn ImageUrl cho FoodItems / Restaurants từ bucket Supabase food-images.
/// </summary>
public class FoodImageUrlSyncService
{
    /// <summary>Folder trên Storage → từ khóa khớp trong tên món/danh mục (đã bỏ dấu).</summary>
    private static readonly Dictionary<string, string[]> FolderAliases =
        new(StringComparer.OrdinalIgnoreCase)
        {
            ["Pho"] = new[] { "pho", "phở", "pho bo", "phở bò", "phở & bún", "bun", "bún" },
            ["banh beo"] = new[] { "Banh beo", "bánh bèo" },
            ["Pizza"] = new[] { "pizza", "margherita", "hải sản", "hai san", "bbq chicken", "mì ý", "mi y", "đồ âu", "do au" },
            ["Com tam"] = new[] { "com tam", "cơm tấm", "co tam", "cơm", "com" },
            ["Xoi xeo"] = new[] { "xoi xeo", "xôi xéo", "xoi", "xôi" },
            ["Mi quang"] = new[] { "mi quang", "mì quảng", "mì quang", "mi quảng" },
            ["Goi cuon"] = new[] { "goi cuon", "gỏi cuốn", "goi cuốn", "gỏi cuon" },
            ["Banh chung"] = new[] { "banh chung", "bánh chưng", "banh chưng", "bánh chung" },
            ["Banh tet"] = new[] { "banh tet", "bánh tét", "banh tét", "bánh tet" },
            ["Banh mi"] = new[] { "banh mi", "bánh mì", "banh mì", "bánh mi" },
            ["Banh cong"] = new[] { "banh cong", "bánh cống", "banh cống", "bánh cong" },
            ["Banh tieu"] = new[] { "banh tieu", "bánh tiêu", "banh tiêu", "bánh tieu" },
            ["Banh khot"] = new[] { "banh khot", "bánh khọt", "banh khọt", "bánh khot" },
        };

    /// <summary>Folder không có trên Storage → folder thay thế (giữ số file .jpg).</summary>
    private static readonly (string WrongFolder, string RightFolder)[] FolderUrlRemaps =
        System.Array.Empty<(string, string)>();

    private readonly FoodAppDbContext _context;
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IConfiguration _configuration;
    private readonly ILogger<FoodImageUrlSyncService> _logger;

    public FoodImageUrlSyncService(
        FoodAppDbContext context,
        IHttpClientFactory httpClientFactory,
        IConfiguration configuration,
        ILogger<FoodImageUrlSyncService> logger)
    {
        _context = context;
        _httpClientFactory = httpClientFactory;
        _configuration = configuration;
        _logger = logger;
    }

    public async Task<FoodImageSyncResult> SyncAsync(CancellationToken cancellationToken = default)
    {
        var publicBase = (_configuration["Supabase:PublicStorageBaseUrl"]
            ?? "https://wbusmwbzqlkyhxtoghsl.supabase.co/storage/v1/object/public/food-images")
            .TrimEnd('/');

        var bucket = _configuration["Supabase:StorageBucket"] ?? "food-images";
        var projectUrl = (_configuration["Supabase:ProjectUrl"]
            ?? "https://wbusmwbzqlkyhxtoghsl.supabase.co").TrimEnd('/');

        await FixKnownFolderCasingInDatabaseAsync(publicBase, cancellationToken);
        await FixRemappedFolderUrlsInDatabaseAsync(cancellationToken);

        var folderImages = await BuildFolderImageMapAsync(
            publicBase, projectUrl, bucket, cancellationToken);

        if (folderImages.Count == 0)
        {
            return new FoodImageSyncResult
            {
                Message = "Không tìm thấy ảnh trong bucket. Kiểm tra bucket public và tên folder.",
            };
        }

        var foodItems = await _context.FoodItems
            .Include(f => f.Category)
            .ToListAsync(cancellationToken);

        var foodUpdated = 0;
        foreach (var item in foodItems)
        {
            var folderKey = ResolveFolderKey(
                item.Name,
                item.Category?.Name,
                folderImages.Keys);

            var url = folderKey != null
                ? PickImageUrl(folderImages[folderKey], item.Id)
                : null;
            url = await EnsureWorkingImageUrlAsync(url ?? item.ImageUrl, cancellationToken);
            if (string.IsNullOrEmpty(url) || url == item.ImageUrl) continue;

            item.ImageUrl = url;
            item.UpdatedDate = DateTime.UtcNow;
            foodUpdated++;
        }

        var restaurants = await _context.Restaurants.ToListAsync(cancellationToken);
        var itemsByRestaurant = foodItems
            .Where(f => !string.IsNullOrWhiteSpace(f.ImageUrl))
            .GroupBy(f => f.RestaurantId)
            .ToDictionary(g => g.Key, g => g.ToList());

        var restaurantUpdated = 0;
        foreach (var r in restaurants)
        {
            string? url = null;

            if (itemsByRestaurant.TryGetValue(r.Id, out var list) && list.Count > 0)
                url = list[0].ImageUrl;

            if (string.IsNullOrEmpty(url))
            {
                var folderKey = ResolveFolderKey(r.Name, r.Type1, folderImages.Keys)
                    ?? ResolveFolderKey(r.Name, r.Type2, folderImages.Keys);
                if (folderKey != null)
                    url = PickImageUrl(folderImages[folderKey], r.Id);
            }

            url = await EnsureWorkingImageUrlAsync(url, cancellationToken);
            if (string.IsNullOrEmpty(url) || url == r.ImageUrl) continue;

            r.ImageUrl = url;
            r.UpdatedDate = DateTime.UtcNow;
            restaurantUpdated++;
        }

        await _context.SaveChangesAsync(cancellationToken);

        return new FoodImageSyncResult
        {
            Message = "Đã đồng bộ URL ảnh từ Supabase Storage",
            FoldersFound = folderImages.Count,
            FoodItemsUpdated = foodUpdated,
            RestaurantsUpdated = restaurantUpdated,
            TotalFoodItems = foodItems.Count,
            TotalRestaurants = restaurants.Count,
        };
    }

    /// <summary>Chuyển URL folder không tồn tại (vd. Xoi xeo) sang Com tam.</summary>
    private async Task FixRemappedFolderUrlsInDatabaseAsync(CancellationToken cancellationToken)
    {
        foreach (var (wrong, right) in FolderUrlRemaps)
        {
            var wrongPrefix = $"/food-images/{Uri.EscapeDataString(wrong)}/";
            var rightPrefix = $"/food-images/{Uri.EscapeDataString(right)}/";

            await _context.Database.ExecuteSqlInterpolatedAsync($"""
                UPDATE "FoodItems"
                SET "ImageUrl" = REPLACE("ImageUrl", {wrongPrefix}, {rightPrefix}),
                    "UpdatedDate" = NOW()
                WHERE "ImageUrl" IS NOT NULL AND "ImageUrl" ILIKE ${"%" + wrongPrefix + "%"}
                """);

            await _context.Database.ExecuteSqlInterpolatedAsync($"""
                UPDATE "Restaurants"
                SET "ImageUrl" = REPLACE("ImageUrl", {wrongPrefix}, {rightPrefix}),
                    "UpdatedDate" = NOW()
                WHERE "ImageUrl" ILIKE ${"%" + wrongPrefix + "%"}
                """);
        }
    }

    /// <summary>Sửa nhanh URL sai hoa/thường (vd. Banh%20beo → banh%20beo) trước khi sync chi tiết.</summary>
    private async Task FixKnownFolderCasingInDatabaseAsync(
        string publicBase, CancellationToken cancellationToken)
    {
        var client = _httpClientFactory.CreateClient();
        var folders = GetKnownStorageFolders().ToList();

        foreach (var folder in folders)
        {
            var resolved = await ResolveWorkingFolderPathAsync(
                publicBase, folder, client, cancellationToken);
            if (resolved == null || string.Equals(folder, resolved, StringComparison.Ordinal)) continue;

            var wrongPrefix = $"/food-images/{Uri.EscapeDataString(folder)}/";
            var rightPrefix = $"/food-images/{Uri.EscapeDataString(resolved)}/";

            await _context.Database.ExecuteSqlInterpolatedAsync($"""
                UPDATE "FoodItems"
                SET "ImageUrl" = REPLACE("ImageUrl", {wrongPrefix}, {rightPrefix}),
                    "UpdatedDate" = NOW()
                WHERE "ImageUrl" IS NOT NULL AND "ImageUrl" ILIKE ${"%" + wrongPrefix + "%"}
                """);

            await _context.Database.ExecuteSqlInterpolatedAsync($"""
                UPDATE "Restaurants"
                SET "ImageUrl" = REPLACE("ImageUrl", {wrongPrefix}, {rightPrefix}),
                    "UpdatedDate" = NOW()
                WHERE "ImageUrl" ILIKE ${"%" + wrongPrefix + "%"}
                """);
        }
    }

    private async Task<Dictionary<string, List<string>>> BuildFolderImageMapAsync(
        string publicBase,
        string projectUrl,
        string bucket,
        CancellationToken cancellationToken)
    {
        var fromStorage = await TryListFromStorageApiAsync(projectUrl, bucket, publicBase, cancellationToken);
        if (fromStorage.Count > 0) return fromStorage;

        _logger.LogInformation("Storage API không dùng được — quét URL theo tên danh mục/món trong DB.");
        return await DiscoverByProbingAsync(publicBase, cancellationToken);
    }

    private async Task<Dictionary<string, List<string>>> TryListFromStorageApiAsync(
        string projectUrl,
        string bucket,
        string publicBase,
        CancellationToken cancellationToken)
    {
        var serviceKey = _configuration["Supabase:ServiceRoleKey"]
            ?? Environment.GetEnvironmentVariable("SUPABASE_SERVICE_ROLE_KEY");

        if (string.IsNullOrWhiteSpace(serviceKey)) return new Dictionary<string, List<string>>();

        var client = _httpClientFactory.CreateClient();
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", serviceKey.Trim());

        var map = new Dictionary<string, List<string>>(StringComparer.OrdinalIgnoreCase);
        var prefixes = new Queue<string>();
        prefixes.Enqueue("");

        while (prefixes.Count > 0)
        {
            var prefix = prefixes.Dequeue();
            var body = JsonSerializer.Serialize(new { prefix, limit = 1000, offset = 0 });
            using var content = new StringContent(body, Encoding.UTF8, "application/json");
            var url = $"{projectUrl}/storage/v1/object/list/{bucket}";

            HttpResponseMessage response;
            try
            {
                response = await client.PostAsync(url, content, cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Lỗi gọi Storage list API");
                break;
            }

            if (!response.IsSuccessStatusCode) break;

            var json = await response.Content.ReadAsStringAsync(cancellationToken);
            using var doc = JsonDocument.Parse(json);
            if (doc.RootElement.ValueKind != JsonValueKind.Array) break;

            foreach (var entry in doc.RootElement.EnumerateArray())
            {
                if (!entry.TryGetProperty("name", out var nameEl)) continue;
                var name = nameEl.GetString() ?? "";
                if (string.IsNullOrWhiteSpace(name)) continue;

                var fullPath = string.IsNullOrEmpty(prefix) ? name : $"{prefix.TrimEnd('/')}/{name}";

                if (IsImageFile(name))
                {
                    var parts = fullPath.Split('/');
                    var folderKey = parts.Length >= 2
                        ? parts[^2]
                        : Path.GetFileNameWithoutExtension(parts[0]);

                    var publicUrl = $"{publicBase}/{EncodePath(fullPath)}";
                    if (!map.TryGetValue(folderKey, out var list))
                    {
                        list = new List<string>();
                        map[folderKey] = list;
                    }
                    list.Add(publicUrl);
                }
                else if (!name.Contains('.'))
                {
                    prefixes.Enqueue(fullPath + "/");
                }
            }
        }

        return map;
    }

    private async Task<Dictionary<string, List<string>>> DiscoverByProbingAsync(
        string publicBase,
        CancellationToken cancellationToken)
    {
        var folderNames = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        foreach (var known in GetKnownStorageFolders())
            folderNames.Add(known);

        var categories = await _context.Categories.AsNoTracking()
            .Select(c => c.Name).ToListAsync(cancellationToken);
        foreach (var n in categories)
            if (!string.IsNullOrWhiteSpace(n)) folderNames.Add(n.Trim());

        var foodNames = await _context.FoodItems.AsNoTracking()
            .Select(f => f.Name).ToListAsync(cancellationToken);
        foreach (var n in foodNames)
        {
            if (string.IsNullOrWhiteSpace(n)) continue;
            folderNames.Add(n.Trim());
            var first = n.Trim().Split(' ', StringSplitOptions.RemoveEmptyEntries).FirstOrDefault();
            if (!string.IsNullOrEmpty(first)) folderNames.Add(first);
        }

        var client = _httpClientFactory.CreateClient();
        var map = new Dictionary<string, List<string>>(StringComparer.OrdinalIgnoreCase);

        foreach (var folder in folderNames)
        {
            var storageFolder = await ResolveWorkingFolderPathAsync(
                publicBase, folder, client, cancellationToken);
            if (storageFolder == null) continue;

            var urls = new List<string>();
            for (var i = 1; i <= 30; i++)
            {
                var imageUrl = $"{publicBase}/{EncodePath($"{storageFolder}/{i}.jpg")}";
                if (await HeadOkAsync(client, imageUrl, cancellationToken))
                    urls.Add(imageUrl);
            }

            if (urls.Count > 0)
                map[folder] = urls;
        }

        return map;
    }

    private IEnumerable<string> GetKnownStorageFolders()
    {
        var fromConfig = _configuration.GetSection("Supabase:KnownImageFolders").Get<string[]>();
        if (fromConfig is { Length: > 0 })
            return fromConfig.Where(s => !string.IsNullOrWhiteSpace(s)).Select(s => s.Trim());

        return FolderAliases.Keys;
    }

    private static string? ResolveFolderKey(
        string? primary,
        string? secondary,
        IEnumerable<string> folderKeys)
    {
        var keys = folderKeys.ToList();
        if (keys.Count == 0) return null;

        foreach (var candidate in new[] { primary, secondary })
        {
            if (string.IsNullOrWhiteSpace(candidate)) continue;

            var exact = keys.FirstOrDefault(k =>
                Normalize(k) == Normalize(candidate));
            if (exact != null) return exact;

            var contains = keys.FirstOrDefault(k =>
                Normalize(candidate).Contains(Normalize(k), StringComparison.OrdinalIgnoreCase)
                || Normalize(k).Contains(Normalize(candidate), StringComparison.OrdinalIgnoreCase));
            if (contains != null) return contains;

            var viaAlias = keys.FirstOrDefault(k => MatchesFolderAlias(k, candidate));
            if (viaAlias != null) return viaAlias;
        }

        if (!string.IsNullOrWhiteSpace(primary))
        {
            var firstWord = primary.Trim().Split(' ', StringSplitOptions.RemoveEmptyEntries).FirstOrDefault();
            if (!string.IsNullOrEmpty(firstWord))
            {
                var match = keys.FirstOrDefault(k =>
                    Normalize(k) == Normalize(firstWord)
                    || Normalize(k).StartsWith(Normalize(firstWord), StringComparison.OrdinalIgnoreCase)
                    || MatchesFolderAlias(k, firstWord));
                if (match != null) return match;
            }
        }

        return null;
    }

    private static bool MatchesFolderAlias(string folderKey, string text)
    {
        if (!FolderAliases.TryGetValue(folderKey, out var aliases)) return false;
        var n = Normalize(text);
        return aliases.Any(a => n.Contains(Normalize(a), StringComparison.OrdinalIgnoreCase));
    }

    private async Task<string?> EnsureWorkingImageUrlAsync(string? url, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(url)) return null;

        var client = _httpClientFactory.CreateClient();
        if (await HeadOkAsync(client, url, cancellationToken)) return url;

        var remapped = RemapBrokenFolderInUrl(url);
        if (!string.IsNullOrEmpty(remapped) && remapped != url
            && await HeadOkAsync(client, remapped, cancellationToken))
            return remapped;

        var fixedUrl = await FixStorageFolderPathAsync(url, client, cancellationToken);
        if (!string.IsNullOrEmpty(fixedUrl) && fixedUrl != url
            && await HeadOkAsync(client, fixedUrl, cancellationToken))
            return fixedUrl;

        return null;
    }

    private static string? RemapBrokenFolderInUrl(string url)
    {
        const string marker = "/food-images/";
        var idx = url.IndexOf(marker, StringComparison.OrdinalIgnoreCase);
        if (idx < 0) return null;

        var basePart = url[..(idx + marker.Length)];
        var pathPart = url[(idx + marker.Length)..];
        var segments = pathPart.Split('/', StringSplitOptions.RemoveEmptyEntries);
        if (segments.Length == 0) return null;

        var folder = Uri.UnescapeDataString(segments[0]);
        foreach (var (wrong, right) in FolderUrlRemaps)
        {
            if (!string.Equals(folder, wrong, StringComparison.OrdinalIgnoreCase)) continue;
            segments[0] = Uri.EscapeDataString(right);
            return basePart + string.Join("/", segments);
        }

        return null;
    }

    private async Task<string?> FixStorageFolderPathAsync(
        string url, HttpClient client, CancellationToken cancellationToken)
    {
        const string marker = "/food-images/";
        var idx = url.IndexOf(marker, StringComparison.OrdinalIgnoreCase);
        if (idx < 0) return null;

        var publicBase = url[..(idx + marker.Length)].TrimEnd('/');
        var pathPart = url[(idx + marker.Length)..];
        var segments = pathPart.Split('/', StringSplitOptions.RemoveEmptyEntries);
        if (segments.Length == 0) return null;

        var folder = Uri.UnescapeDataString(segments[0]);
        var resolved = await ResolveWorkingFolderPathAsync(
            publicBase, folder, client, cancellationToken);
        if (resolved == null || string.Equals(folder, resolved, StringComparison.Ordinal)) return null;

        segments[0] = Uri.EscapeDataString(resolved);
        return publicBase + marker + string.Join("/", segments);
    }

    private async Task<string?> ResolveWorkingFolderPathAsync(
        string publicBase,
        string folder,
        HttpClient client,
        CancellationToken cancellationToken)
    {
        var candidates = new[]
        {
            folder,
            folder.ToLowerInvariant(),
            CultureInfo.CurrentCulture.TextInfo.ToTitleCase(folder.ToLowerInvariant()),
        };

        foreach (var candidate in candidates.Distinct(StringComparer.OrdinalIgnoreCase))
        {
            var testUrl = $"{publicBase}/{EncodePath($"{candidate}/1.jpg")}";
            if (await HeadOkAsync(client, testUrl, cancellationToken))
                return candidate;
        }

        return null;
    }

    private static async Task<bool> HeadOkAsync(
        HttpClient client, string url, CancellationToken cancellationToken)
    {
        try
        {
            using var req = new HttpRequestMessage(HttpMethod.Head, url);
            var res = await client.SendAsync(req, HttpCompletionOption.ResponseHeadersRead, cancellationToken);
            return res.IsSuccessStatusCode;
        }
        catch
        {
            return false;
        }
    }

    private static string PickImageUrl(List<string> urls, int seed)
    {
        if (urls.Count == 0) return "";
        var index = Math.Abs(seed) % urls.Count;
        return urls[index];
    }

    private static bool IsImageFile(string name) =>
        name.EndsWith(".jpg", StringComparison.OrdinalIgnoreCase)
        || name.EndsWith(".jpeg", StringComparison.OrdinalIgnoreCase)
        || name.EndsWith(".png", StringComparison.OrdinalIgnoreCase)
        || name.EndsWith(".webp", StringComparison.OrdinalIgnoreCase);

    private static string EncodePath(string path) =>
        string.Join("/", path.Split('/').Select(Uri.EscapeDataString));

    private static string Normalize(string value)
    {
        var s = value.Trim().ToLowerInvariant();
        s = Regex.Replace(s, @"\s+", " ");
        return RemoveDiacritics(s);
    }

    private static string RemoveDiacritics(string text)
    {
        var normalized = text.Normalize(NormalizationForm.FormD);
        var sb = new StringBuilder();
        foreach (var c in normalized)
        {
            if (CharUnicodeInfo.GetUnicodeCategory(c) != UnicodeCategory.NonSpacingMark)
                sb.Append(c);
        }
        return sb.ToString().Normalize(NormalizationForm.FormC);
    }
}

public class FoodImageSyncResult
{
    public string Message { get; set; } = "";
    public int FoldersFound { get; set; }
    public int FoodItemsUpdated { get; set; }
    public int RestaurantsUpdated { get; set; }
    public int TotalFoodItems { get; set; }
    public int TotalRestaurants { get; set; }
}
