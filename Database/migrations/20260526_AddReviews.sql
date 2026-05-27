-- Tạo bảng Reviews cho tính năng đánh giá nhà hàng (5 sao + comment).
-- Chạy trên Supabase: paste vào SQL Editor rồi Run.
--
-- Liên kết:
--   - Reviews.UserId        -> Users.Id        (cascade delete)
--   - Reviews.RestaurantId  -> Restaurants.Id  (cascade delete)
--   - Reviews.OrderId       -> nullable, không ràng buộc FK cứng để tránh
--     khoá thao tác xoá đơn cũ; logic ràng buộc qua app layer.
--
-- Sentiment_Score nullable: dành cho pipeline NLP (AIService) sau này.

CREATE TABLE IF NOT EXISTS "Reviews" (
    "Id"             SERIAL PRIMARY KEY,
    "UserId"         INTEGER          NOT NULL,
    "RestaurantId"   INTEGER          NOT NULL,
    "OrderId"        INTEGER          NULL,
    "Rating"         INTEGER          NOT NULL DEFAULT 5,
    "Comment"        TEXT             NOT NULL DEFAULT '',
    "SentimentScore" DOUBLE PRECISION NULL,
    "CreatedDate"    TIMESTAMP        NOT NULL DEFAULT NOW(),
    "UpdatedDate"    TIMESTAMP        NULL,
    CONSTRAINT "Reviews_Rating_chk" CHECK ("Rating" BETWEEN 1 AND 5),
    CONSTRAINT "Reviews_UserId_fk"
        FOREIGN KEY ("UserId") REFERENCES "Users"("Id") ON DELETE CASCADE,
    CONSTRAINT "Reviews_RestaurantId_fk"
        FOREIGN KEY ("RestaurantId") REFERENCES "Restaurants"("Id") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS "Reviews_RestaurantId_idx"
    ON "Reviews" ("RestaurantId");
CREATE INDEX IF NOT EXISTS "Reviews_UserId_idx"
    ON "Reviews" ("UserId");
