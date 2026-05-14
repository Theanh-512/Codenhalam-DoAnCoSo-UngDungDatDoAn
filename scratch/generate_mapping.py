import psycopg2
import json
import os

conn_str = "host=aws-1-ap-southeast-2.pooler.supabase.com port=5432 dbname=postgres user=postgres.wbusmwbzqlkyhxtoghsl password=Codenhalam123456 sslmode=require"

def generate_mapping():
    conn = psycopg2.connect(conn_str)
    cur = conn.cursor()
    
    # Get all food items and their restaurant info
    print("Fetching FoodItems and Restaurants...")
    cur.execute('''
        SELECT f."Id", f."RestaurantId", r."Latitude", r."Longitude"
        FROM "FoodItems" f
        JOIN "Restaurants" r ON f."RestaurantId" = r."Id"
        ORDER BY f."Id"
    ''')
    rows = cur.fetchall()
    
    mapping = {
        "id_to_idx": {},
        "idx_to_id": {},
        "idx_to_rest_id": {},
        "idx_to_coord": {}
    }
    
    for idx, (fid, rid, lat, lng) in enumerate(rows):
        mapping["id_to_idx"][fid] = idx
        mapping["idx_to_id"][idx] = fid
        mapping["idx_to_rest_id"][idx] = rid
        mapping["idx_to_coord"][idx] = (lat, lng)
        
    os.makedirs("AIEngine/data", exist_ok=True)
    with open("AIEngine/data/item_mapping.json", "w") as f:
        json.dump(mapping, f)
        
    print(f"Generated mapping for {len(rows)} items.")
    cur.close()
    conn.close()

if __name__ == "__main__":
    generate_mapping()
