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
    
    for feat in features:
        props = feat.get('properties', {})
        geom = feat.get('geometry', {})
        
        name = props.get('name')
        if not name:
            continue # Skip unnamed restaurants
            
        street = props.get('addr:street', '')
        house_num = props.get('addr:housenumber', '')
        address = f"{house_num} {street}".strip()
        if not address:
            address = "Hồ Chí Minh"
        else:
            address += ", Hồ Chí Minh"
            
        coords = geom.get('coordinates', [0, 0])
        lng, lat = coords
        
        cuisine = props.get('cuisine', 'Địa điểm ăn uống')
        description = f"Phục vụ các món {cuisine}"
        
        # Mapping to DB columns: 
        # Name, Description, Address, ImageUrl, Latitude, Longitude, OpeningHours, IsActive, CreatedDate
        restaurants_to_insert.append((
            name,
            description,
            address,
            "https://images.unsplash.com/photo-1552566626-52f8b828add9?w=500",
            lat,
            lng,
            "08:00-22:00",
            True,
            datetime.datetime.utcnow()
        ))

    print(f"Prepared {len(restaurants_to_insert)} restaurants for insertion.")

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
        
        insert_query = """
            INSERT INTO "Restaurants" 
            ("Name", "Description", "Address", "ImageUrl", "Latitude", "Longitude", "OpeningHours", "IsActive", "CreatedDate")
            VALUES %s
        """
        
        extras.execute_values(cur, insert_query, restaurants_to_insert)
        
        conn.commit()
        print(f"Successfully inserted {len(restaurants_to_insert)} restaurants into the database.")
        
    except Exception as e:
        print(f"An error occurred: {e}")
        if conn:
            conn.rollback()
    finally:
        if cur: cur.close()
        if conn: conn.close()

if __name__ == "__main__":
    migrate_data('export.geojson')
