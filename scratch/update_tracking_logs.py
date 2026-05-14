import psycopg2

conn_str = "host=aws-1-ap-southeast-2.pooler.supabase.com port=5432 dbname=postgres user=postgres.wbusmwbzqlkyhxtoghsl password=Codenhalam123456 sslmode=require"
conn = psycopg2.connect(conn_str)
conn.autocommit = True
cur = conn.cursor()

print("Adding FoodItemId to TrackingLogs...")
try:
    cur.execute('ALTER TABLE "TrackingLogs" ADD COLUMN IF NOT EXISTS "FoodItemId" INTEGER')
    print("Success.")
except Exception as e:
    print(f"Error: {e}")

cur.close()
conn.close()
