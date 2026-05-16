import json
import psycopg2
from psycopg2 import extras
import datetime
import os
import random

# Cấu hình
CONN_STR = "host=aws-1-ap-southeast-2.pooler.supabase.com port=5432 dbname=postgres user=postgres.wbusmwbzqlkyhxtoghsl password=Codenhalam123456 sslmode=require"
SUPABASE_URL = "https://wbusmwbzqlkyhxtoghsl.supabase.co/storage/v1/object/public/food-images"

# Ánh xạ thư mục ảnh vào Danh mục chuẩn
CATEGORY_MAPPING = {
    "Phở & Bún": ["Pho", "Bun bo Hue", "Bun rieu", "Bun mam", "Bun dau mam tom", "Bun thit nuong", "Hu tieu", "Banh canh"],
    "Cơm": ["Com tam", "Xoi xeo"],
    "Bánh Mì": ["banh mi"],
    "Món Ăn Vặt": ["Banh beo", "banh bo", "banh bot loc", "Banh can", "banh cong", "banh da lon", "Banh duc", "banh khot", "Banh tieu", "Banh trang nuong", "Goi cuon", "Nem chua"],
    "Đặc Sản & Món Mặn": ["Banh chung", "Banh tet", "Banh xeo", "Banh cuon", "Ca kho to", "Canh chua", "Cao lau", "Chao long", "Mi quang"],
    "Tráng Miệng": ["banh pia", "banh tai heo", "banh trung thu", "Banh gio"]
}

def restore_and_fix():
    print("--- Đang khôi phục danh mục và chuẩn hóa liên kết nhà hàng ---")
    
    conn = psycopg2.connect(CONN_STR)
    cur = conn.cursor()
    
    try:
        # 1. Làm sạch dữ liệu
        cur.execute('TRUNCATE TABLE "FoodItems", "Restaurants", "Categories" RESTART IDENTITY CASCADE;')
        
        # 2. Nạp Categories "nguyên mẫu"
        categories_to_insert = [
            ("Phở & Bún", "Các món sợi truyền thống Việt Nam", ""),
            ("Cơm", "Cơm tấm, cơm gà và các loại xôi", ""),
            ("Bánh Mì", "Bánh mì đặc sản kẹp thịt, pate", ""),
            ("Món Ăn Vặt", "Các loại bánh dân dã và đồ ăn nhẹ", ""),
            ("Đặc Sản & Món Mặn", "Món ăn gia đình và đặc sản vùng miền", ""),
            ("Tráng Miệng", "Bánh ngọt, chè và đồ tráng miệng", "")
        ]
        
        cat_data = []
        for name, desc, img in categories_to_insert:
            cat_data.append((name, desc, img, datetime.datetime.now()))
            
        extras.execute_values(cur, 'INSERT INTO "Categories" ("Name", "Description", "ImageUrl", "CreatedDate") VALUES %s', cat_data)
        cur.execute('SELECT "Id", "Name" FROM "Categories"')
        cat_map = {name: id for id, name in cur.fetchall()}
        
        # 3. Nạp 500 Nhà hàng từ GeoJSON
        geojson_path = r"d:\DoAnCoSo\DOANCOSO\Codenhalam-DoAnCoSo-UngDungDatDoAn\export.geojson"
        with open(geojson_path, 'r', encoding='utf-8') as f:
            geo_data = json.load(f)
        features = geo_data.get('features', [])
        
        restaurants_to_insert = []
        for i, feat in enumerate(features[:500]):
            props = feat.get('properties', {})
            geom = feat.get('geometry', {})
            name = props.get('name', f"Quán ăn {i}")
            coords = geom.get('coordinates', [106.7, 10.8])
            
            # Xác định loại nhà hàng dựa trên tên để gán thực đơn phù hợp
            res_type = "Món Ăn Vặt" # Mặc định
            if any(kw in name.lower() for kw in ["phở", "bún", "hủ tiếu"]): res_type = "Phở & Bún"
            elif any(kw in name.lower() for kw in ["cơm", "xôi"]): res_type = "Cơm"
            elif "bánh mì" in name.lower(): res_type = "Bánh Mì"
            elif any(kw in name.lower() for kw in ["nhà hàng", "quán"]): res_type = random.choice(["Phở & Bún", "Cơm", "Đặc Sản & Món Mặn"])
            
            # Lấy 1 ảnh đại diện từ loại tương ứng
            folder = random.choice(CATEGORY_MAPPING[res_type])
            res_img = f"{SUPABASE_URL}/{folder.replace(' ', '%20')}/1.jpg"
            
            restaurants_to_insert.append((
                name, f"Chuyên phục vụ các món {res_type} thơm ngon.", "TP. Hồ Chí Minh",
                res_img, coords[1], coords[0], "07:00-21:00", True, datetime.datetime.now(), res_type
            ))

        # Chèn nhà hàng (tạm thời lưu res_type vào biến python)
        for r in restaurants_to_insert:
            cur.execute("""
                INSERT INTO "Restaurants" ("Name", "Description", "Address", "ImageUrl", "Latitude", "Longitude", "OpeningHours", "IsActive", "CreatedDate")
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s) RETURNING "Id"
            """, r[:-1])
            rid = cur.fetchone()[0]
            res_type = r[-1]
            
            # 4. Gắn liền món ăn phù hợp với nhà hàng đó
            food_items = []
            # Lấy tất cả các món thuộc loại của nhà hàng này
            relevant_folders = CATEGORY_MAPPING[res_type]
            
            # Tạo 6-10 món cho quán này
            for _ in range(random.randint(6, 10)):
                folder = random.choice(relevant_folders)
                img_idx = random.randint(1, 20)
                img_url = f"{SUPABASE_URL}/{folder.replace(' ', '%20')}/{img_idx}.jpg"
                
                food_items.append((
                    folder, # Tên món lấy theo tên folder cho chuẩn
                    f"Món {folder} nóng hổi, chuẩn vị, phục vụ tận nơi.",
                    random.randint(25, 120) * 1000,
                    img_url, True, cat_map[res_type], rid, round(random.uniform(4.2, 5.0), 1),
                    datetime.datetime.now()
                ))
            
            # Thêm 1-2 món "tráng miệng" hoặc "uống" cho quán sinh động
            for _ in range(2):
                extra_type = random.choice(["Tráng Miệng", "Món Ăn Vặt"])
                folder = random.choice(CATEGORY_MAPPING[extra_type])
                img_url = f"{SUPABASE_URL}/{folder.replace(' ', '%20')}/1.jpg"
                food_items.append((
                    folder, f"Món ăn kèm/tráng miệng tuyệt vời.",
                    random.randint(15, 45) * 1000, img_url, True, cat_map[extra_type], rid, 5.0, datetime.datetime.now()
                ))

            extras.execute_values(cur, """
                INSERT INTO "FoodItems" ("Name", "Description", "Price", "ImageUrl", "IsAvailable", "CategoryId", "RestaurantId", "Rating", "CreatedDate")
                VALUES %s
            """, food_items)

        conn.commit()
        print("✅ THÀNH CÔNG: Đã khôi phục Categories nguyên mẫu và liên kết thực đơn chuẩn cho 500 nhà hàng.")

    except Exception as e:
        conn.rollback()
        print(f"❌ LỖI: {e}")
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    restore_and_fix()
