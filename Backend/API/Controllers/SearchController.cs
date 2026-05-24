using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Infrastructure.Data;
using Npgsql;
using System.Threading.Tasks;
using System.Collections.Generic;

namespace API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class SearchController : ControllerBase
    {
        private readonly FoodAppDbContext _context;

        public SearchController(FoodAppDbContext context)
        {
            _context = context;
        }

        /// <summary>
        /// Tìm món / nhà hàng theo điểm phù hợp (ưu tiên match cả từ + category).
        /// Tránh "phở" → "Phô Mai" do unaccent gộp ở/ô → o.
        /// </summary>
        [HttpGet]
        public async Task<ActionResult> SearchFood([FromQuery] string q)
        {
            if (string.IsNullOrWhiteSpace(q))
            {
                return Ok(new
                {
                    restaurants = System.Array.Empty<object>(),
                    foodItems = System.Array.Empty<object>(),
                });
            }

            var keyword = q.Trim();
            var foodItems = await SearchFoodItemsAsync(keyword);
            var restaurants = await SearchRestaurantsAsync(keyword);

            return Ok(new { restaurants, foodItems });
        }

        private async Task<List<Dictionary<string, object?>>> SearchFoodItemsAsync(string keyword)
        {
            const string sql = @"
                SELECT
                    f.""Id""             AS id,
                    COALESCE(f.""Name"", '')        AS name,
                    COALESCE(f.""Description"", '') AS description,
                    f.""Price""          AS price,
                    COALESCE(f.""ImageUrl"", '')    AS ""imageUrl"",
                    f.""RestaurantId""   AS ""restaurantId"",
                    COALESCE(r.""Name"", '')        AS ""restaurantName"",
                    f.""IsAvailable""    AS ""isAvailable"",
                    f.""CategoryId""     AS ""categoryId"",
                    COALESCE(c.""Name"", '')        AS category,
                    (
                        (CASE WHEN unaccent(COALESCE(c.""Name"", '')) ~* ('\m' || unaccent(@kw) || '\M') THEN 4 ELSE 0 END)
                      + (CASE WHEN unaccent(f.""Name"") ~* ('\m' || unaccent(@kw) || '\M') THEN 3 ELSE 0 END)
                      + (CASE WHEN unaccent(f.""Name"") ILIKE unaccent(@kw || '%') THEN 2 ELSE 0 END)
                      + (CASE WHEN unaccent(f.""Name"") ILIKE unaccent('%' || @kw || '%') THEN 1 ELSE 0 END)
                      + (CASE WHEN unaccent(COALESCE(f.""Description"", '')) ILIKE unaccent('%' || @kw || '%') THEN 1 ELSE 0 END)
                    ) AS score
                FROM ""FoodItems"" f
                JOIN ""Categories"" c ON c.""Id"" = f.""CategoryId""
                LEFT JOIN ""Restaurants"" r ON r.""Id"" = f.""RestaurantId""
                WHERE f.""IsAvailable""
                  AND (
                       unaccent(f.""Name"") ~* ('\m' || unaccent(@kw) || '\M')
                    OR unaccent(COALESCE(c.""Name"", '')) ~* ('\m' || unaccent(@kw) || '\M')
                    OR unaccent(f.""Name"") ILIKE unaccent(@kw || '%')
                    OR unaccent(COALESCE(f.""Description"", '')) ILIKE unaccent('%' || @kw || '%')
                  )
                ORDER BY score DESC, f.""Name"" ASC
                LIMIT 50;";

            return await ExecuteAsync(sql, keyword);
        }

        private async Task<List<Dictionary<string, object?>>> SearchRestaurantsAsync(string keyword)
        {
            const string sql = @"
                SELECT
                    r.""Id""             AS id,
                    COALESCE(r.""Name"", '')        AS name,
                    COALESCE(r.""Description"", '') AS description,
                    COALESCE(r.""ImageUrl"", '')    AS ""imageUrl"",
                    COALESCE(r.""Type1"", '')       AS type1,
                    COALESCE(r.""Type2"", '')       AS type2,
                    r.""Latitude""       AS latitude,
                    r.""Longitude""      AS longitude,
                    COALESCE(r.""OpeningHours"", '') AS ""openingHours"",
                    r.""IsActive""       AS ""isActive"",
                    (
                        (CASE WHEN unaccent(COALESCE(r.""Name"", '')) ~* ('\m' || unaccent(@kw) || '\M') THEN 3 ELSE 0 END)
                      + (CASE WHEN unaccent(COALESCE(r.""Name"", '')) ILIKE unaccent(@kw || '%') THEN 2 ELSE 0 END)
                      + (CASE WHEN unaccent(COALESCE(r.""Name"", '')) ILIKE unaccent('%' || @kw || '%') THEN 1 ELSE 0 END)
                      + (CASE WHEN unaccent(COALESCE(r.""Type1"", '')) ILIKE unaccent('%' || @kw || '%') THEN 1 ELSE 0 END)
                      + (CASE WHEN unaccent(COALESCE(r.""Type2"", '')) ILIKE unaccent('%' || @kw || '%') THEN 1 ELSE 0 END)
                      + (CASE WHEN unaccent(COALESCE(r.""Description"", '')) ILIKE unaccent('%' || @kw || '%') THEN 1 ELSE 0 END)
                    ) AS score
                FROM ""Restaurants"" r
                WHERE r.""IsActive""
                  AND (
                       unaccent(COALESCE(r.""Name"", '')) ILIKE unaccent('%' || @kw || '%')
                    OR unaccent(COALESCE(r.""Type1"", '')) ILIKE unaccent('%' || @kw || '%')
                    OR unaccent(COALESCE(r.""Type2"", '')) ILIKE unaccent('%' || @kw || '%')
                    OR unaccent(COALESCE(r.""Description"", '')) ILIKE unaccent('%' || @kw || '%')
                  )
                ORDER BY score DESC, r.""Name"" ASC
                LIMIT 20;";

            return await ExecuteAsync(sql, keyword);
        }

        private async Task<List<Dictionary<string, object?>>> ExecuteAsync(string sql, string keyword)
        {
            var rows = new List<Dictionary<string, object?>>();
            var conn = _context.Database.GetDbConnection();
            if (conn.State != System.Data.ConnectionState.Open) await conn.OpenAsync();
            await using var cmd = conn.CreateCommand();
            cmd.CommandText = sql;
            var p = cmd.CreateParameter();
            p.ParameterName = "kw";
            p.Value = keyword;
            cmd.Parameters.Add(p);

            await using var reader = await cmd.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                var row = new Dictionary<string, object?>();
                for (var i = 0; i < reader.FieldCount; i++)
                {
                    var value = reader.IsDBNull(i) ? null : reader.GetValue(i);
                    row[reader.GetName(i)] = value;
                }
                rows.Add(row);
            }
            return rows;
        }
    }
}
