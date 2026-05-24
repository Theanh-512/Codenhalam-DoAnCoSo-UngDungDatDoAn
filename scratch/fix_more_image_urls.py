#!/usr/bin/env python3
"""Gắn ImageUrl cho món Mi quang / Goi cuon từ Storage (đa dạng ảnh theo Id)."""
import os
import urllib.parse
import urllib.request
import psycopg2

CONN = os.environ.get(
    "DATABASE_URL",
    "host=aws-1-ap-southeast-2.pooler.supabase.com port=5432 dbname=postgres "
    "user=postgres.wbusmwbzqlkyhxtoghsl password=Codenhalam123456 sslmode=require",
)

BASE = "https://wbusmwbzqlkyhxtoghsl.supabase.co/storage/v1/object/public/food-images"


def list_images(folder, prefix="", max_n=200):
    """HEAD probe để liệt kê {prefix}{n}.jpg có trên Storage (có thể nhảy số)."""
    nums = []
    for i in range(1, max_n + 1):
        url = f"{BASE}/{urllib.parse.quote(folder)}/{prefix}{i}.jpg"
        try:
            r = urllib.request.urlopen(urllib.request.Request(url, method="HEAD"), timeout=4)
            if r.status == 200:
                nums.append(i)
        except Exception:
            pass
    return nums


def main():
    # (folder Storage, keyword tên món để match, prefix file [optional])
    targets = [
        ("Mi quang", "mi quang", ""),
        ("Goi cuon", "goi cuon", ""),
        ("Xoi xeo", "xoi xeo", ""),
        ("Banh chung", "banh chung", ""),
        ("Banh tet", "banh tet", ""),
        ("Banh mi", "banh mi", ""),
        ("Banh cong", "banh cong", "banh_cong"),
        ("Banh tieu", "banh tieu", "banh_tieu"),
        ("Banh khot", "banh khot", ""),
    ]

    conn = psycopg2.connect(CONN)
    cur = conn.cursor()
    try:
        for folder, kw, prefix in targets:
            nums = list_images(folder, prefix, 120)
            if not nums:
                print(f"[skip] Không có ảnh trong folder '{folder}'")
                continue

            label = f"{prefix}{{N}}.jpg" if prefix else "{N}.jpg"
            print(f"[ok] folder '{folder}' có {len(nums)} ảnh ({label})")

            cur.execute(
                'SELECT "Id" FROM "FoodItems" WHERE unaccent("Name") ILIKE unaccent(%s) AND "IsAvailable" = true',
                (f"%{kw}%",),
            )
            ids = [row[0] for row in cur.fetchall()]
            print(f"     {len(ids)} món sẽ được gắn ảnh")

            for fid in ids:
                pick = nums[fid % len(nums)]
                url = f"{BASE}/{urllib.parse.quote(folder)}/{prefix}{pick}.jpg"
                cur.execute(
                    'UPDATE "FoodItems" SET "ImageUrl" = %s, "UpdatedDate" = NOW() WHERE "Id" = %s',
                    (url, fid),
                )

            conn.commit()
            print(f"     Đã cập nhật {len(ids)} món.")
    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    main()
