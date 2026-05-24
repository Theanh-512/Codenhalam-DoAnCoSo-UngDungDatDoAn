#!/usr/bin/env python3
"""Sửa ảnh đại diện cho Restaurants:
1. Fix casing folder đã có trên Storage (banh khot/mi/cong/tieu).
2. Restaurant trỏ folder KHÔNG tồn tại → lấy ảnh món đầu tiên của quán.
3. Restaurant không còn món → fallback Pho/1.jpg.
"""
import os
import psycopg2

CONN = os.environ.get(
    "DATABASE_URL",
    "host=aws-1-ap-southeast-2.pooler.supabase.com port=5432 dbname=postgres "
    "user=postgres.wbusmwbzqlkyhxtoghsl password=Codenhalam123456 sslmode=require",
)
BASE = "https://wbusmwbzqlkyhxtoghsl.supabase.co/storage/v1/object/public/food-images"
FALLBACK = f"{BASE}/Pho/1.jpg"

CASE_FIXES = [
    ("/food-images/banh%20khot/", "/food-images/Banh%20khot/"),
    ("/food-images/banh%20mi/", "/food-images/Banh%20mi/"),
    ("/food-images/banh%20cong/", "/food-images/Banh%20cong/"),
    ("/food-images/banh%20tieu/", "/food-images/Banh%20tieu/"),
]

# Folders không có trên Storage — restaurant nào trỏ vào đây phải đổi.
BROKEN_FOLDERS = [
    "Bun%20mam", "Bun%20dau%20mam%20tom", "Bun%20rieu", "Hu%20tieu",
    "Canh%20chua", "Banh%20can", "banh%20bot%20loc", "Ca%20kho%20to",
    "Nem%20chua", "Bun%20thit%20nuong", "Cao%20lau", "banh%20xeo",
    "Banh%20cuon", "Banh%20trang%20nuong", "Chao%20long", "Banh%20duc",
    "banh%20da%20lon",
]


def main():
    conn = psycopg2.connect(CONN)
    cur = conn.cursor()
    try:
        # 1) Fix case
        total_case = 0
        for old, new in CASE_FIXES:
            cur.execute(
                """
                UPDATE "Restaurants"
                SET "ImageUrl" = REPLACE("ImageUrl", %s, %s),
                    "UpdatedDate" = NOW()
                WHERE "ImageUrl" ILIKE %s
                """,
                (old, new, f"%{old}%"),
            )
            total_case += cur.rowcount
            if cur.rowcount:
                print(f"  case: {cur.rowcount:3d} {old} → {new}")

        # 2) Restaurant ImageUrl rỗng hoặc trỏ folder hỏng → lấy ảnh món đầu của quán.
        broken_pat = " OR ".join(
            ['"ImageUrl" ILIKE %s' for _ in BROKEN_FOLDERS]
        )
        broken_args = [f"%/{f}/%" for f in BROKEN_FOLDERS]
        sql = f"""
            UPDATE "Restaurants" r
            SET "ImageUrl" = COALESCE((
                SELECT f."ImageUrl"
                FROM "FoodItems" f
                WHERE f."RestaurantId" = r."Id"
                  AND f."IsAvailable" = true
                  AND f."ImageUrl" IS NOT NULL
                  AND f."ImageUrl" <> ''
                ORDER BY f."Id"
                LIMIT 1
            ), %s),
            "UpdatedDate" = NOW()
            WHERE r."ImageUrl" IS NULL
               OR r."ImageUrl" = ''
               OR ({broken_pat})
        """
        cur.execute(sql, [FALLBACK] + broken_args)
        print(f"  broken/empty → first food image | fallback: {cur.rowcount} restaurants updated")

        conn.commit()
        print(f"\nTotal: case={total_case}, fixed broken={cur.rowcount}")
    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    main()
