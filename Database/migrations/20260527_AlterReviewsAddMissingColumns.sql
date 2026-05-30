-- Patch bảng "Reviews" cho trường hợp bảng đã được tạo sẵn (vd: từ pipeline
-- sentiment của AIService) với schema thiếu các cột mà ReviewsController.cs
-- (entity Domain.Entities.Review) đang dùng.
--
-- Cách chạy: paste vào Supabase SQL Editor → Run.
-- Script idempotent: chạy lại nhiều lần vẫn an toàn nhờ IF NOT EXISTS / IF EXISTS.
-- Không xoá dữ liệu đang có.

-- Đảm bảo bảng tồn tại (nếu chưa có thì tạo full schema). Trường hợp đã có
-- thì lệnh này bị skip; phần ALTER bên dưới sẽ vá thêm các cột còn thiếu.
CREATE TABLE IF NOT EXISTS public."Reviews" (
    "Id"             SERIAL PRIMARY KEY,
    "UserId"         INT NOT NULL REFERENCES public."Users"("Id")        ON DELETE CASCADE,
    "RestaurantId"   INT NOT NULL REFERENCES public."Restaurants"("Id")  ON DELETE CASCADE,
    "OrderId"        INT,
    "Rating"         INT  NOT NULL DEFAULT 5,
    "Comment"        TEXT NOT NULL DEFAULT '',
    "SentimentScore" DOUBLE PRECISION,
    "CreatedDate"    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc', now()),
    "UpdatedDate"    TIMESTAMP WITH TIME ZONE,
    CONSTRAINT "CK_Reviews_Rating" CHECK ("Rating" BETWEEN 1 AND 5)
);

-- Vá các cột còn thiếu (cần khi bảng đã có sẵn từ trước nhưng schema khác).
ALTER TABLE public."Reviews"
    ADD COLUMN IF NOT EXISTS "OrderId"        INT,
    ADD COLUMN IF NOT EXISTS "Comment"        TEXT             NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS "Rating"         INT              NOT NULL DEFAULT 5,
    ADD COLUMN IF NOT EXISTS "SentimentScore" DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS "CreatedDate"    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc', now()),
    ADD COLUMN IF NOT EXISTS "UpdatedDate"    TIMESTAMP WITH TIME ZONE;

-- Đảm bảo có check constraint trên Rating (nếu chưa có).
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'CK_Reviews_Rating'
          AND conrelid = 'public."Reviews"'::regclass
    ) THEN
        ALTER TABLE public."Reviews"
            ADD CONSTRAINT "CK_Reviews_Rating" CHECK ("Rating" BETWEEN 1 AND 5);
    END IF;
END $$;

-- Index để truy vấn theo nhà hàng / theo user nhanh hơn.
CREATE INDEX IF NOT EXISTS "IX_Reviews_RestaurantId" ON public."Reviews"("RestaurantId");
CREATE INDEX IF NOT EXISTS "IX_Reviews_UserId"       ON public."Reviews"("UserId");
