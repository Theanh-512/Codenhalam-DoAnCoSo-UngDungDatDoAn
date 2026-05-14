import psycopg2
conn_str = "host=aws-1-ap-southeast-2.pooler.supabase.com port=5432 dbname=postgres user=postgres.wbusmwbzqlkyhxtoghsl password=Codenhalam123456 sslmode=require"
conn = psycopg2.connect(conn_str)
cur = conn.cursor()
cur.execute('SELECT "Id", "FullName", "Email", "Role" FROM "Users"')
print(cur.fetchall())
cur.close()
conn.close()
