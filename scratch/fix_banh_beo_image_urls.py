#!/usr/bin/env python3
"""Sửa nhanh URL ảnh bánh bèo: Banh%20beo → banh%20beo (Supabase phân biệt hoa thường)."""
import os
import psycopg2

CONN = os.environ.get(
    "DATABASE_URL",
    "host=aws-1-ap-southeast-2.pooler.supabase.com port=5432 dbname=postgres "
    "user=postgres.wbusmwbzqlkyhxtoghsl password=Codenhalam123456 sslmode=require",
)

REPLACEMENTS = [
    ("/food-images/Banh%20beo/", "/food-images/banh%20beo/"),
    ("/food-images/Banh%20Beo/", "/food-images/banh%20beo/"),
]


def main():
    conn = psycopg2.connect(CONN)
    cur = conn.cursor()
    try:
        for old, new in REPLACEMENTS:
            for table in ("FoodItems", "Restaurants"):
                cur.execute(
                    f'''
                    UPDATE "{table}"
                    SET "ImageUrl" = REPLACE("ImageUrl", %s, %s),
                        "UpdatedDate" = NOW()
                    WHERE "ImageUrl" ILIKE %s
                    ''',
                    (old, new, f"%{old}%"),
                )
                print(f"{table}: {cur.rowcount} rows ({old} → {new})")
        conn.commit()
        print("Done.")
    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    main()
