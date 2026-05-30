import psycopg2
import requests
import time
import datetime
import random

# Kết nối cơ sở dữ liệu Supabase
conn_str = "host=aws-1-ap-southeast-2.pooler.southeast-2.pooler.supabase.com port=5432 dbname=postgres user=postgres.wbusmwbzqlkyhxtoghsl password=Codenhalam123456 sslmode=require"
# Sửa lại URL chuẩn của host Supabase của bạn
conn_str = "host=aws-1-ap-southeast-2.pooler.supabase.com port=5432 dbname=postgres user=postgres.wbusmwbzqlkyhxtoghsl password=Codenhalam123456 sslmode=require"

SERPAPI_KEY = "6b2e2613c00071b625f6ce29dc9becea1e9814c72d122d080f4c045e5562ee9c"

# Định nghĩa ngoại lệ khi hết lượt miễn phí
class QuotaExceededError(Exception):
    pass

# ─── BỘ SINH BÌNH LUẬN DỰ PHÒNG CHẤT LƯỢNG CAO (SMART FALLBACK GENERATOR) ─────
STARTERS = [
    "Hôm nay mình có ghé quán ăn thử,",
    "Được bạn đồng nghiệp giới thiệu nên qua ăn,",
    "Nhà mình hay đặt quán này trên app giao nhanh,",
    "Cuối tuần rủ cả gia đình đi ăn,",
    "Tiện đường đi làm về ghé ăn tối,",
    "Quán quen của mình suốt 3 tháng nay,",
    "Trải nghiệm lần đầu tiên tại quán,",
    "Hôm nay đổi gió đi ăn cùng người yêu,",
    "Được hôm thèm món này quá nên ghé đại,",
    "Đặt món qua app thấy giao hàng nhanh, hộp sạch sẽ,"
]

FOOD_PRESETS = {
    "PHO_BUN": {
        "food": ["tô phở bò tái nạm", "phở gà ta", "bún bò Huế giò chả", "hủ tiếu Nam Vang"],
        "taste_pos": [
            "nước dùng ngọt thanh từ xương, bò tái mềm ngọt thơm.",
            "nước lèo nóng hổi, thơm mùi sả ớt đậm đà đúng điệu miền Trung.",
            "sợi bún dai dai, miếng giò to nạc ăn sướng miệng.",
            "nước súp trong và ngọt, tôm mực tươi rói."
        ],
        "taste_neg": [
            "nước dùng hơi lạt và nguội, thịt bò hơi dai.",
            "vị nước dùng hơi ngọt quá so với khẩu vị của mình.",
            "phần bún hơi ít, ăn chưa đủ no.",
            "nước dùng nhiều mỡ quá ăn hơi ngấy."
        ]
    },
    "RICE": {
        "food": ["đĩa cơm tấm sườn bì chả", "cơm gà xối mỡ", "cơm niêu"],
        "taste_pos": [
            "sườn nướng ướp đậm đà, thơm nức mũi, hạt cơm dẻo thơm.",
            "thịt gà da giòn rụm, thịt bên trong mềm mọng nước.",
            "cơm niêu cháy giòn đều, cá kho tộ đậm đà rất đưa cơm."
        ],
        "taste_neg": [
            "cơm tấm hơi bị khô, sườn nướng bị cháy cạnh nhiều.",
            "gà chiên nhiều dầu quá ăn mau ngán.",
            "cơm niêu hơi cháy quá tay, cá kho hơi mặn."
        ]
    },
    "FAST_FOOD": {
        "food": ["pizza hải sản viền phô mai", "đĩa mì Ý sốt bò băm", "combo gà rán giòn"],
        "taste_pos": [
            "đế bánh giòn xốp, phô mai ngập tràn kéo sợi béo ngậy.",
            "sốt bò băm đậm đà nhiều thịt, mì Ý luộc vừa tới chín.",
            "lớp da gà giòn rụm bên ngoài, thịt đùi mềm ngọt bên trong."
        ],
        "taste_neg": [
            "đế pizza hơi cứng và khô, ít nhân hải sản.",
            "sốt mì Ý hơi bị chua quá so với gu của mình.",
            "gà rán chiên bị khô cứng, da không còn giòn."
        ]
    },
    "JAP_KOR": {
        "food": ["sushi tổng hợp", "thịt ba chỉ bò nướng BBQ", "lẩu kim chi"],
        "taste_pos": [
            "cá tươi rói ngọt thịt, trang trí rất nghệ thuật bắt mắt.",
            "thịt bò nướng ướp sốt Hàn Quốc đậm đà nướng xèo xèo thơm phức.",
            "nước lẩu kim chi chua cay đậm đà, nhúng thịt ba chỉ rất hợp vị."
        ],
        "taste_neg": [
            "cá hồi cắt hơi mỏng, cơm sushi nén chưa chặt.",
            "vỉ nướng hơi nhanh cháy, thịt thái mỏng quá.",
            "nước lẩu hơi cay nồng quá, kim chi hơi chua gắt."
        ]
    },
    "DRINK_CAFE": {
        "food": ["ly trà sữa trân châu hoàng kim", "ly cà phê sữa đá", "trà đào cam sả"],
        "taste_pos": [
            "trà thơm đậm vị, trân châu dai dẻo hoàng kim ngọt nhẹ béo ngậy.",
            "cà phê thơm nồng đậm đặc, đậm vị truyền thống tỉnh cả người.",
            "vị thanh mát của trà đào hòa quyện sả thơm mát lạnh sảng khoái."
        ],
        "taste_neg": [
            "trà sữa hơi ngọt gắt, trân châu bị cứng ở lõi.",
            "cà phê sữa hơi ngọt quá và ít cà phê.",
            "trà đào hơi nhạt vị đào, đá nhiều quá uống nhạt."
        ]
    },
    "DEFAULT": {
        "food": ["món ăn đặc sản của quán", "combo món ăn gia đình", "đồ ăn nhẹ"],
        "taste_pos": [
            "chế biến rất vừa miệng, trình bày sạch sẽ chỉn chu.",
            "mọi nguyên liệu tươi ngon, nêm nếm gia vị đậm đà vừa ăn.",
            "hương vị đặc trưng không lẫn đi đâu được, rất hợp khẩu vị."
        ],
        "taste_neg": [
            "nêm nếm hơi bình thường, không có gì nổi bật lắm.",
            "đồ ăn nguội lạnh khi bưng ra, trình bày hơi sơ sài.",
            "vị hơi lạt, phải nêm thêm nước tương mới vừa ăn."
        ]
    }
}

ENVIRONMENTS = [
    "Không gian quán rộng rãi thoáng mát,",
    "Quán máy lạnh sạch sẽ, trang trí ấm cúng thích hợp gia đình,",
    "Địa điểm dễ tìm, có chỗ giữ xe miễn phí rộng rãi,",
    "Quán hơi nhỏ một chút vào giờ cao điểm nhưng bù lại sạch sẽ,",
    "View quán khá xinh, bàn ghế được lau chùi sạch bong,",
    "Không gian hơi ồn ào tí do đông khách,",
    "Không gian quán thoáng mát, bày trí lịch sự,"
]

SERVICES = [
    "nhân viên phục vụ nhanh nhẹn và rất nhiệt tình.",
    "mấy bạn phục vụ lịch sự dễ thương cực kỳ.",
    "đồ ăn lên nhanh nóng hổi dù quán đang rất đông khách.",
    "phục vụ chu đáo, hay chủ động châm trà nước cho khách.",
    "chủ quán nhiệt tình hỏi han ý kiến khách hàng.",
    "phục vụ hơi chậm một chút nhưng thái độ nhân viên rất lịch sự."
]

CONCLUSIONS = [
    "Sẽ ủng hộ quán dài dài.",
    "Rất đáng đồng tiền bát gạo, đánh giá cao quán này!",
    "Highly recommend mọi người qua ăn thử nhé.",
    "Rất hài lòng về chất lượng dịch vụ của quán.",
    "Đánh giá 5 sao cho sự chỉn chu này.",
    "Điểm cộng là giá cả siêu hợp lý.",
    "Chắc chắn sẽ ghé lại nhiều lần."
]

def get_preset_category(name):
    name_lower = name.lower()
    if any(k in name_lower for k in ["phở", "bún", "hủ tiếu", "mì huê", "miến", "lẩu nấm"]):
        return "PHO_BUN"
    elif any(k in name_lower for k in ["cơm", "tân cảng", "hoàng ký", "bên sông", "món huế", "quán ăn", "nhà hàng"]):
        return "RICE"
    elif any(k in name_lower for k in ["pizza", "gà rán", "kfc", "lotteria", "sumo", "bbq", "nướng"]):
        return "FAST_FOOD"
    elif any(k in name_lower for k in ["sushi", "sashimi", "tokbokki", "korean", "japan", "mì cay"]):
        return "JAP_KOR"
    elif any(k in name_lower for k in ["cà phê", "cafe", "trà sữa", "the loop", "loop", "highlands", "starbucks"]):
        return "DRINK_CAFE"
    return "DEFAULT"

def generate_human_like_review(restaurant_name, rating):
    cat = get_preset_category(restaurant_name)
    preset = FOOD_PRESETS[cat]
    starter = random.choice(STARTERS)
    food_item = random.choice(preset["food"])
    
    if rating >= 4.0:
        taste = random.choice(preset["taste_pos"])
    else:
        taste = random.choice(preset["taste_neg"])
        
    env = random.choice(ENVIRONMENTS)
    svc = random.choice(SERVICES)
    conclusion = random.choice(CONCLUSIONS)
    
    return f"{starter} gọi {food_item}. Cảm nhận là {taste} {env} {svc} {conclusion}"

POS_WORDS = ["ngon", "tuyệt vời", "xuất sắc", "đậm đà", "sạch sẽ", "nóng hổi", "thơm ngon", "tươi ngon", "rẻ", "hợp lý", "chu đáo", "thân thiện", "nhiệt tình", "nhanh chóng", "ưng ý", "hài lòng", "quay lại", "ủng hộ", "đặc sắc", "vừa vị"]
NEG_WORDS = ["tệ", "dở", "nhạt", "nguội", "bẩn", "chậm", "đắt", "thái độ", "kém", "ít", "tanh", "thất vọng", "không ngon", "khó ăn", "dai", "mắc", "lạt"]

def analyze_sentiment(comment):
    if not comment:
        return 0.5
    comment_lower = comment.lower()
    pos_count = sum(1 for word in POS_WORDS if word in comment_lower)
    neg_count = sum(1 for word in NEG_WORDS if word in comment_lower)
    total = pos_count + neg_count
    if total == 0:
        return 0.5
    score = (pos_count - neg_count) / total
    return max(0.0, min(1.0, 0.5 + (score * 0.5)))

# ─── TRUY VẤN SERPAPI ────────────────────────────────────────────────────────
def search_restaurant_on_serpapi(name, lat, lng):
    url = "https://serpapi.com/search.json"
    params = {
        "engine": "google_maps",
        "q": name,
        "ll": f"@{lat},{lng},16z",
        "type": "search",
        "hl": "vi",
        "api_key": SERPAPI_KEY
    }
    
    try:
        response = requests.get(url, params=params)
        data = response.json()
        
        # Check quota error
        if "error" in data:
            if "out of searches" in data["error"].lower() or "limit" in data["error"].lower():
                raise QuotaExceededError()
                
        place_results = data.get("place_results", {})
        if place_results:
            return place_results.get("place_id"), place_results.get("data_id")
            
        local_results = data.get("local_results", [])
        if local_results:
            first_match = local_results[0]
            return first_match.get("place_id"), first_match.get("data_id")
    except QuotaExceededError:
        raise
    except Exception as e:
        print(f"  ❌ Lỗi kết nối tìm kiếm: {e}")
    return None, None

def fetch_real_reviews_via_serpapi(place_id, data_id):
    url = "https://serpapi.com/search.json"
    params = {
        "engine": "google_maps_reviews",
        "hl": "vi",
        "api_key": SERPAPI_KEY
    }
    
    if place_id:
        params["place_id"] = place_id
    elif data_id:
        params["data_id"] = data_id
    else:
        return None
        
    try:
        response = requests.get(url, params=params)
        data = response.json()
        
        # Check quota error
        if "error" in data:
            if "out of searches" in data["error"].lower() or "limit" in data["error"].lower():
                raise QuotaExceededError()
                
        place_info = data.get("place_info", {})
        rating = place_info.get("rating", 4.0)
        review_count = place_info.get("reviews", 0)
        reviews = data.get("reviews", [])
        
        return {
            "rating": rating,
            "review_count": review_count,
            "reviews": reviews
        }
    except QuotaExceededError:
        raise
    except Exception as e:
        print(f"  ❌ Lỗi kết nối reviews: {e}")
    return None

def main():
    print("=== PIPELINE ĐỒNG BỘ HYBRID GOOGLE MAPS REVIEWS (SERPAPI + FALLBACK SMART GENERATOR) ===")
    
    fallback_active = False
    
    try:
        conn = psycopg2.connect(conn_str)
        cur = conn.cursor()
        
        # Tải TOÀN BỘ nhà hàng từ cơ sở dữ liệu
        cur.execute('SELECT "Id", "Name", "Latitude", "Longitude", "Rating" FROM "Restaurants" ORDER BY "Id" ASC')
        restaurants = cur.fetchall()
        print(f"Đã tải {len(restaurants)} nhà hàng hoạt động từ database để đồng bộ...")
        
        cur.execute('SELECT "Id" FROM "Users"')
        user_ids = [row[0] for row in cur.fetchall()]
        if not user_ids:
            user_ids = [7]
            
        success_count = 0
        real_count = 0
        fallback_count = 0
        
        for idx, res in enumerate(restaurants):
            res_id, name, lat, lng, current_rating = res
            
            # Kiểm tra số lượng review hiện có của quán này
            cur.execute('SELECT COUNT(*) FROM "Reviews" WHERE "RestaurantId" = %s', (res_id,))
            review_count_existing = cur.fetchone()[0]
            
            if review_count_existing >= 8:
                print(f"[{idx+1}/{len(restaurants)}] ✅ Quán '{name}' đã có đầy đủ {review_count_existing} đánh giá. Bỏ qua.")
                continue
                
            print(f"\n[{idx+1}/{len(restaurants)}] Đang đồng bộ quán thiếu đánh giá: '{name}' (Hiện có: {review_count_existing})...")
            
            # Xóa các review cũ để tránh trùng lặp
            cur.execute('DELETE FROM "Reviews" WHERE "RestaurantId" = %s', (res_id,))
            
            # A. Luồng chính: Sử dụng SerpApi cào dữ liệu thật từ Google Maps (nếu chưa hết quota)
            if not fallback_active:
                try:
                    place_id, data_id = search_restaurant_on_serpapi(name, lat, lng)
                    if place_id or data_id:
                        gmaps_data = fetch_real_reviews_via_serpapi(place_id, data_id)
                        if gmaps_data and gmaps_data["reviews"]:
                            real_rating = gmaps_data["rating"]
                            real_review_count = gmaps_data["review_count"]
                            real_reviews = gmaps_data["reviews"]
                            
                            print(f"  ⭐ [SerpApi] Điểm Google thật: {real_rating} ({real_review_count} lượt đánh giá)")
                            
                            total_sentiment = 0.0
                            valid_reviews_count = 0
                            
                            for rev in real_reviews[:5]:
                                user_info = rev.get("user", {})
                                author_name = user_info.get("name", "Khách hàng Google Maps")
                                rating = rev.get("rating", 4.0)
                                comment_text = rev.get("snippet", "")
                                
                                if not comment_text.strip():
                                    comment_text = f"Đánh giá {rating} sao cho chất lượng dịch vụ và đồ ăn của quán."
                                    
                                sentiment = analyze_sentiment(comment_text)
                                total_sentiment += sentiment
                                valid_reviews_count += 1
                                
                                created_date = datetime.datetime.now()
                                uid = random.choice(user_ids)
                                
                                cur.execute("""
                                    INSERT INTO "Reviews" ("RestaurantId", "UserId", "Rating", "Comment", "CreatedDate")
                                    VALUES (%s, %s, %s, %s, %s)
                                """, (res_id, uid, rating, f"[{author_name}]: {comment_text}", created_date))
                                
                            avg_sentiment = (total_sentiment / valid_reviews_count) if valid_reviews_count > 0 else 0.5
                            
                            cur.execute("""
                                UPDATE "Restaurants"
                                SET "SentimentScore" = %s,
                                    "Rating" = %s,
                                    "ReviewCount" = %s
                                WHERE "Id" = %s
                            """, (avg_sentiment, real_rating, real_review_count, res_id))
                            
                            real_count += 1
                            success_count += 1
                            conn.commit()
                            time.sleep(0.3)
                            continue
                            
                except QuotaExceededError:
                    print("\n⚠️ CHÚ Ý: Tài khoản SerpApi của bạn đã hết lượt tìm kiếm miễn phí (Quota Limit 100/month)!")
                    print("🤖 Tự động kích hoạt luồng Dự phòng thông minh (Fallback Smart Review Generator)...")
                    fallback_active = True
                except Exception as e:
                    print(f"  ⚠️ Lỗi kết nối API: {e}. Tự động dùng fallback.")
                    
            # B. Luồng dự phòng thông minh (Fallback Smart Generator): Tự động sinh đánh giá tiếng Việt độc nhất 100% tự nhiên
            num_reviews = random.randint(7, 10)
            total_sentiment = 0.0
            
            for _ in range(num_reviews):
                rating_offset = random.uniform(-0.4, 0.4)
                gmaps_rating = round(max(1.0, min(5.0, current_rating + rating_offset)), 1)
                
                comment = generate_human_like_review(name, gmaps_rating)
                sentiment = analyze_sentiment(comment)
                total_sentiment += sentiment
                
                days_ago = random.randint(1, 30)
                created_date = datetime.datetime.now() - datetime.timedelta(days=days_ago)
                uid = random.choice(user_ids)
                
                cur.execute("""
                    INSERT INTO "Reviews" ("RestaurantId", "UserId", "Rating", "Comment", "CreatedDate")
                    VALUES (%s, %s, %s, %s, %s)
                """, (res_id, uid, gmaps_rating, comment, created_date))
                
            avg_sentiment = total_sentiment / num_reviews
            
            cur.execute("""
                UPDATE "Restaurants"
                SET "SentimentScore" = %s,
                    "ReviewCount" = %s,
                    "Rating" = %s
                WHERE "Id" = %s
            """, (avg_sentiment, num_reviews, current_rating, res_id))
            
            fallback_count += 1
            success_count += 1
            
            # Lưu theo lô nhỏ để tăng tốc độ ghi DB
            if (idx + 1) % 50 == 0 or (idx + 1) == len(restaurants):
                print(f" -> Đang tiến hành lưu trữ dữ liệu... ({idx + 1}/{len(restaurants)} quán)")
                conn.commit()
                
        conn.commit()
        print(f"\n🎉 HOÀN TẤT ĐỒNG BỘ TOÀN BỘ CƠ SỞ DỮ LIỆU ĐỒ AN!")
        print(f"✅ Tổng số nhà hàng được xử lý: {success_count}/{len(restaurants)}")
        print(f"   - 🌟 Đồng bộ thật qua SerpApi: {real_count} nhà hàng")
        print(f"   - 🤖 Đồng bộ qua Fallback Smart Generator: {fallback_count} nhà hàng")
        
        cur.close()
        conn.close()
        
    except Exception as e:
        print(f"❌ Lỗi nghiêm trọng: {e}")

if __name__ == "__main__":
    main()
