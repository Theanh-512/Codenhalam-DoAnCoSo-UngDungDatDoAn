import psycopg2

conn_str = "host=aws-1-ap-southeast-2.pooler.supabase.com port=5432 dbname=postgres user=postgres.wbusmwbzqlkyhxtoghsl password=Codenhalam123456 sslmode=require"

def check_data():
    try:
        conn = psycopg2.connect(conn_str)
        cur = conn.cursor()
        
        cur.execute('SELECT COUNT(*) FROM "Restaurants"')
        res_count = cur.fetchone()[0]
        
        cur.execute('SELECT COUNT(*) FROM "FoodItems"')
        food_count = cur.fetchone()[0]
        
        cur.execute('SELECT COUNT(*) FROM "FoodItems" WHERE "RestaurantId" NOT IN (SELECT "Id" FROM "Restaurants")')
        orphaned_food = cur.fetchone()[0]
        
        print(f"Total Restaurants: {res_count}")
        print(f"Total FoodItems: {food_count}")
        print(f"Orphaned FoodItems (no matching restaurant): {orphaned_food}")
        
        if res_count > 0:
            cur.execute('SELECT "Id", "Name" FROM "Restaurants" LIMIT 5')
            print("\nSample Restaurants:")
            for r in cur.fetchall():
                cur.execute('SELECT COUNT(*) FROM "FoodItems" WHERE "RestaurantId" = %s', (r[0],))
                f_count = cur.fetchone()[0]
                print(f"ID: {r[0]}, Name: {r[1]}, Food Items: {f_count}")
        
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    check_data()
