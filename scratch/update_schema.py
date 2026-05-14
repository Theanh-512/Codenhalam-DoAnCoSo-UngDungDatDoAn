import psycopg2

conn_str = "host=aws-1-ap-southeast-2.pooler.supabase.com port=5432 dbname=postgres user=postgres.wbusmwbzqlkyhxtoghsl password=Codenhalam123456 sslmode=require"
conn = psycopg2.connect(conn_str)
conn.autocommit = True
cur = conn.cursor()

print("Updating schema...")

# 1. Add Rating/ReviewCount to Restaurants if not exists
try:
    cur.execute('ALTER TABLE "Restaurants" ADD COLUMN IF NOT EXISTS "Rating" DOUBLE PRECISION DEFAULT 4.5')
    cur.execute('ALTER TABLE "Restaurants" ADD COLUMN IF NOT EXISTS "ReviewCount" INTEGER DEFAULT 100')
except Exception as e:
    print(f"Restaurant update error: {e}")

# 2. Add Rating to FoodItems if not exists
try:
    cur.execute('ALTER TABLE "FoodItems" ADD COLUMN IF NOT EXISTS "Rating" DOUBLE PRECISION DEFAULT 5.0')
except Exception as e:
    print(f"FoodItem update error: {e}")

# 3. Create Reviews table
try:
    cur.execute('''
    CREATE TABLE IF NOT EXISTS "Reviews" (
        "Id" SERIAL PRIMARY KEY,
        "RestaurantId" INTEGER NOT NULL,
        "UserId" INTEGER,
        "Rating" DOUBLE PRECISION NOT NULL,
        "Comment" TEXT,
        "CreatedDate" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    )
    ''')
except Exception as e:
    print(f"Review table creation error: {e}")

print("Schema updated successfully.")
cur.close()
conn.close()
