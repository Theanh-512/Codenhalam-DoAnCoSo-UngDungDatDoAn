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

# Danh sách hậu tố để làm thực đơn phong phú
SUFFIXES = ["Đặc Biệt", "Truyền Thống", "Thập Cẩm", "Cỡ Lớn", "Vị Cung Đình", "Gia Truyền", "Sốt Cay", "Ít Béo", "Hạng Thương Gia", "Nóng Hổi"]

# Ánh xạ thư mục ảnh vào Danh mục chuẩn (Sẽ được cập nhật chính xác từ Disk)
CATEGORY_GROUPS = {
    "Phở & Bún": ["Pho", "Bun bo Hue", "Bun rieu", "Bun mam", "Bun dau mam tom", "Bun thit nuong", "Hu tieu", "Banh canh"],
    "Cơm": ["Com tam", "Xoi xeo"],
    "Bánh Mì": ["banh mi"],
    "Món Ăn Vặt": ["Banh beo", "banh bo", "banh bot loc", "Banh can", "banh cong", "banh da lon", "Banh duc", "banh khot", "Banh tieu", "Banh trang nuong", "Goi cuon", "Nem chua"],
    "Đặc Sản & Món Mặn": ["Banh chung", "Banh tet", "Banh xeo", "Banh cuon", "Ca kho to", "Canh chua", "Cao lau", "Chao long", "Mi quang"],
    "Tráng Miệng": ["banh pia", "banh tai heo", "banh trung thu", "Banh gio"]
}

def fix_diversity_and_images():
    print("--- Đang tối ưu hóa thực đơn và sửa lỗi hiển thị ảnh ---")
    
    # 1. Lấy danh sách thư mục thực tế trên đĩa để tránh sai tên
    actual_folders = [f for f in os.listdir(IMAGE_DIR) if os.path.isdir(os.path.join(IMAGE_DIR, f))]
    folder_map = {f.lower(): f for f in actual_folders} # Để tra cứu không phân biệt hoa thường

    conn = psycopg2.connect(CONN_STR)
    cur = conn.cursor()
    
    try:
        # Xóa dữ liệu cũ để nạp bản chuẩn nhất
        cur.execute('TRUNCATE TABLE "FoodItems", "Restaurants", "Categories" RESTART IDENTITY CASCADE;')
        
        # 2. Tạo Categories
        categories_data = [(name, f"Các món {name} thơm ngon.", "", datetime.datetime.now()) for name in CATEGORY_GROUPS.keys()]
        extras.execute_values(cur, 'INSERT INTO "Categories" ("Name", "Description", "ImageUrl", "CreatedDate") VALUES %s', categories_data)
        cur.execute('SELECT "Id", "Name" FROM "Categories"')
        cat_db_map = {name: id for id, name in cur.fetchall()}
        
        # 3. Đọc Nhà hàng
        geojson_path = r"d:\DoAnCoSo\DOANCOSO\Codenhalam-DoAnCoSo-UngDungDatDoAn\export.geojson"
        with open(geojson_path, 'r', encoding='utf-8') as f:
            features = json.load(f).get('features', [])[:500]
            
        for i, feat in enumerate(features):
            props = feat.get('properties', {})
            geom = feat.get('geometry', {})
            name = props.get('name', f"Quán ăn {i+1}")
            coords = geom.get('coordinates', [106.7, 10.8])
            
            # Chọn loại nhà hàng
            res_type = "Món Ăn Vặt"
            name_lower = name.lower()
            if any(kw in name_lower for kw in ["phở", "bún", "hủ tiếu"]): res_type = "Phở & Bún"
            elif any(kw in name_lower for kw in ["cơm", "xôi"]): res_type = "Cơm"
            elif "bánh mì" in name_lower: res_type = "Bánh Mì"
            elif any(kw in name_lower for kw in ["nhà hàng", "quán"]): res_type = random.choice(["Phở & Bún", "Cơm", "Đặc Sản & Món Mặn"])
            
            # Lấy ảnh đại diện nhà hàng (Fix URL)
            potential_folders = [folder_map.get(f.lower()) for f in CATEGORY_GROUPS[res_type] if f.lower() in folder_map]
            folder = random.choice(potential_folders) if potential_folders else actual_folders[0]
            encoded_folder = urllib.parse.quote(folder)
            res_img = f"{IMAGE_BASE_URL}/{encoded_folder}/1.jpg"
            
            cur.execute("""
                INSERT INTO "Restaurants" ("Name", "Description", "Address", "ImageUrl", "Latitude", "Longitude", "OpeningHours", "IsActive", "CreatedDate")
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s) RETURNING "Id"
            """, (name, f"Chuyên {res_type} gia truyền.", "TP. Hồ Chí Minh", res_img, coords[1], coords[0], "06:30-22:00", True, datetime.datetime.now()))
            rid = cur.fetchone()[0]
            
            # 4. Tạo thực đơn phong phú cho nhà hàng
            food_items = []
            # Lấy các món chính của quán
            for _ in range(random.randint(5, 8)):
                folder_raw = random.choice(CATEGORY_GROUPS[res_type])
                folder = folder_map.get(folder_raw.lower(), folder_raw)
                
                # Tạo tên món đa dạng
                item_name = f"{folder} {random.choice(SUFFIXES)}"
                img_idx = random.randint(1, 15)
                encoded_folder = urllib.parse.quote(folder)
                img_url = f"{IMAGE_BASE_URL}/{encoded_folder}/{img_idx}.jpg"
                
                food_items.append((
                    item_name, f"Thưởng thức {item_name} thơm ngon tại {name}.",
                    random.randint(35, 150) * 1000, img_url, True, cat_db_map[res_type], rid, round(random.uniform(4.0, 5.0), 1), datetime.datetime.now()
                ))
            
            # Thêm món tráng miệng
            folder = folder_map.get("banh pia", actual_folders[0])
            encoded_folder = urllib.parse.quote(folder)
            food_items.append((
                "Bánh Pía Tráng Miệng", "Món tráng miệng ngọt ngào.",
                25000, f"{IMAGE_BASE_URL}/{encoded_folder}/1.jpg", True, cat_db_map["Tráng Miệng"], rid, 5.0, datetime.datetime.now()
            ))

            extras.execute_values(cur, """
                INSERT INTO "FoodItems" ("Name", "Description", "Price", "ImageUrl", "IsAvailable", "CategoryId", "RestaurantId", "Rating", "CreatedDate")
                VALUES %s
            """, food_items)

        conn.commit()
        print(f"✅ ĐÃ XỬ LÝ XONG: 500 nhà hàng với thực đơn đa dạng và link ảnh chuẩn hóa.")

    except Exception as e:
        conn.rollback()
        print(f"❌ LỖI: {e}")
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    fix_diversity_and_images()
