import os
import csv
import random
import datetime

# Cấu hình đường dẫn
DATA_DIR = os.path.dirname(os.path.abspath(__file__))
IMAGE_ROOT = os.path.join(DATA_DIR, "raw_images", "vietnamese-foods", "Images", "Train")
META_FILE = os.path.join(DATA_DIR, "items_meta.csv")
INTERACTION_FILE = os.path.join(DATA_DIR, "interactions.csv")

NUM_USERS = 1000
NUM_INTERACTIONS = 10000

def generate_dataset():
    global IMAGE_ROOT
    if not os.path.exists(IMAGE_ROOT):
        print(f"Directory {IMAGE_ROOT} not found.")
        # Generate dummy images for testing while Kaggle dataset downloads
        print("Generating 30 dummy food categories for immediate pipeline testing...")
        IMAGE_ROOT = os.path.join(DATA_DIR, "raw_images", "dummy_foods")
        os.makedirs(IMAGE_ROOT, exist_ok=True)
        
        dummy_categories = [f"Food_{i}" for i in range(30)]
        for cat in dummy_categories:
            cat_dir = os.path.join(IMAGE_ROOT, cat)
            os.makedirs(cat_dir, exist_ok=True)
            # Create a simple colored dummy image
            from PIL import Image
            img = Image.new('RGB', (224, 224), color = (random.randint(0,255), random.randint(0,255), random.randint(0,255)))
            img.save(os.path.join(cat_dir, "dummy_1.jpg"))
            img.save(os.path.join(cat_dir, "dummy_2.jpg"))

    categories = []
    item_mapping = {}
    
    # 1. Quét thư mục ảnh và tạo meta
    print("1. Quét thư mục ảnh và tạo Meta Data...")
    item_id_counter = 0
    if os.path.exists(IMAGE_ROOT):
        for entry in sorted(os.listdir(IMAGE_ROOT)):
            full_path = os.path.join(IMAGE_ROOT, entry)
            if os.path.isdir(full_path):
                # Lấy 1 ảnh đại diện
                images = [f for f in os.listdir(full_path) if f.endswith(('.jpg', '.jpeg', '.png'))]
                if images:
                    rep_image = os.path.join(entry, images[0])
                    # Lưu trữ tất cả ảnh của category này để random khi sinh tương tác
                    item_mapping[item_id_counter] = {
                        "name": entry,
                        "rep_image": rep_image,
                        "all_images": [os.path.join(entry, img) for img in images]
                    }
                    categories.append(item_id_counter)
                    item_id_counter += 1
    
    if not item_mapping:
        print("CẢNH BÁO: Không tìm thấy ảnh nào. Sẽ dùng dummy data nếu tiếp tục.")
        return

    with open(META_FILE, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(["item_id", "food_name", "image_path"])
        for iid, data in item_mapping.items():
            writer.writerow([iid, data["name"], data["rep_image"]])
    
    print(f"Đã lưu {len(item_mapping)} món ăn vào {META_FILE}")

    # 2. Sinh dữ liệu tương tác giả lập
    print("2. Sinh dữ liệu tương tác giả lập...")
    base_time = datetime.datetime.now() - datetime.timedelta(days=30)
    
    with open(INTERACTION_FILE, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(["user_id", "item_id", "timestamp", "lat", "lon", "image_path"])
        
        for _ in range(NUM_INTERACTIONS):
            user_id = random.randint(0, NUM_USERS - 1)
            item_id = random.choice(categories)
            
            # Thời gian random trong 30 ngày qua
            offset = datetime.timedelta(
                days=random.randint(0, 30),
                hours=random.randint(0, 23),
                minutes=random.randint(0, 59)
            )
            interact_time = base_time + offset
            timestamp_str = interact_time.strftime("%Y-%m-%dT%H:%M:%S")
            
            # Tọa độ giả lập xung quanh TP.HCM
            lat = 10.762622 + random.uniform(-0.1, 0.1)
            lon = 106.660172 + random.uniform(-0.1, 0.1)
            
            # Chọn 1 ảnh ngẫu nhiên của món ăn này
            img_path = random.choice(item_mapping[item_id]["all_images"])
            
            writer.writerow([user_id, item_id, timestamp_str, lat, lon, img_path])

    print(f"Đã lưu {NUM_INTERACTIONS} lượt tương tác vào {INTERACTION_FILE}")

if __name__ == "__main__":
    generate_dataset()
