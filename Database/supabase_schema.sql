-- ============================================================
-- SQL Schema for FastBite (Supabase / PostgreSQL)
-- Đồng bộ với entity .NET (Backend/Domain/Entities/*) sau migration
-- 20260523182951_AddOrderDetailsAndRestaurantRating.
-- Table names theo PascalCase (EF Core default).
-- ============================================================

CREATE EXTENSION IF NOT EXISTS unaccent;

-- 1. Categories
CREATE TABLE IF NOT EXISTS public."Categories" (
    "Id"          SERIAL PRIMARY KEY,
    "Name"        TEXT NOT NULL,
    "Description" TEXT,
    "ImageUrl"    TEXT,
    "CreatedDate" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc', now()),
    "UpdatedDate" TIMESTAMP WITH TIME ZONE
);

-- 2. Restaurants
CREATE TABLE IF NOT EXISTS public."Restaurants" (
    "Id"           SERIAL PRIMARY KEY,
    "Name"         TEXT NOT NULL,
    "Description"  TEXT NOT NULL DEFAULT '',
    "Address"      TEXT NOT NULL DEFAULT '',
    "ImageUrl"     TEXT NOT NULL DEFAULT '',
    "Type1"        TEXT NOT NULL DEFAULT '',
    "Type2"        TEXT NOT NULL DEFAULT '',
    "Latitude"     DOUBLE PRECISION NOT NULL DEFAULT 0,
    "Longitude"    DOUBLE PRECISION NOT NULL DEFAULT 0,
    "OpeningHours" TEXT NOT NULL DEFAULT '',
    "IsActive"     BOOLEAN NOT NULL DEFAULT true,
    "Rating"       DOUBLE PRECISION NOT NULL DEFAULT 0,
    "ReviewCount"  INT              NOT NULL DEFAULT 0,
    "CreatedDate"  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc', now()),
    "UpdatedDate"  TIMESTAMP WITH TIME ZONE
);

-- 3. Users (self-managed auth, KHÔNG dùng Supabase Auth)
-- PasswordHash: BCrypt ($2a$/$2b$/$2y$). Legacy plain-text được tự động upgrade khi login.
CREATE TABLE IF NOT EXISTS public."Users" (
    "Id"            SERIAL PRIMARY KEY,
    "Email"         TEXT NOT NULL,
    "PasswordHash"  TEXT NOT NULL,
    "FullName"      TEXT NOT NULL DEFAULT '',
    "PhoneNumber"   TEXT NOT NULL DEFAULT '',
    "Address"       TEXT NOT NULL DEFAULT '',
    "UserRole"      TEXT NOT NULL DEFAULT 'User',
    "LastLatitude"  DOUBLE PRECISION,
    "LastLongitude" DOUBLE PRECISION,
    "CreatedDate"   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc', now()),
    "UpdatedDate"   TIMESTAMP WITH TIME ZONE,
    CONSTRAINT "UQ_Users_Email" UNIQUE ("Email"),
    CONSTRAINT "CK_Users_Role"  CHECK ("UserRole" IN ('User', 'Admin', 'Shipper'))
);

-- 4. Food Items
CREATE TABLE IF NOT EXISTS public."FoodItems" (
    "Id"                   SERIAL PRIMARY KEY,
    "Name"                 TEXT NOT NULL,
    "Description"          TEXT,
    "Price"                NUMERIC(18,2) NOT NULL,
    "ImageUrl"             TEXT,
    "IsAvailable"          BOOLEAN NOT NULL DEFAULT true,
    "CategoryId"           INT NOT NULL REFERENCES public."Categories"("Id") ON DELETE CASCADE,
    "RestaurantId"         INT NOT NULL REFERENCES public."Restaurants"("Id") ON DELETE CASCADE,
    "Rating"               DOUBLE PRECISION NOT NULL DEFAULT 0,
    "VisualFeatureVector"  TEXT,   -- AI: DenseNet201 image embedding
    "TextualFeatureVector" TEXT,   -- AI: BERT/RoBERTa text embedding
    "CreatedDate"          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc', now()),
    "UpdatedDate"          TIMESTAMP WITH TIME ZONE
);

-- 5. Orders
CREATE TABLE IF NOT EXISTS public."Orders" (
    "Id"                SERIAL PRIMARY KEY,
    "UserId"            INT NOT NULL REFERENCES public."Users"("Id") ON DELETE CASCADE,
    "OrderDate"         TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc', now()),
    "TotalAmount"       NUMERIC(18,2) NOT NULL,
    "Status"            TEXT NOT NULL DEFAULT 'Pending',
    "DeliveryAddress"   TEXT NOT NULL DEFAULT '',
    "ReceiverName"      TEXT NOT NULL DEFAULT '',
    "ReceiverPhone"     TEXT NOT NULL DEFAULT '',
    "DeliveryLatitude"  DOUBLE PRECISION,
    "DeliveryLongitude" DOUBLE PRECISION,
    "PaymentMethod"     TEXT NOT NULL DEFAULT 'cod',
    "VoucherCode"       TEXT NOT NULL DEFAULT '',
    "CreatedDate"       TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc', now()),
    "UpdatedDate"       TIMESTAMP WITH TIME ZONE,
    CONSTRAINT "CK_Orders_Status" CHECK ("Status" IN (
        'Pending', 'Confirmed', 'Preparing', 'Delivering', 'Completed', 'Cancelled'
    ))
);

-- 6. Order Items
CREATE TABLE IF NOT EXISTS public."OrderItems" (
    "Id"          SERIAL PRIMARY KEY,
    "OrderId"     INT NOT NULL REFERENCES public."Orders"("Id") ON DELETE CASCADE,
    "FoodItemId"  INT NOT NULL REFERENCES public."FoodItems"("Id") ON DELETE CASCADE,
    "Quantity"    INT NOT NULL,
    "UnitPrice"   NUMERIC(18,2) NOT NULL,
    "CreatedDate" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc', now()),
    "UpdatedDate" TIMESTAMP WITH TIME ZONE
);

-- 7. Reviews (đánh giá nhà hàng + sentiment cho AI)
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

-- 8. Tracking Logs (AI behavioral data - SCR Theory)
CREATE TABLE IF NOT EXISTS public."TrackingLogs" (
    "Id"           SERIAL PRIMARY KEY,
    "UserId"       INT REFERENCES public."Users"("Id") ON DELETE SET NULL,
    "RestaurantId" INT NOT NULL REFERENCES public."Restaurants"("Id") ON DELETE CASCADE,
    "SessionId"    TEXT,
    "ActionType"   TEXT NOT NULL,      -- 'View' | 'AddToCart' | 'Click'
    "Latitude"     DOUBLE PRECISION NOT NULL,
    "Longitude"    DOUBLE PRECISION NOT NULL,
    "Timestamp"    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc', now()),
    "DeviceInfo"   TEXT NOT NULL DEFAULT '',
    "CreatedDate"  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc', now()),
    "UpdatedDate"  TIMESTAMP WITH TIME ZONE
);

-- ============================================================
-- Indexes (đồng bộ với EF Core)
-- ============================================================
CREATE INDEX IF NOT EXISTS "IX_FoodItems_CategoryId"     ON public."FoodItems"("CategoryId");
CREATE INDEX IF NOT EXISTS "IX_FoodItems_RestaurantId"   ON public."FoodItems"("RestaurantId");
CREATE INDEX IF NOT EXISTS "IX_OrderItems_FoodItemId"    ON public."OrderItems"("FoodItemId");
CREATE INDEX IF NOT EXISTS "IX_OrderItems_OrderId"       ON public."OrderItems"("OrderId");
CREATE INDEX IF NOT EXISTS "IX_Orders_UserId"            ON public."Orders"("UserId");
CREATE INDEX IF NOT EXISTS "IX_TrackingLogs_RestaurantId" ON public."TrackingLogs"("RestaurantId");
CREATE INDEX IF NOT EXISTS "IX_TrackingLogs_UserId"      ON public."TrackingLogs"("UserId");
CREATE INDEX IF NOT EXISTS "IX_Reviews_RestaurantId"     ON public."Reviews"("RestaurantId");
CREATE INDEX IF NOT EXISTS "IX_Reviews_UserId"           ON public."Reviews"("UserId");
CREATE UNIQUE INDEX IF NOT EXISTS "IX_Users_Email"       ON public."Users"(LOWER("Email"));

-- ============================================================
-- EF Core Migration History Table
-- ============================================================
CREATE TABLE IF NOT EXISTS public."__EFMigrationsHistory" (
    "MigrationId"    VARCHAR(150) NOT NULL,
    "ProductVersion" VARCHAR(32)  NOT NULL,
    CONSTRAINT "PK___EFMigrationsHistory" PRIMARY KEY ("MigrationId")
);
