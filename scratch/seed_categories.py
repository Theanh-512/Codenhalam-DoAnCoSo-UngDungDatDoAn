import psycopg2

conn_str = "host=aws-1-ap-southeast-2.pooler.supabase.com port=5432 dbname=postgres user=postgres.wbusmwbzqlkyhxtoghsl password=Codenhalam123456 sslmode=require"
conn = psycopg2.connect(conn_str)
conn.autocommit = True
cur = conn.cursor()
print("Checking Categories schema...")
cur.execute('SET statement_timeout = 0')

# Ensure ImageUrl column exists
cur.execute("SELECT column_name FROM information_schema.columns WHERE table_name='Categories' AND column_name='ImageUrl'")
if not cur.fetchone():
    print("Adding ImageUrl column...")
    try:
        cur.execute('ALTER TABLE "Categories" ADD COLUMN "ImageUrl" TEXT')
        print("Column added.")
    except Exception as e:
        print(f"Error adding column: {e}")
else:
    print("ImageUrl column exists.")

CATEGORIES = [
    ("Đồ ăn nhanh", "Các món ăn nhanh tiện lợi", "https://images.unsplash.com/photo-1561758033-d89a9ad46330?q=80&w=400"),
    ("Món Việt", "Hương vị truyền thống Việt Nam", "https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?q=80&w=400"),
    ("Đồ uống", "Trà sữa, Cafe và nước giải khát", "https://images.unsplash.com/photo-1544145945-f904253d0c7b?q=80&w=400"),
    ("Bún & Phở", "Các loại bún, phở, mì nước", "https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?q=80&w=400"),
    ("Cơm văn phòng", "Bữa cơm đầy đủ dinh dưỡng", "https://images.unsplash.com/photo-1512058560366-cd24270083cd?q=80&w=400"),
    ("Tráng miệng", "Bánh ngọt, chè và hoa quả", "https://images.unsplash.com/photo-1551024601-bec78aea704b?q=80&w=400"),
    ("Món Nhật", "Sashimi, Sushi và Ramen", "https://images.unsplash.com/photo-1553621042-f6e147245754?q=80&w=400"),
    ("Pizza & Pasta", "Món Âu chuẩn vị", "https://images.unsplash.com/photo-1513104890138-7c749659a591?q=80&w=400")
]

print("Seeding Categories...")
for name, desc, img in CATEGORIES:
    cur.execute('SELECT "Id" FROM "Categories" WHERE "Name" = %s', (name,))
    row = cur.fetchone()
    if row:
        cur.execute('UPDATE "Categories" SET "Description" = %s, "ImageUrl" = %s WHERE "Id" = %s', (desc, img, row[0]))
    else:
        cur.execute('INSERT INTO "Categories" ("Name", "Description", "ImageUrl", "CreatedDate", "UpdatedDate") VALUES (%s, %s, %s, NOW(), NOW())', (name, desc, img))

print("Categories seeded successfully.")
cur.close()
conn.close()
