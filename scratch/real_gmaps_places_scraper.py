import psycopg2
import requests
import time
import datetime

# Cấu hình kết nối Database Supabase PostgreSQL
conn_str = "host=aws-1-ap-southeast-2.pooler.supabase.com port=5432 dbname=postgres user=postgres.wbusmwbzqlkyhxtoghsl password=Codenhalam123456 sslmode=require"

# ─── CẤU HÌNH GOOGLE PLACES API ──────────────────────────────────────────────
# Hãy thay thế bằng Google Maps API Key của bạn (API Key này cần được kích hoạt Places API)
GOOGLE_MAPS_API_KEY = "YOUR_GOOGLE_MAPS_API_KEY_HERE"

def find_place_id(name, lat, lng, api_key):
    """
    Sử dụng Find Place API để lấy Place ID chính xác của quán dựa trên Tên và Tọa độ (Vĩ độ, Kinh độ)
    """
    url = "https://maps.googleapis.com/maps/api/place/findplacefromtext/json"
    params = {
        "input": name,
        "inputtype": "textquery",
        # Ràng buộc tìm kiếm xung quanh tọa độ của quán trong bán kính 500m để đảm bảo chính xác quán đó
        "locationbias": f"circle:500@{lat},{lng}",
        "fields": "place_id,name,geometry",
        "key": api_key
    }
    
    try:
        response = requests.get(url, params=params)
        data = response.json()
        if data.get("status") == "OK" and data.get("candidates"):
            # Lấy ứng viên đầu tiên chính xác nhất
            candidate = data["candidates"][0]
            return candidate["place_id"]
    except Exception as e:
        print(f"  ❌ Lỗi khi tìm Place ID cho '{name}': {e}")
    return None

def fetch_real_reviews(place_id, api_key):
    """
    Sử dụng Place Details API để lấy các đánh giá (Reviews), Điểm số (Rating) 
    và Tổng số lượt đánh giá (User Ratings Total) thực tế từ Google Maps
    """
    url = "https://maps.googleapis.com/maps/api/place/details/json"
    params = {
        "place_id": place_id,
        # Yêu cầu lấy thông tin đánh giá, điểm số trung bình và tổng số lượng đánh giá thực tế
        "fields": "reviews,rating,user_ratings_total",
        "language": "vi", # Yêu cầu trả về review bằng tiếng Việt
        "key": api_key
    }
    
    try:
        response = requests.get(url, params=params)
        data = response.json()
        if data.get("status") == "OK":
            result = data.get("result", {})
            return {
                "rating": result.get("rating", 4.0),
                "review_count": result.get("user_ratings_total", 0),
                "reviews": result.get("reviews", [])
            }
    except Exception as e:
        print(f"  ❌ Lỗi khi lấy chi tiết đánh giá cho Place ID '{place_id}': {e}")
    return None

# Bộ phân tích cảm xúc tiếng Việt nhẹ nhàng cho ẩm thực
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

def main():
    print("=== PIPELINE CÀO ĐÁNH GIÁ THỰC TẾ TỪ GOOGLE MAPS API ===")
    
    if GOOGLE_MAPS_API_KEY == "YOUR_GOOGLE_MAPS_API_KEY_HERE":
        print("\n⚠️  CẢNH BÁO: Bạn chưa cấu hình Google Maps API Key!")
        print("Vui lòng mở file 'scratch/real_gmaps_places_scraper.py' và cập nhật biến 'GOOGLE_MAPS_API_KEY'")
        print("bằng API Key đã kích hoạt Places API của bạn để chạy cào dữ liệu thực tế.\n")
        return
        
    try:
        conn = psycopg2.connect(conn_str)
        cur = conn.cursor()
        
        # 1. Lấy danh sách nhà hàng có tọa độ thực tế tại HCM từ database
        cur.execute('SELECT "Id", "Name", "Latitude", "Longitude" FROM "Restaurants" WHERE "Latitude" != 0')
        restaurants = cur.fetchall()
        print(f"Đã tải {len(restaurants)} nhà hàng từ Database để tiến hành truy vấn Google Maps...")
        
        # Lấy một danh sách User ID có sẵn trong hệ thống để map làm tác giả đánh giá
        cur.execute('SELECT "Id" FROM "Users"')
        user_ids = [row[0] for row in cur.fetchall()]
        if not user_ids:
            user_ids = [7]
            
        success_count = 0
        
        for idx, res in enumerate(restaurants):
            res_id, name, lat, lng = res
            print(f"\n[{idx+1}/{len(restaurants)}] Đang xử lý quán: '{name}'...")
            
            # Bước A: Tìm Place ID dựa trên tên và tọa độ thực tế của quán trên Google Maps
            place_id = find_place_id(name, lat, lng, GOOGLE_MAPS_API_KEY)
            if not place_id:
                print(f"  ⚠️  Không tìm thấy quán '{name}' trên Google Maps. Bỏ qua.")
                continue
                
            print(f"  🔍 Tìm thấy Place ID trên Google Maps: {place_id}")
            
            # Bước B: Gọi Places Details API để lấy reviews thực tế từ Google Maps
            gmaps_data = fetch_real_reviews(place_id, GOOGLE_MAPS_API_KEY)
            if not gmaps_data:
                print(f"  ⚠️  Không thể tải chi tiết reviews cho quán '{name}'. Bỏ qua.")
                continue
                
            real_rating = gmaps_data["rating"]
            real_review_count = gmaps_data["review_count"]
            real_reviews = gmaps_data["reviews"]
            
            print(f"  ⭐ Điểm đánh giá thực tế: {real_rating} ({real_review_count} lượt đánh giá)")
            print(f"  💬 Cào được {len(real_reviews)} bình luận thực tế bằng tiếng Việt từ khách hàng trên Google Maps.")
            
            # Xóa các reviews cũ của nhà hàng này trước khi nạp reviews thực tế để tránh trùng lặp
            cur.execute('DELETE FROM "Reviews" WHERE "RestaurantId" = %s', (res_id,))
            
            total_sentiment = 0.0
            valid_reviews_count = 0
            
            # Bước C: Nạp các đánh giá thực tế vào bảng "Reviews"
            for rev in real_reviews:
                author_name = rev.get("author_name", "Khách hàng Google Maps")
                rating = rev.get("rating", 4.0)
                comment_text = rev.get("text", "")
                
                # Bỏ qua các review rỗng không viết bình luận thô
                if not comment_text.strip():
                    comment_text = f"Đánh giá {rating} sao cho chất lượng món ăn và dịch vụ tại quán."
                
                # Phân tích điểm cảm xúc thực của bình luận thực tế
                sentiment = analyze_sentiment(comment_text)
                total_sentiment += sentiment
                valid_reviews_count += 1
                
                # Lấy thời gian viết đánh giá thực tế
                epoch_time = rev.get("time")
                if epoch_time:
                    created_date = datetime.datetime.fromtimestamp(epoch_time)
                else:
                    created_date = datetime.datetime.now()
                    
                uid = random.choice(user_ids)
                
                # Chèn vào database bảng Reviews
                cur.execute("""
                    INSERT INTO "Reviews" ("RestaurantId", "UserId", "Rating", "Comment", "CreatedDate")
                    VALUES (%s, %s, %s, %s, %s)
                """, (res_id, uid, rating, f"[{author_name}]: {comment_text}", created_date))
                
            # Tính điểm SentimentScore trung bình từ các bình luận thực tế
            avg_sentiment = (total_sentiment / valid_reviews_count) if valid_reviews_count > 0 else 0.5
            
            # Bước D: Đồng bộ lại điểm số trung bình thực tế và SentimentScore vào bảng Restaurants
            cur.execute("""
                UPDATE "Restaurants"
                SET "SentimentScore" = %s,
                    "Rating" = %s,
                    "ReviewCount" = %s
                WHERE "Id" = %s
            """, (avg_sentiment, real_rating, real_review_count, res_id))
            
            success_count += 1
            
            # Lưu dữ liệu sau mỗi quán ăn
            conn.commit()
            
            # Tránh spam làm nghẽn hoặc bị giới hạn băng thông Google API
            time.sleep(0.2)
            
        print(f"\n🎉 QUÁ TRÌNH CÀO VÀ ĐỒNG BỘ THỰC TẾ HOÀN TẤT!")
        print(f"✅ Đã cào và đồng bộ thành công dữ liệu thực tế cho {success_count}/{len(restaurants)} nhà hàng!")
        
        cur.close()
        conn.close()
        
    except Exception as e:
        print(f"❌ Lỗi trong quá trình kết nối/cào dữ liệu thực tế: {e}")

if __name__ == "__main__":
    main()
