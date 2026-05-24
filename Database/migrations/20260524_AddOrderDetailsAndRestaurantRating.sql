-- =====================================================================
-- Migration: AddOrderDetailsAndRestaurantRating
-- Áp dụng cho Supabase: chạy toàn bộ file này trong SQL Editor.
-- Idempotent: chạy lại không vỡ (dùng IF NOT EXISTS / ON CONFLICT).
-- =====================================================================

BEGIN;

-- 1) Bảng ghi lịch sử migration của EF Core (tạo nếu chưa có) ---------
CREATE TABLE IF NOT EXISTS "__EFMigrationsHistory" (
    "MigrationId"    varchar(150) NOT NULL,
    "ProductVersion" varchar(32)  NOT NULL,
    CONSTRAINT "PK___EFMigrationsHistory" PRIMARY KEY ("MigrationId")
);

-- Backfill các migration cũ đã được áp tay lên Supabase trước đây.
INSERT INTO "__EFMigrationsHistory" ("MigrationId","ProductVersion") VALUES
    ('20260511163727_InitialCreate',                     '9.0.0'),
    ('20260513020727_UpdateAPI',                         '9.0.0'),
    ('20260515035852_AddUserRole',                       '9.0.0'),
    ('20260515041737_AddRestaurantTypes',                '9.0.0'),
    ('20260523182951_AddOrderDetailsAndRestaurantRating','9.0.0')
ON CONFLICT DO NOTHING;

-- 2) Cột mới cho Restaurants ------------------------------------------
ALTER TABLE "Restaurants"
    ADD COLUMN IF NOT EXISTS "Rating"      double precision NOT NULL DEFAULT 0.0,
    ADD COLUMN IF NOT EXISTS "ReviewCount" integer          NOT NULL DEFAULT 0;

-- 3) Cột mới cho Orders (thông tin nhận / thanh toán / voucher) -------
ALTER TABLE "Orders"
    ADD COLUMN IF NOT EXISTS "DeliveryLatitude"  double precision,
    ADD COLUMN IF NOT EXISTS "DeliveryLongitude" double precision,
    ADD COLUMN IF NOT EXISTS "PaymentMethod"     text NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS "ReceiverName"      text NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS "ReceiverPhone"     text NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS "VoucherCode"       text NOT NULL DEFAULT '';

-- 4) Nới NOT NULL cho ImageUrl/Description (đồng bộ với entity) -------
ALTER TABLE "FoodItems"  ALTER COLUMN "ImageUrl"   DROP NOT NULL;
ALTER TABLE "FoodItems"  ALTER COLUMN "Description" DROP NOT NULL;
ALTER TABLE "Categories" ALTER COLUMN "ImageUrl"   DROP NOT NULL;
ALTER TABLE "Categories" ALTER COLUMN "Description" DROP NOT NULL;

COMMIT;

-- =====================================================================
-- Kiểm tra sau khi chạy:
--   SELECT "MigrationId" FROM "__EFMigrationsHistory" ORDER BY 1;
--   \d "Orders"
--   \d "Restaurants"
-- =====================================================================
