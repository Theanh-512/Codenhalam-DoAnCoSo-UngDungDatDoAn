#!/usr/bin/env python3
"""Xoi xeo không có trên Storage — chuyển URL sang folder Com tam."""
import os
import psycopg2

CONN = os.environ.get(
    "DATABASE_URL",
    "host=aws-1-ap-southeast-2.pooler.supabase.com port=5432 dbname=postgres "
    "user=postgres.wbusmwbzqlkyhxtoghsl password=Codenhalam123456 sslmode=require",
)

REPLACEMENTS = [
    ("/food-images/Xoi%20xeo/", "/food-images/Com%20tam/"),
    ("/food-images/xoi%20xeo/", "/food-images/Com%20tam/"),
    ("/food-images/Xoi%20Xeo/", "/food-images/Com%20tam/"),
    ("/food-images/com%20tam/", "/food-images/Com%20tam/"),
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
