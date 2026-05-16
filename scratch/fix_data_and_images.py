import json
import psycopg2
from psycopg2 import extras
import datetime
import os
import random

# Database configuration
CONN_STR = "host=aws-1-ap-southeast-2.pooler.supabase.com port=5432 dbname=postgres user=postgres.wbusmwbzqlkyhxtoghsl password=Codenhalam123456 sslmode=require"
IMAGE_DIR = r"d:\DoAnCoSo\DOANCOSO\Codenhalam-DoAnCoSo-UngDungDatDoAn\Ảnh"
SUPABASE_URL = "https://wbusmwbzqlkyhxtoghsl.supabase.co/storage/v1/object/public/food-images"

def fix_all_data():
    print("--- Bắt đầu sửa lỗi dữ liệu nghiêm trọng ---")
    
    # 1. Thu thập danh sách món ăn và ảnh từ thư mục địa phương
    food_folders = [f for f in os.listdir(IMAGE_DIR) if os.path.isdir(os.path.join(IMAGE_DIR, f))]
    print(f"Tìm thấy {len(food_folders)} loại món ăn trong thư mục Ảnh.")

    # 2. Đọc dữ liệu GeoJSON
    geojson_path = r"d:\DoAnCoSo\DOANCOSO\Codenhalam-DoAnCoSo-UngDungDatDoAn\export.geojson"
    with open(geojson_path, 'r', encoding='utf-8') as f:
        geo_data = json.load(f)
    features = geo_data.get('features', [])
    
    conn = psycopg2.connect(CONN_STR)
    cur = conn.cursor()
    
    try:
        # Xóa sạch để làm mới hoàn toàn liên kết
        print("Đang dọn dẹp dữ liệu cũ...")
        cur.execute('TRUNCATE TABLE "FoodItems", "Restaurants", "Categories" RESTART IDENTITY CASCADE;')
        
        # 3. Tạo Categories dựa trên tên folder
        print("Đang nạp Categories...")
        categories_data = []
        for folder in food_folders:
            categories_data.append((folder, f"Các món {folder} thơm ngon đặc sản.", "", datetime.datetime.now()))
        
        extras.execute_values(cur, 'INSERT INTO "Categories" ("Name", "Description", "ImageUrl", "CreatedDate") VALUES %s', categories_data)
        cur.execute('SELECT "Id", "Name" FROM "Categories"')
        cat_map = {name: id for id, name in cur.fetchall()}

        # 4. Nạp Nhà hàng
        print(f"Đang nạp {min(len(features), 500)} nhà hàng...")
        restaurants_to_insert = []
        for i, feat in enumerate(features[:500]):
            props = feat.get('properties', {})
            geom = feat.get('geometry', {})
            name = props.get('name', f"Quán ăn {i}")
            coords = geom.get('coordinates', [106.7, 10.8])
            
            # Chọn đại diện 1 ảnh cho nhà hàng
            rand_folder = random.choice(food_folders)
            res_img = f"{SUPABASE_URL}/{rand_folder.replace(' ', '%20')}/1.jpg"
            
            restaurants_to_insert.append((
                name, "Địa điểm ẩm thực uy tín tại TP.HCM", "Hồ Chí Minh",
                res_img, coords[1], coords[0], "06:00-22:00", True, datetime.datetime.now()
            ))

        extras.execute_values(cur, 'INSERT INTO "Restaurants" ("Name", "Description", "Address", "ImageUrl", "Latitude", "Longitude", "OpeningHours", "IsActive", "CreatedDate") VALUES %s', restaurants_to_insert)
        
        cur.execute('SELECT "Id", "Name" FROM "Restaurants"')
        all_res = cur.fetchall()

        # 5. Nạp Món ăn (FoodItems) - ĐÂY LÀ PHẦN QUAN TRỌNG NHẤT ĐỂ FIX LỖI
        print("Đang nạp thực đơn cho từng quán...")
        food_items_to_insert = []
        for rid, rname in all_res:
            # Mỗi quán cho 5-10 món ngẫu nhiên từ các folder
            num_dishes = random.randint(5, 10)
            selected_folders = random.sample(food_folders, num_dishes)
            
            for folder in selected_folders:
                # Lấy 1 ảnh ngẫu nhiên từ folder (giả sử có từ 1.jpg đến 20.jpg)
                img_idx = random.randint(1, 15)
                img_url = f"{SUPABASE_URL}/{folder.replace(' ', '%20')}/{img_idx}.jpg"
                
                food_items_to_insert.append((
                    folder, # Tên món lấy theo tên folder
                    f"Món {folder} được chế biến theo công thức gia truyền, nguyên liệu tươi sạch.",
                    random.randint(35, 150) * 1000, # Giá từ 35k - 150k
                    img_url, True, cat_map[folder], rid, round(random.uniform(4.0, 5.0), 1),
                    datetime.datetime.now()
                ))

        extras.execute_values(cur, """
            INSERT INTO "FoodItems" 
            ("Name", "Description", "Price", "ImageUrl", "IsAvailable", "CategoryId", "RestaurantId", "Rating", "CreatedDate") 
            VALUES %s
        """, food_items_to_insert)
        
        conn.commit()
        print(f"✅ THÀNH CÔNG: Đã nạp {len(all_res)} nhà hàng và {len(food_items_to_insert)} món ăn.")
        print("Link ảnh đã được cấu hình theo cấu trúc Supabase Storage.")

    except Exception as e:
        conn.rollback()
        print(f"❌ LỖI: {e}")
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    fix_all_data()
