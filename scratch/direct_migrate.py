import json
import psycopg2
from psycopg2 import extras
import datetime

# Database configuration
CONN_STR = "Host=aws-1-ap-southeast-2.pooler.supabase.com;Port=5432;Database=postgres;Username=postgres.wbusmwbzqlkyhxtoghsl;Password=Codenhalam123456;sslmode=require"

def migrate_data(geojson_path):
    print(f"Reading data from {geojson_path}...")
    with open(geojson_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    features = data.get('features', [])
    print(f"Found {len(features)} features.")
    
    restaurants_to_insert = []
    
    # Image pool for variety
    image_pool = [
        "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=500",
        "https://images.unsplash.com/photo-1552566626-52f8b828add9?w=500",
        "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=500",
        "https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?w=500",
        "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=500",
        "https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=500",
        "https://images.unsplash.com/photo-1559339352-11d035aa65de?w=500",
        "https://images.unsplash.com/photo-1502301103665-0b95cc738def?w=500",
        "https://images.unsplash.com/photo-1482049016688-2d3e1b311543?w=500",
        "https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=500"
    ]
    
    for i, feat in enumerate(features):
        props = feat.get('properties', {})
        geom = feat.get('geometry', {})
        
        name = props.get('name', '').replace('"', '\\"')
        if not name:
            continue # Skip unnamed restaurants
            
        street = props.get('addr:street', '').replace('"', '\\"')
        house_num = props.get('addr:housenumber', '').replace('"', '\\"')
        address = f"{house_num} {street}".strip()
        if not address:
            address = "Hồ Chí Minh"
        else:
            address += ", Hồ Chí Minh"
            
        coords = geom.get('coordinates', [0, 0])
        lng, lat = coords
        
        cuisine = props.get('cuisine', 'Địa điểm ăn uống').replace('"', '\\"')
        description = f"Phục vụ các món {cuisine}"
        
        # Pick image from pool
        img_url = image_pool[i % len(image_pool)]
        
        restaurants_to_insert.append((
            name,
            description,
            address,
            img_url,
            lat,
            lng,
            "08:00-22:00",
            True,
            datetime.datetime.utcnow()
        ))

    # No limit - process all features

    if not restaurants_to_insert:
        print("No valid restaurants found to insert.")
        return

    conn = None
    cur = None
    try:
        # Construct proper psycopg2 DSN
        dsn = "host=aws-1-ap-southeast-2.pooler.supabase.com port=5432 dbname=postgres user=postgres.wbusmwbzqlkyhxtoghsl password=Codenhalam123456 sslmode=require"
        conn = psycopg2.connect(dsn)
        cur = conn.cursor()
        
        # Clear existing restaurants for a clean start
        cur.execute('TRUNCATE TABLE "Restaurants" RESTART IDENTITY CASCADE;')
        
        insert_query = """
            INSERT INTO "Restaurants" 
            ("Name", "Description", "Address", "ImageUrl", "Latitude", "Longitude", "OpeningHours", "IsActive", "CreatedDate")
            VALUES %s
        """
        
        extras.execute_values(cur, insert_query, restaurants_to_insert)
        
        conn.commit()
        print(f"Successfully inserted {len(restaurants_to_insert)} restaurants into the database.")
        
        # Seed some default FoodItems for the first 100 restaurants
        print("Seeding FoodItems...")
        
        # Ensure categories 1-4 exist or at least some categories exist
        cur.execute("SELECT count(*) FROM \"Categories\"")
        if cur.fetchone()[0] == 0:
            cur.execute("""
                INSERT INTO "Categories" ("Name", "ImageUrl", "CreatedDate") VALUES 
                ('Phở', '', now()), ('Pizza', '', now()), ('Bún', '', now()), ('Đồ uống', '', now())
            """)
            conn.commit()

        cur.execute("SELECT \"Id\" FROM \"Categories\" LIMIT 4")
        cat_ids = [c[0] for c in cur.fetchall()]
        
        cur.execute("SELECT \"Id\" FROM \"Restaurants\" LIMIT 200")
        res_ids = [r[0] for r in cur.fetchall()]
        
        food_items = []
        menu_templates = [
            ("Phở Đặc Biệt", "Nước dùng đậm đà", 65000, cat_ids[0] if len(cat_ids)>0 else 1, "https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=200"),
            ("Pizza Hải Sản", "Hải sản tươi ngon", 150000, cat_ids[1] if len(cat_ids)>1 else 1, "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=200"),
            ("Cơm Tấm Sườn Bì", "Đặc sản Sài Gòn", 45000, cat_ids[2] if len(cat_ids)>2 else 1, "https://images.unsplash.com/photo-1541529086526-db283c563270?w=200"),
            ("Trà Sữa Thái", "Giải nhiệt mùa hè", 30000, cat_ids[3] if len(cat_ids)>3 else 1, "https://images.unsplash.com/photo-1571328003758-4a3921661709?w=200")
        ]
        
        for r_id in res_ids:
            for name, desc, price, cat_id, img in menu_templates:
                food_items.append((
                    name, desc, price, cat_id, r_id, img, True, datetime.datetime.utcnow()
                ))
        
        cur.execute("TRUNCATE TABLE \"FoodItems\" RESTART IDENTITY CASCADE;")
        insert_food_query = """
            INSERT INTO "FoodItems" 
            ("Name", "Description", "Price", "CategoryId", "RestaurantId", "ImageUrl", "IsAvailable", "CreatedDate")
            VALUES %s
        """
        extras.execute_values(cur, insert_food_query, food_items)
        conn.commit()
        print(f"Successfully seeded {len(food_items)} food items.")
        
    except Exception as e:
        print(f"An error occurred: {e}")
        if conn:
            conn.rollback()
    finally:
        if cur: cur.close()
        if conn: conn.close()

if __name__ == "__main__":
    migrate_data('export.geojson')
