import psycopg2

conn_str = "host=aws-1-ap-southeast-2.pooler.supabase.com port=5432 dbname=postgres user=postgres.wbusmwbzqlkyhxtoghsl password=Codenhalam123456 sslmode=require"

def check_categories():
    try:
        conn = psycopg2.connect(conn_str)
        cur = conn.cursor()
        cur.execute('SELECT * FROM "Categories"')
        rows = cur.fetchall()
        print(f"Categories: {rows}")
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    check_categories()
