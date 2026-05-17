import psycopg2
import random

CONN_STR = "host=aws-1-ap-southeast-2.pooler.supabase.com port=5432 dbname=postgres user=postgres.wbusmwbzqlkyhxtoghsl password=Codenhalam123456 sslmode=require"

def update_ratings():
    try:
        conn = psycopg2.connect(CONN_STR)
        cur = conn.cursor()
        
        # 1. Update Restaurants
        cur.execute('SELECT "Id" FROM "Restaurants"')
        restaurant_ids = [r[0] for r in cur.fetchall()]
        print(f"Updating {len(restaurant_ids)} restaurants...")
        
        for rid in restaurant_ids:
            rating = round(random.uniform(3.5, 4.9), 1)
            review_count = random.randint(15, 380)
            cur.execute('UPDATE "Restaurants" SET "Rating" = %s, "ReviewCount" = %s WHERE "Id" = %s', (rating, review_count, rid))
            
        # 2. Update FoodItems
        cur.execute('SELECT "Id" FROM "FoodItems"')
        food_ids = [f[0] for f in cur.fetchall()]
        print(f"Updating {len(food_ids)} food items...")
        
        for fid in food_ids:
            rating = round(random.uniform(3.8, 4.9), 1)
            cur.execute('UPDATE "FoodItems" SET "Rating" = %s WHERE "Id" = %s', (rating, fid))
            
        conn.commit()
        print("✅ SUCCESS: All restaurant and food item ratings have been randomized between 3.5 and 4.9 stars!")
    except Exception as e:
        print(f"❌ ERROR: {e}")
    finally:
        if 'conn' in locals():
            cur.close()
            conn.close()

if __name__ == "__main__":
    update_ratings()
