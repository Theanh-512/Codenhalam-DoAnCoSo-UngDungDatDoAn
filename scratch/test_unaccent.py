import psycopg2

CONN_STR = "host=aws-1-ap-southeast-2.pooler.supabase.com port=5432 dbname=postgres user=postgres.wbusmwbzqlkyhxtoghsl password=Codenhalam-DoAnCoSo sslmode=require"

try:
    # Try the main password, or fallback password
    conn = psycopg2.connect("host=aws-1-ap-southeast-2.pooler.supabase.com port=5432 dbname=postgres user=postgres.wbusmwbzqlkyhxtoghsl password=Codenhalam123456 sslmode=require")
    cur = conn.cursor()
    cur.execute("CREATE EXTENSION IF NOT EXISTS unaccent;")
    cur.execute("SELECT unaccent('bún riêu cua');")
    res = cur.fetchone()[0]
    print(f"✅ Unaccent works! 'bún riêu cua' -> '{res}'")
    conn.close()
except Exception as e:
    print(f"❌ Error: {e}")
