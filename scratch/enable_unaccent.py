import psycopg2

CONN_STR = "host=aws-1-ap-southeast-2.pooler.supabase.com port=5432 dbname=postgres user=postgres.wbusmwbzqlkyhxtoghsl password=Codenhalam123456 sslmode=require"

print("🔌 Đang kết nối tới Supabase PostgreSQL để kích hoạt extension 'unaccent'...")
try:
    conn = psycopg2.connect(CONN_STR)
    conn.autocommit = True
    cur = conn.cursor()
    
    # Kích hoạt extension unaccent
    print("⚡ Đang kích hoạt extension 'unaccent'...")
    cur.execute('CREATE EXTENSION IF NOT EXISTS "unaccent";')
    
    # Kiểm tra thử
    cur.execute("SELECT unaccent('bún riêu cua đặc biệt');")
    result = cur.fetchone()[0]
    
    print(f"✅ KÍCH HOẠT THÀNH CÔNG!")
    print(f"📝 Kiểm tra thử nghiệm bỏ dấu: 'bún riêu cua đặc biệt' -> '{result}'")
    
    cur.close()
    conn.close()
except Exception as e:
    print(f"❌ LỖI kết nối hoặc kích hoạt extension: {e}")
