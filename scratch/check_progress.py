import psycopg2
import os

# Kết nối cơ sở dữ liệu Supabase
conn_str = "host=aws-1-ap-southeast-2.pooler.supabase.com port=5432 dbname=postgres user=postgres.wbusmwbzqlkyhxtoghsl password=Codenhalam123456 sslmode=require"

def main():
    try:
        conn = psycopg2.connect(conn_str)
        cur = conn.cursor()
        
        # 1. Tổng số nhà hàng
        cur.execute('SELECT COUNT(*) FROM "Restaurants"')
        total_res = cur.fetchone()[0]
        
        # 2. Số nhà hàng đã có ít nhất 1 đánh giá
        cur.execute('SELECT COUNT(DISTINCT "RestaurantId") FROM "Reviews"')
        res_with_reviews = cur.fetchone()[0]
        
        # 3. Số nhà hàng đã có đủ từ 5 đánh giá trở lên
        cur.execute('''
            SELECT COUNT(*) FROM (
                SELECT "RestaurantId" 
                FROM "Reviews" 
                GROUP BY "RestaurantId" 
                HAVING COUNT(*) >= 5
            ) AS subquery
        ''')
        res_full_reviews = cur.fetchone()[0]
        
        # 4. Tổng số đánh giá trong hệ thống
        cur.execute('SELECT COUNT(*) FROM "Reviews"')
        total_reviews = cur.fetchone()[0]
        
        # 5. Điểm đánh giá trung bình toàn hệ thống
        cur.execute('SELECT AVG("Rating") FROM "Reviews"')
        avg_rating = cur.fetchone()[0] or 0.0
        
        # 6. Đánh giá mới nhất vừa được thêm vào
        cur.execute('''
            SELECT r."Name", rev."Rating", rev."Comment", rev."CreatedDate" 
            FROM "Reviews" rev
            JOIN "Restaurants" r ON rev."RestaurantId" = r."Id"
            ORDER BY rev."CreatedDate" DESC, rev."Id" DESC
            LIMIT 1
        ''')
        latest = cur.fetchone()
        
        # Tính toán tỷ lệ phần trăm tiến độ
        pct = (res_full_reviews / total_res * 100) if total_res > 0 else 0
        bar_len = 30
        filled_len = int(bar_len * pct / 100)
        bar = '█' * filled_len + '░' * (bar_len - filled_len)
        
        # In Dashboard tiến độ
        print("\n" + "="*60)
        print("📊 ĐỒNG HỒ ĐO TIẾN ĐỘ BỒ SUNG ĐÁNH GIÁ (SUPABASE METRICS)")
        print("="*60)
        print(f"📈 Tiến độ quán đủ >= 5 đánh giá: [{bar}] {pct:.1f}%")
        print(f"   - Đã phủ đủ đánh giá:  {res_full_reviews} / {total_res} nhà hàng")
        print(f"   - Đã có ít nhất 1 review: {res_with_reviews} / {total_res} nhà hàng")
        print(f"   - Tổng số review hiện có: {total_reviews} bình luận")
        print(f"   - Điểm đánh giá TB:       {avg_rating:.2f} ⭐")
        print("-"*60)
        
        if latest:
            name, score, comment, date = latest
            print("🔔 Hoạt động cào/sinh đánh giá mới nhất vừa ghi nhận:")
            print(f"   - Nhà hàng: {name}")
            print(f"   - Số sao:   {score} ⭐")
            # Trích xuất ngắn bình luận cho đỡ dài dòng
            short_comment = comment[:100] + "..." if len(comment) > 100 else comment
            print(f"   - Nội dung: {short_comment}")
            print(f"   - Thời gian: {date}")
        else:
            print("❌ Chưa có đánh giá nào được thêm.")
        print("="*60 + "\n")
        
        cur.close()
        conn.close()
    except Exception as e:
        print(f"❌ Lỗi khi đọc tiến độ: {e}")

if __name__ == "__main__":
    main()
