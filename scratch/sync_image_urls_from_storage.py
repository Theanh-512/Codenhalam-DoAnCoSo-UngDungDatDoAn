#!/usr/bin/env python3
"""
Đồng bộ ImageUrl cho FoodItems và Restaurants từ bucket Supabase food-images.

Cách chạy:
  pip install psycopg2-binary requests
  python scratch/sync_image_urls_from_storage.py

Tùy chọn (nhanh hơn — liệt kê file trong bucket):
  export SUPABASE_SERVICE_ROLE_KEY="your-service-role-key"
"""

from __future__ import annotations

import json
import os
import re
import unicodedata
import urllib.parse
import urllib.request
from collections import defaultdict

import psycopg2
from psycopg2.extras import execute_batch

CONN_STR = os.environ.get(
    "DATABASE_URL",
    "host=aws-1-ap-southeast-2.pooler.supabase.com port=5432 dbname=postgres "
    "user=postgres.wbusmwbzqlkyhxtoghsl password=Codenhalam123456 sslmode=require",
)
PROJECT_URL = os.environ.get("SUPABASE_URL", "https://wbusmwbzqlkyhxtoghsl.supabase.co").rstrip("/")
PUBLIC_BASE = os.environ.get(
    "SUPABASE_PUBLIC_BASE",
    f"{PROJECT_URL}/storage/v1/object/public/food-images",
).rstrip("/")
BUCKET = os.environ.get("SUPABASE_BUCKET", "food-images")
SERVICE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "")

IMAGE_EXT = (".jpg", ".jpeg", ".png", ".webp")


def normalize(s: str) -> str:
    s = s.strip().lower()
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    return re.sub(r"\s+", " ", s)


def encode_path(path: str) -> str:
    return "/".join(urllib.parse.quote(p) for p in path.split("/"))


def list_from_storage_api() -> dict[str, list[str]]:
    if not SERVICE_KEY:
        return {}

    folder_map: dict[str, list[str]] = defaultdict(list)
    queue = [""]

    while queue:
        prefix = queue.pop(0)
        body = json.dumps({"prefix": prefix, "limit": 1000, "offset": 0}).encode()
        req = urllib.request.Request(
            f"{PROJECT_URL}/storage/v1/object/list/{BUCKET}",
            data=body,
            headers={
                "Authorization": f"Bearer {SERVICE_KEY}",
                "Content-Type": "application/json",
            },
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=60) as res:
                entries = json.loads(res.read().decode())
        except Exception as e:
            print(f"Storage API lỗi (prefix={prefix!r}): {e}")
            break

        if not isinstance(entries, list):
            break

        for entry in entries:
            name = (entry.get("name") or "").strip()
            if not name:
                continue
            full = f"{prefix}{name}" if not prefix else f"{prefix.rstrip('/')}/{name}"

            if name.lower().endswith(IMAGE_EXT):
                parts = full.split("/")
                folder_key = parts[-2] if len(parts) >= 2 else parts[0].rsplit(".", 1)[0]
                url = f"{PUBLIC_BASE}/{encode_path(full)}"
                folder_map[folder_key].append(url)
            elif "." not in name:
                queue.append(full + "/")

    return dict(folder_map)


def probe_folder(folder: str) -> list[str]:
    urls = []
    for i in range(1, 21):
        path = encode_path(f"{folder}/{i}.jpg")
        url = f"{PUBLIC_BASE}/{path}"
        req = urllib.request.Request(url, method="HEAD")
        try:
            with urllib.request.urlopen(req, timeout=8) as res:
                if 200 <= res.status < 300:
                    urls.append(url)
        except Exception:
            pass
    return urls


def discover_by_probing(conn) -> dict[str, list[str]]:
    folder_map: dict[str, list[str]] = {}
    names: set[str] = set()

    with conn.cursor() as cur:
        cur.execute('SELECT "Name" FROM "Categories"')
        names.update(row[0].strip() for row in cur.fetchall() if row[0])

        cur.execute('SELECT "Name" FROM "FoodItems"')
        for (n,) in cur.fetchall():
            if not n:
                continue
            n = n.strip()
            names.add(n)
            first = n.split()[0] if n.split() else ""
            if first:
                names.add(first)

    print(f"Đang thử {len(names)} tên folder (HEAD 1.jpg…20.jpg)…")
    for i, folder in enumerate(sorted(names), 1):
        urls = probe_folder(folder)
        if urls:
            folder_map[folder] = urls
        if i % 50 == 0:
            print(f"  … {i}/{len(names)}")

    return folder_map


def resolve_folder_key(primary: str | None, secondary: str | None, keys: list[str]) -> str | None:
    for candidate in (primary, secondary):
        if not candidate:
            continue
        nc = normalize(candidate)
        for k in keys:
            nk = normalize(k)
            if nk == nc or nc in nk or nk in nc:
                return k
        words = candidate.strip().split()
        if words:
            w = normalize(words[0])
            for k in keys:
                if normalize(k).startswith(w) or w.startswith(normalize(k)):
                    return k
    return None


def pick_url(urls: list[str], seed: int) -> str:
    return urls[abs(seed) % len(urls)]


def main():
    print("--- Đồng bộ URL ảnh từ Supabase food-images ---")

    folder_map = list_from_storage_api()
    if folder_map:
        print(f"Liệt kê Storage API: {len(folder_map)} folder có ảnh")
    else:
        print("Không có SERVICE_ROLE_KEY hoặc API lỗi — dùng chế độ quét HEAD")

    conn = psycopg2.connect(CONN_STR)
    try:
        if not folder_map:
            folder_map = discover_by_probing(conn)

        if not folder_map:
            print("Không tìm thấy ảnh. Kiểm tra bucket public và tên folder.")
            return

        keys = list(folder_map.keys())
        food_updates = []
        rest_updates = []

        with conn.cursor() as cur:
            cur.execute(
                '''
                SELECT f."Id", f."Name", c."Name", f."RestaurantId", f."ImageUrl"
                FROM "FoodItems" f
                LEFT JOIN "Categories" c ON c."Id" = f."CategoryId"
                '''
            )
            rows = cur.fetchall()
            for fid, fname, cname, _, old_url in rows:
                fk = resolve_folder_key(fname, cname, keys)
                if not fk:
                    continue
                url = pick_url(folder_map[fk], fid)
                if url and url != (old_url or ""):
                    food_updates.append((url, fid))

            cur.execute('SELECT "Id", "Name", "Type1", "Type2", "ImageUrl" FROM "Restaurants"')
            restaurants = cur.fetchall()

            cur.execute(
                '''
                SELECT DISTINCT ON ("RestaurantId") "RestaurantId", "ImageUrl"
                FROM "FoodItems"
                WHERE "ImageUrl" IS NOT NULL AND "ImageUrl" <> ''
                ORDER BY "RestaurantId", "Id"
                '''
            )
            first_food_img = {r[0]: r[1] for r in cur.fetchall()}

        for rid, rname, t1, t2, old_url in restaurants:
            url = first_food_img.get(rid)
            if not url:
                fk = resolve_folder_key(rname, t1, keys) or resolve_folder_key(rname, t2, keys)
                if fk:
                    url = pick_url(folder_map[fk], rid)
            if url and url != (old_url or ""):
                rest_updates.append((url, rid))

        with conn.cursor() as cur:
            if food_updates:
                execute_batch(
                    cur,
                    'UPDATE "FoodItems" SET "ImageUrl" = %s, "UpdatedDate" = NOW() WHERE "Id" = %s',
                    food_updates,
                    page_size=500,
                )
            if rest_updates:
                execute_batch(
                    cur,
                    'UPDATE "Restaurants" SET "ImageUrl" = %s, "UpdatedDate" = NOW() WHERE "Id" = %s',
                    rest_updates,
                    page_size=500,
                )
        conn.commit()

        print(f"✅ Folder ảnh: {len(folder_map)}")
        print(f"✅ Cập nhật món: {len(food_updates)} / {len(rows)}")
        print(f"✅ Cập nhật quán: {len(rest_updates)} / {len(restaurants)}")
    except Exception as e:
        conn.rollback()
        raise
    finally:
        conn.close()


if __name__ == "__main__":
    main()
