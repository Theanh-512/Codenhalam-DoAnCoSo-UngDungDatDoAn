import json
import psycopg2
from psycopg2 import extras
import datetime
import os
import random
import urllib.parse

# Cấu hình
CONN_STR = "host=aws-1-ap-southeast-2.pooler.supabase.com port=5432 dbname=postgres user=postgres.wbusmwbzqlkyhxtoghsl password=Codenhalam123456 sslmode=require"
IMAGE_BASE_URL = "https://wbusmwbzqlkyhxtoghsl.supabase.co/storage/v1/object/public/food-images"
IMAGE_DIR = r"d:\DoAnCoSo\DOANCOSO\Codenhalam-DoAnCoSo-UngDungDatDoAn\Ảnh"

MENU_VARIATIONS = {
    "Phở & Bún": ["Đặc Biệt", "Tái Nạm", "Gà Ta", "Bò Viên", "Thập Cẩm", "Gia Truyền", "Cung Đình"],
    "Cơm": ["Sườn Bì Chả", "Gà Xối Mỡ", "Thịt Kho Tàu", "Đặc Biệt", "Văn Phòng", "Gia Đình"],
    "Bánh Mì": ["Thịt Nguội", "Heo Quay", "Ốp La", "Chả Lụa", "Que Cay", "Pate Đặc Biệt"],
    "Món Ăn Vặt": ["Giòn Tan", "Cay Tê", "Vỉa Hè", "Sốt Me", "Phô Mai", "Truyền Thống"],
    "Đặc Sản & Món Mặn": ["Miền Tây", "Đà Lạt", "Hà Nội", "Xứ Quảng", "Chính Gốc"],
    "Tráng Miệng": ["Thanh Mát", "Ngọt Dịu", "Đặc Sản", "Ít Đường"]
}

CATEGORY_GROUPS = {
    "Phở & Bún": ["Pho", "Bun bo Hue", "Bun rieu", "Bun mam", "Bun dau mam tom", "Bun thit nuong", "Hu tieu", "Banh canh"],
    "Cơm": ["Com tam", "Xoi xeo"],
    "Bánh Mì": ["banh mi"],
    "Món Ăn Vặt": ["Banh beo", "banh bo", "banh bot loc", "Banh can", "banh cong", "banh da lon", "Banh duc", "banh khot", "Banh tieu", "Banh trang nuong", "Goi cuon", "Nem chua"],
    "Đặc Sản & Món Mặn": ["Banh chung", "Banh tet", "Banh xeo", "Banh cuon", "Ca kho to", "Canh chua", "Cao lau", "Chao long", "Mi quang"],
    "Tráng Miệng": ["banh pia", "banh tai heo", "banh trung thu", "Banh gio"]
}

def fix_final_data():
    print("--- Đang quét thư mục ảnh thực tế và nạp dữ liệu chuẩn ---")
    
    folder_files_map = {}
    if not os.path.exists(IMAGE_DIR):
        print(f"❌ Không tìm thấy thư mục ảnh: {IMAGE_DIR}")
        return

    for folder_name in os.listdir(IMAGE_DIR):
        folder_path = os.path.join(IMAGE_DIR, folder_name)
        if os.path.isdir(folder_path):
            files = [f for f in os.listdir(folder_path) if f.lower().endswith(('.jpg', '.jpeg', '.png'))]
            if files:
                folder_files_map[folder_name.lower()] = {
                    "original_name": folder_name,
                    "files": files
                }

    try:
        conn = psycopg2.connect(CONN_STR)
        cur = conn.cursor()
        
        # 🟢 QUAN TRỌNG: Vô hiệu hóa timeout cho phiên làm việc này
        print("Đang cấu hình phiên làm việc (tắt timeout)...")
        cur.execute('SET statement_timeout = 0;')
        
        # Làm sạch dữ liệu cũ
        print("Làm sạch database và cập nhật cấu trúc...")
        cur.execute("""
            DO $$ 
            BEGIN 
                IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Restaurants' AND column_name='Rating') THEN
                    ALTER TABLE "Restaurants" ADD COLUMN "Rating" DOUBLE PRECISION DEFAULT 4.0;
                END IF;
                IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Restaurants' AND column_name='ReviewCount') THEN
                    ALTER TABLE "Restaurants" ADD COLUMN "ReviewCount" INTEGER DEFAULT 0;
                END IF;
            END $$;
        """)
        cur.execute('TRUNCATE TABLE "FoodItems", "Restaurants", "Categories" RESTART IDENTITY CASCADE;')
        
        # 1. Tạo Categories
        print("Tạo danh mục...")
        for cat_name in CATEGORY_GROUPS.keys():
            cur.execute('INSERT INTO "Categories" ("Name", "Description", "CreatedDate") VALUES (%s, %s, %s) RETURNING "Id"',
                       (cat_name, f"Khám phá hương vị {cat_name} đặc sắc.", datetime.datetime.now()))
        
        cur.execute('SELECT "Id", "Name" FROM "Categories"')
        cat_db_map = {name: id for id, name in cur.fetchall()}
        
        # 2. Đọc Nhà hàng từ GeoJSON
        geojson_path = r"d:\DoAnCoSo\DOANCOSO\Codenhalam-DoAnCoSo-UngDungDatDoAn\export.geojson"
        with open(geojson_path, 'r', encoding='utf-8') as f:
            features = json.load(f).get('features', [])[:500]
            
        print(f"Đang nạp {len(features)} nhà hàng...")
        for i, feat in enumerate(features):
            props = feat.get('properties', {})
            geom = feat.get('geometry', {})
            name = props.get('name', f"Quán ăn {i+1}")
            coords = geom.get('coordinates', [106.7, 10.8])
            
            # Phân loại quán
            res_type = "Món Ăn Vặt"
            n_low = name.lower()
            if any(k in n_low for k in ["phở", "bún", "hủ tiếu"]): res_type = "Phở & Bún"
            elif any(k in n_low for k in ["cơm", "xôi"]): res_type = "Cơm"
            elif "bánh mì" in n_low: res_type = "Bánh Mì"
            elif any(k in n_low for k in ["nhà hàng", "quán"]): res_type = random.choice(["Phở & Bún", "Cơm", "Đặc Sản & Món Mặn"])
            
            # Chọn ảnh đại diện nhà hàng
            possible_folders = [f for f in CATEGORY_GROUPS[res_type] if f.lower() in folder_files_map]
            selected_folder_name = random.choice(possible_folders) if possible_folders else list(folder_files_map.keys())[0]
            folder_info = folder_files_map[selected_folder_name.lower()]
            
            img_file = random.choice(folder_info["files"])
            encoded_path = f"{urllib.parse.quote(folder_info['original_name'])}/{urllib.parse.quote(img_file)}"
            res_img = f"{IMAGE_BASE_URL}/{encoded_path}"
            
            # Thêm Rating và ReviewCount ngẫu nhiên
            rating = round(random.uniform(3.5, 5.0), 1)
            review_count = random.randint(10, 500)
            
            cur.execute("""
                INSERT INTO "Restaurants" ("Name", "Description", "Address", "ImageUrl", "Latitude", "Longitude", "OpeningHours", "IsActive", "CreatedDate", "Rating", "ReviewCount")
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s) RETURNING "Id"
            """, (name, f"Đặc sản {res_type} truyền thống.", "TP. Hồ Chí Minh", res_img, coords[1], coords[0], "07:00-22:00", True, datetime.datetime.now(), rating, review_count))
            rid = cur.fetchone()[0]
            
            # 3. Tạo Menu đa dạng
            food_items = []
            for _ in range(random.randint(6, 10)):
                folder_key = random.choice(CATEGORY_GROUPS[res_type]).lower()
                if folder_key not in folder_files_map: continue
                
                f_info = folder_files_map[folder_key]
                item_name = f"{f_info['original_name']} {random.choice(MENU_VARIATIONS[res_type])}"
                img_f = random.choice(f_info["files"])
                enc_p = f"{urllib.parse.quote(f_info['original_name'])}/{urllib.parse.quote(img_f)}"
                
                food_items.append((
                    item_name, f"Hương vị {item_name} thơm ngon đặc sắc.",
                    random.randint(35, 120) * 1000, f"{IMAGE_BASE_URL}/{enc_p}",
                    True, cat_db_map[res_type], rid, round(random.uniform(4.0, 5.0), 1), datetime.datetime.now()
                ))
            
            if food_items:
                extras.execute_values(cur, """
                    INSERT INTO "FoodItems" ("Name", "Description", "Price", "ImageUrl", "IsAvailable", "CategoryId", "RestaurantId", "Rating", "CreatedDate")
                    VALUES %s
                """, food_items)

        conn.commit()
        print(f"✅ THÀNH CÔNG: Đã nạp 500 nhà hàng với thực đơn phong phú và ảnh chuẩn.")

    except Exception as e:
        print(f"❌ LỖI: {e}")
    finally:
        if 'conn' in locals():
            cur.close()
            conn.close()

if __name__ == "__main__":
    fix_final_data()
