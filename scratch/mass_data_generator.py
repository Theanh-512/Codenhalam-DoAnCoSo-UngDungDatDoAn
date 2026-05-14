import psycopg2
import random
import time

conn_str = "host=aws-1-ap-southeast-2.pooler.supabase.com port=5432 dbname=postgres user=postgres.wbusmwbzqlkyhxtoghsl password=Codenhalam123456 sslmode=require"

FOOD_TEMPLATES = [
    ("Phở Bò", ["Phở bò truyền thống với nước dùng hầm xương 24h.", "Phở tái lăn thơm nức mũi, chuẩn vị Nam Định.", "Phở bò đặc biệt với đầy đủ tái, nạm, gầu, gân."]),
    ("Bún Chả", ["Bún chả Hà Nội nướng than hoa thơm lừng.", "Sự kết hợp hoàn hảo giữa chả viên và chả miếng.", "Nước mắm chua ngọt đậm đà, ăn kèm rau sống tươi ngon."]),
    ("Cơm Tấm", ["Cơm tấm sườn bì chả đặc sản Sài Gòn.", "Sườn nướng mật ong mềm mại, thấm vị.", "Ăn kèm đồ chua và nước mắm kẹo đặc trưng."]),
    ("Bánh Mì", ["Bánh mì thịt nguội giòn rụm, đầy đặn nhân.", "Bánh mì heo quay da giòn, nước sốt độc quyền.", "Bánh mì trứng ốp la nóng hổi cho bữa sáng năng lượng."]),
    ("Mì Ý", ["Mì Ý sốt bò băm Bolognese truyền thống.", "Mì Ý hải sản sốt kem béo ngậy.", "Mì Ý Carbonara với thịt xông khói giòn tan."]),
    ("Pizza", ["Pizza Hải Sản sốt Pesto xanh mát.", "Pizza Gà Nướng nấm thơm nức.", "Pizza 4 loại phô mai tan chảy béo ngậy."]),
    ("Gà Rán", ["Gà rán giòn tan sốt cay Hàn Quốc.", "Gà rán truyền thống da giòn thịt mềm.", "Gà rán sốt mật ong tỏi thơm lừng."]),
    ("Trà Sữa", ["Trà sữa trân châu đường đen đậm vị trà.", "Trà trái cây nhiệt đới giải nhiệt mùa hè.", "Lục trà sữa thạch sương sáo thanh mát."])
]

REVIEW_TEMPLATES = [
    "Món ăn rất ngon, đóng gói cẩn thận.",
    "Giao hàng nhanh, shipper thân thiện.",
    "Hương vị đậm đà, giá cả hợp lý.",
    "Sẽ quay lại ủng hộ quán lần sau.",
    "Quán sạch sẽ, nhân viên nhiệt tình.",
    "Món phở ở đây nước dùng rất trong và ngọt.",
    "Pizza giòn, nhiều phô mai, cực kỳ hài lòng.",
    "Trà sữa hơi ngọt so với khẩu vị của mình nhưng trân châu ngon."
]

IMAGE_POOL = [
    "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=600",
    "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=600",
    "https://images.unsplash.com/photo-1567620905732-2d1ec7bb7445?q=80&w=600",
    "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?q=80&w=600",
    "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?q=80&w=600",
    "https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?q=80&w=600",
    "https://images.unsplash.com/photo-1482049016688-2d3e1b311543?q=80&w=600",
    "https://images.unsplash.com/photo-1484723088339-32383369d5bb?q=80&w=600"
]

def seed_data():
    conn = psycopg2.connect(conn_str)
    cur = conn.cursor()
    cur.execute('SET statement_timeout = 0') # Disable timeout for long seeding
    
    print("Fetching restaurants...")
    cur.execute('SELECT "Id" FROM "Restaurants"')
    res_ids = [r[0] for r in cur.fetchall()]
    
    print(f"Found {len(res_ids)} restaurants. Starting seeding...")
    
    # Get Categories
    cur.execute('SELECT "Id" FROM "Categories"')
    cat_ids = [c[0] for c in cur.fetchall()]
    if not cat_ids: cat_ids = [1]
    
    total_items = 0
    total_reviews = 0
    food_batch = []
    review_batch = []
    
    for rid in res_ids:
        # Resume check: Skip if already has FoodItems
        cur.execute('SELECT COUNT(*) FROM "FoodItems" WHERE "RestaurantId" = %s', (rid,))
        if cur.fetchone()[0] > 0:
            continue

        # Seed 8-12 FoodItems per restaurant
        num_f = random.randint(8, 12)
        ...
        for _ in range(num_f):
            name_base, descs = random.choice(FOOD_TEMPLATES)
            name = f"{name_base} {random.randint(1, 999)}"
            desc = random.choice(descs) + f" (Đặc sản tại nhà hàng ID {rid})"
            price = random.randint(30000, 250000)
            img = random.choice(IMAGE_POOL)
            rating = round(random.uniform(4.0, 5.0), 1)
            cat_id = random.choice(cat_ids)
            
            food_batch.append((name, desc, price, img, True, cat_id, rid, rating))
            total_items += 1
            
        # Seed 15-25 Reviews per restaurant
        num_r = random.randint(15, 25)
        avg_rating = 0
        for _ in range(num_r):
            score = random.choice([4.0, 4.5, 5.0, 5.0, 5.0])
            comment = random.choice(REVIEW_TEMPLATES) + f" Tuyệt vời cho nhà hàng này!"
            uid = random.randint(1, 100)
            review_batch.append((rid, uid, score, comment))
            total_reviews += 1
            avg_rating += score
            
        # Update Restaurant summary
        final_rating = round(avg_rating / num_r, 1)
        cur.execute('''
            UPDATE "Restaurants" SET "Rating" = %s, "ReviewCount" = %s WHERE "Id" = %s
        ''', (final_rating, num_r, rid))
        
        if len(food_batch) >= 200: # Approx 20 restaurants
            cur.executemany('''
                INSERT INTO "FoodItems" ("Name", "Description", "Price", "ImageUrl", "IsAvailable", "CategoryId", "RestaurantId", "Rating", "CreatedDate", "UpdatedDate")
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
            ''', food_batch)
            cur.executemany('''
                INSERT INTO "Reviews" ("RestaurantId", "UserId", "Rating", "Comment", "CreatedDate")
                VALUES (%s, %s, %s, %s, NOW())
            ''', review_batch)
            food_batch = []
            review_batch = []
            conn.commit()
            print(f"Batch committed: {total_items} items total...")

    if food_batch:
        cur.executemany('''
            INSERT INTO "FoodItems" ("Name", "Description", "Price", "ImageUrl", "IsAvailable", "CategoryId", "RestaurantId", "Rating", "CreatedDate", "UpdatedDate")
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
        ''', food_batch)
        cur.executemany('''
            INSERT INTO "Reviews" ("RestaurantId", "UserId", "Rating", "Comment", "CreatedDate")
            VALUES (%s, %s, %s, %s, NOW())
        ''', review_batch)
        conn.commit()
    print(f"DONE! Seeded {total_items} FoodItems and {total_reviews} Reviews across {len(res_ids)} restaurants.")
    cur.close()
    conn.close()

if __name__ == "__main__":
    seed_data()
