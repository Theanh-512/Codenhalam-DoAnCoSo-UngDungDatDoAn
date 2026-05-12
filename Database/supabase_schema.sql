-- ============================================================
-- SQL Schema for M-CARS-Food (Supabase / PostgreSQL)
-- Generated to MATCH EF Core InitialCreate Migration exactly
-- Table names use PascalCase (EF Core default convention)
-- ============================================================

-- 1. Categories
CREATE TABLE IF NOT EXISTS public."Categories" (
    "Id"          SERIAL PRIMARY KEY,
    "Name"        TEXT NOT NULL,
    "Description" TEXT NOT NULL,
    "CreatedDate" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc', now()),
    "UpdatedDate" TIMESTAMP WITH TIME ZONE
);

-- 2. Restaurants
CREATE TABLE IF NOT EXISTS public."Restaurants" (
    "Id"           SERIAL PRIMARY KEY,
    "Name"         TEXT NOT NULL,
    "Description"  TEXT NOT NULL,
    "Address"      TEXT NOT NULL,
    "ImageUrl"     TEXT NOT NULL,
    "Latitude"     DOUBLE PRECISION NOT NULL,
    "Longitude"    DOUBLE PRECISION NOT NULL,
    "OpeningHours" TEXT NOT NULL,
    "IsActive"     BOOLEAN NOT NULL DEFAULT true,
    "CreatedDate"  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc', now()),
    "UpdatedDate"  TIMESTAMP WITH TIME ZONE
);

-- 3. Users (self-managed auth, NOT Supabase Auth)
CREATE TABLE IF NOT EXISTS public."Users" (
    "Id"            SERIAL PRIMARY KEY,
    "Email"         TEXT NOT NULL,
    "PasswordHash"  TEXT NOT NULL,
    "FullName"      TEXT NOT NULL,
    "PhoneNumber"   TEXT NOT NULL,
    "Address"       TEXT NOT NULL,
    "LastLatitude"  DOUBLE PRECISION,
    "LastLongitude" DOUBLE PRECISION,
    "CreatedDate"   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc', now()),
    "UpdatedDate"   TIMESTAMP WITH TIME ZONE
);

-- 4. Food Items
CREATE TABLE IF NOT EXISTS public."FoodItems" (
    "Id"                    SERIAL PRIMARY KEY,
    "Name"                  TEXT NOT NULL,
    "Description"           TEXT NOT NULL,
    "Price"                 DECIMAL(18,2) NOT NULL,
    "ImageUrl"              TEXT NOT NULL,
    "IsAvailable"           BOOLEAN NOT NULL DEFAULT true,
    "CategoryId"            INT NOT NULL REFERENCES public."Categories"("Id") ON DELETE CASCADE,
    "RestaurantId"          INT NOT NULL REFERENCES public."Restaurants"("Id") ON DELETE CASCADE,
    "VisualFeatureVector"   TEXT,   -- AI: DenseNet201 image embedding
    "TextualFeatureVector"  TEXT,   -- AI: BERT/RoBERTa text embedding
    "CreatedDate"           TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc', now()),
    "UpdatedDate"           TIMESTAMP WITH TIME ZONE
);

-- 5. Orders
CREATE TABLE IF NOT EXISTS public."Orders" (
    "Id"              SERIAL PRIMARY KEY,
    "UserId"          INT NOT NULL REFERENCES public."Users"("Id") ON DELETE CASCADE,
    "OrderDate"       TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc', now()),
    "TotalAmount"     DECIMAL(18,2) NOT NULL,
    "Status"          TEXT NOT NULL DEFAULT 'Pending',
    "DeliveryAddress" TEXT NOT NULL,
    "CreatedDate"     TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc', now()),
    "UpdatedDate"     TIMESTAMP WITH TIME ZONE,
    CONSTRAINT "CK_Orders_Status" CHECK ("Status" IN ('Pending', 'Completed', 'Cancelled'))
);

-- 6. Order Items
CREATE TABLE IF NOT EXISTS public."OrderItems" (
    "Id"          SERIAL PRIMARY KEY,
    "OrderId"     INT NOT NULL REFERENCES public."Orders"("Id") ON DELETE CASCADE,
    "FoodItemId"  INT NOT NULL REFERENCES public."FoodItems"("Id") ON DELETE CASCADE,
    "Quantity"    INT NOT NULL,
    "UnitPrice"   DECIMAL(18,2) NOT NULL,
    "CreatedDate" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc', now()),
    "UpdatedDate" TIMESTAMP WITH TIME ZONE
);

-- 7. Tracking Logs (AI Behavioral Data - SCR Theory)
CREATE TABLE IF NOT EXISTS public."TrackingLogs" (
    "Id"           SERIAL PRIMARY KEY,
    "UserId"       INT REFERENCES public."Users"("Id") ON DELETE SET NULL,  -- nullable (guest users)
    "RestaurantId" INT NOT NULL REFERENCES public."Restaurants"("Id") ON DELETE CASCADE,
    "SessionId"    TEXT,               -- Groups behavior by session (SCR Theory)
    "ActionType"   TEXT NOT NULL,      -- 'View', 'AddToCart', 'Click'
    "Latitude"     DOUBLE PRECISION NOT NULL,
    "Longitude"    DOUBLE PRECISION NOT NULL,
    "Timestamp"    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc', now()),
    "DeviceInfo"   TEXT NOT NULL,
    "CreatedDate"  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc', now()),
    "UpdatedDate"  TIMESTAMP WITH TIME ZONE
);

-- ============================================================
-- Indexes (matching EF Core generated indexes)
-- ============================================================
CREATE INDEX IF NOT EXISTS "IX_FoodItems_CategoryId"   ON public."FoodItems"("CategoryId");
CREATE INDEX IF NOT EXISTS "IX_FoodItems_RestaurantId" ON public."FoodItems"("RestaurantId");
CREATE INDEX IF NOT EXISTS "IX_OrderItems_FoodItemId"  ON public."OrderItems"("FoodItemId");
CREATE INDEX IF NOT EXISTS "IX_OrderItems_OrderId"     ON public."OrderItems"("OrderId");
CREATE INDEX IF NOT EXISTS "IX_Orders_UserId"          ON public."Orders"("UserId");

-- ============================================================
-- EF Core Migration History Table (required if using MigrateAsync)
-- ============================================================
CREATE TABLE IF NOT EXISTS public."__EFMigrationsHistory" (
    "MigrationId"    VARCHAR(150) NOT NULL,
    "ProductVersion" VARCHAR(32)  NOT NULL,
    CONSTRAINT "PK___EFMigrationsHistory" PRIMARY KEY ("MigrationId")
);
