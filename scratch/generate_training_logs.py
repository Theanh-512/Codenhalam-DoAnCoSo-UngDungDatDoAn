import psycopg2
import random
import datetime
import time

conn_str = "host=aws-1-ap-southeast-2.pooler.supabase.com port=5432 dbname=postgres user=postgres.wbusmwbzqlkyhxtoghsl password=Codenhalam123456 sslmode=require"

def generate_logs():
    conn = psycopg2.connect(conn_str)
    cur = conn.cursor()
    
    print("Fetching restaurants for logs...")
    cur.execute('SELECT "Id", "Latitude", "Longitude" FROM "Restaurants"')
    restaurants = cur.fetchall()
    
    # 1. Fetch Users
    cur.execute('SELECT "Id" FROM "Users"')
    user_ids = [u[0] for u in cur.fetchall()]
    if not user_ids: user_ids = list(range(1, 51)) # Fallback
    
    print(f"Generating 10,000+ logs for {len(user_ids)} users...")
    
    logs_data = []
    base_time = datetime.datetime.now() - datetime.timedelta(days=30)
    
    for uid in user_ids:
        num_inters = random.randint(50, 100)
        for i in range(num_inters):
            ts = base_time + datetime.timedelta(hours=i * 6 + random.randint(0, 120))
            res = random.choice(restaurants)
            rid, lat, lng = res
            
            # Fetch a random food item from this restaurant
            cur.execute('SELECT "Id" FROM "FoodItems" WHERE "RestaurantId" = %s', (rid,))
            f_items = cur.fetchall()
            fid = f_items[0][0] if f_items else None

            action = random.choice(["View", "AddToCart", "Order"])
            session_id = f"SESS_{uid}_{ts.strftime('%Y%m%d')}"
            
            logs_data.append((uid, rid, fid, session_id, action, lat, lng, ts, "Device_Simulated"))
            
            if len(logs_data) >= 1000:
                cur.executemany('''
                    INSERT INTO "TrackingLogs" ("UserId", "RestaurantId", "FoodItemId", "SessionId", "ActionType", "Latitude", "Longitude", "Timestamp", "DeviceInfo", "CreatedDate", "UpdatedDate")
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
                ''', logs_data)
                logs_data = []
                conn.commit()

    if logs_data:
        cur.executemany('''
            INSERT INTO "TrackingLogs" ("UserId", "RestaurantId", "FoodItemId", "SessionId", "ActionType", "Latitude", "Longitude", "Timestamp", "DeviceInfo", "CreatedDate", "UpdatedDate")
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
        ''', logs_data)
        conn.commit()

    print("DONE! Synthetic behavior logs generated.")
    cur.close()
    conn.close()

if __name__ == "__main__":
    generate_logs()
