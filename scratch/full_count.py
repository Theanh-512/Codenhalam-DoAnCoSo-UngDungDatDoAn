import psycopg2
conn_str = "host=aws-1-ap-southeast-2.pooler.supabase.com port=5432 dbname=postgres user=postgres.wbusmwbzqlkyhxtoghsl password=Codenhalam123456 sslmode=require"
conn = psycopg2.connect(conn_str)
cur = conn.cursor()

def count_table(table):
    cur.execute(f'SELECT COUNT(*) FROM "{table}"')
    return cur.fetchone()[0]

print(f"Restaurants: {count_table('Restaurants')}")
print(f"Categories: {count_table('Categories')}")
print(f"FoodItems: {count_table('FoodItems')}")
print(f"Reviews: {count_table('Reviews')}")
print(f"TrackingLogs: {count_table('TrackingLogs')}")
print(f"Users: {count_table('Users')}")

cur.close()
conn.close()
