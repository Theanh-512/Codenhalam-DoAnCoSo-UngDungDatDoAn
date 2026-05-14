import psycopg2
import random
import datetime

conn_str = "host=aws-1-ap-southeast-2.pooler.supabase.com port=5432 dbname=postgres user=postgres.wbusmwbzqlkyhxtoghsl password=Codenhalam123456 sslmode=require"

def seed_users_and_habits():
    conn = psycopg2.connect(conn_str)
    conn.autocommit = True
    cur = conn.cursor()
    cur.execute('SET statement_timeout = 0')

    print("Cleaning up old simulated data...")
    cur.execute('DELETE FROM "TrackingLogs" WHERE "DeviceInfo" = \'Simulated_Habit\'')
    cur.execute('DELETE FROM "Users" WHERE "Email" LIKE \'%@example.com\'')

    print("Creating User and Shipper accounts...")
    user_profiles = [
        {"name": "Nguyen Van An", "pref": "Breakfast Lover"},
        {"name": "Tran Thi Binh", "pref": "Office Worker"},
        {"name": "Le Hoang Cuong", "pref": "Night Owl"},
        {"name": "Pham Minh Duc", "pref": "Fast Food Fan"},
        {"name": "Hoang Thanh Ha", "pref": "Healthy Eater"}
    ]
    
    all_users = []
    for i in range(20):
        p = random.choice(user_profiles)
        name = f"{p['name']} {i}"
        email = f"user{i}@example.com"
        # Dummy data for NOT NULL constraints
        phone = f"090{random.randint(1000000, 9999999)}"
        address = f"Street {i}, Ward {random.randint(1, 15)}, District {random.randint(1, 10)}"
        cur.execute('INSERT INTO "Users" ("FullName", "Email", "PasswordHash", "Role", "PhoneNumber", "Address", "CreatedDate", "UpdatedDate") VALUES (%s, %s, %s, %s, %s, %s, NOW(), NOW()) RETURNING "Id"',
                    (name, email, "123456", "User", phone, address))
        uid = cur.fetchone()[0]
        all_users.append({"id": uid, "pref": p['pref']})

    for i in range(10):
        name = f"Shipper {i}"
        email = f"shipper{i}@example.com"
        phone = f"091{random.randint(1000000, 9999999)}"
        cur.execute('INSERT INTO "Users" ("FullName", "Email", "PasswordHash", "Role", "PhoneNumber", "Address", "CreatedDate", "UpdatedDate") VALUES (%s, %s, %s, %s, %s, %s, NOW(), NOW())',
                    (name, email, "123456", "Shipper", phone, "Shipper Hub"))

    print("Generating Habits (TrackingLogs)...")
    
    def get_items_by_keyword(keyword):
        cur.execute('SELECT f."Id", r."Id", r."Latitude", r."Longitude" FROM "FoodItems" f JOIN "Restaurants" r ON f."RestaurantId" = r."Id" WHERE f."Name" ILIKE %s LIMIT 50', (f'%{keyword}%',))
        return cur.fetchall()

    pho_items = get_items_by_keyword("Phở")
    rice_items = get_items_by_keyword("Cơm")
    fast_items = get_items_by_keyword("Pizza") + get_items_by_keyword("Gà Rán")
    drink_items = get_items_by_keyword("Trà")
    
    # Fallback if keywords fail
    if not pho_items:
        cur.execute('SELECT f."Id", r."Id", r."Latitude", r."Longitude" FROM "FoodItems" f JOIN "Restaurants" r ON f."RestaurantId" = r."Id" LIMIT 100')
        pho_items = cur.fetchall()
        rice_items = pho_items
        fast_items = pho_items
        drink_items = pho_items

    base_date = datetime.datetime.now() - datetime.timedelta(days=15)
    logs_to_insert = []
    
    for user in all_users:
        uid = user['id']
        pref = user['pref']
        
        for d in range(15):
            curr_date = base_date + datetime.timedelta(days=d)
            if pref == "Breakfast Lover":
                hour = random.randint(6, 8)
                target = pho_items
            elif pref == "Night Owl":
                hour = random.choice([22, 23, 0, 1])
                target = fast_items + drink_items
            elif pref == "Office Worker":
                hour = random.randint(11, 12)
                target = rice_items
            else:
                hour = random.randint(8, 20)
                target = pho_items + rice_items
                
            if not target: continue
            
            for _ in range(random.randint(2, 5)):
                fid, rid, lat, lng = random.choice(target)
                ts = curr_date.replace(hour=hour, minute=random.randint(0, 59))
                session_id = f"SESS_{uid}_{curr_date.strftime('%Y%m%d')}"
                logs_to_insert.append((uid, rid, fid, session_id, "View", lat, lng, ts, "Simulated_Habit"))

    print(f"Inserting {len(logs_to_insert)} TrackingLogs...")
    cur.executemany('''
        INSERT INTO "TrackingLogs" ("UserId", "RestaurantId", "FoodItemId", "SessionId", "ActionType", "Latitude", "Longitude", "Timestamp", "DeviceInfo", "CreatedDate", "UpdatedDate")
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
    ''', logs_to_insert)

    print("DONE!")
    cur.close()
    conn.close()

if __name__ == "__main__":
    seed_users_and_habits()
