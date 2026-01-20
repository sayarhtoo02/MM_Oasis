-- Halal Shop Database Schema for Supabase
-- Run this in the Supabase SQL Editor to create the required tables

-- Create the munajat_app schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS munajat_app;

-- ========== SHOPS TABLE ==========
CREATE TABLE IF NOT EXISTS munajat_app.shops (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    address TEXT,
    contact_phone TEXT,
    contact_email TEXT,
    website TEXT,
    lat DOUBLE PRECISION,
    long DOUBLE PRECISION,
    category TEXT DEFAULT 'restaurant',
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'suspended')),
    rejection_reason TEXT,
    operating_hours JSONB DEFAULT '{}',
    is_verified BOOLEAN DEFAULT FALSE,
    approved_at TIMESTAMPTZ,
    approved_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ========== SHOP IMAGES TABLE ==========
CREATE TABLE IF NOT EXISTS munajat_app.shop_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shop_id UUID NOT NULL REFERENCES munajat_app.shops(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    image_type TEXT NOT NULL CHECK (image_type IN ('logo', 'cover', 'gallery')),
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ========== SHOP MENU CATEGORIES TABLE ==========
CREATE TABLE IF NOT EXISTS munajat_app.shop_menu_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shop_id UUID NOT NULL REFERENCES munajat_app.shops(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ========== SHOP MENU ITEMS TABLE ==========
CREATE TABLE IF NOT EXISTS munajat_app.shop_menu_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shop_id UUID NOT NULL REFERENCES munajat_app.shops(id) ON DELETE CASCADE,
    category_id UUID REFERENCES munajat_app.shop_menu_categories(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10, 2),
    image_url TEXT,
    is_available BOOLEAN DEFAULT TRUE,
    is_halal_certified BOOLEAN DEFAULT FALSE,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ========== SHOP REVIEWS TABLE ==========
CREATE TABLE IF NOT EXISTS munajat_app.shop_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shop_id UUID NOT NULL REFERENCES munajat_app.shops(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(shop_id, user_id)
);

-- ========== USER FAVORITES TABLE ==========
CREATE TABLE IF NOT EXISTS munajat_app.user_favorites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    shop_id UUID NOT NULL REFERENCES munajat_app.shops(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, shop_id)
);

-- ========== ADMIN ACTIONS AUDIT TABLE ==========
CREATE TABLE IF NOT EXISTS munajat_app.admin_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID NOT NULL REFERENCES auth.users(id),
    action_type TEXT NOT NULL,
    target_type TEXT,
    target_table TEXT,
    target_id TEXT,
    details JSONB,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ========== ROW LEVEL SECURITY POLICIES ==========

-- Enable RLS on all tables
ALTER TABLE munajat_app.shops ENABLE ROW LEVEL SECURITY;
ALTER TABLE munajat_app.shop_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE munajat_app.shop_menu_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE munajat_app.shop_menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE munajat_app.shop_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE munajat_app.user_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE munajat_app.admin_actions ENABLE ROW LEVEL SECURITY;

-- SHOPS: Public can read approved shops, owners can manage their own
CREATE POLICY "Approved shops are public" ON munajat_app.shops
    FOR SELECT USING (status = 'approved');

CREATE POLICY "Owners can view own shops" ON munajat_app.shops
    FOR SELECT USING (auth.uid() = owner_id);

CREATE POLICY "Admins can view all shops" ON munajat_app.shops
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM munajat_app.profiles WHERE user_id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Users can create shops" ON munajat_app.shops
    FOR INSERT WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Owners can update own shops" ON munajat_app.shops
    FOR UPDATE USING (auth.uid() = owner_id);

CREATE POLICY "Owners can delete own shops" ON munajat_app.shops
    FOR DELETE USING (auth.uid() = owner_id);

CREATE POLICY "Admins can update any shop" ON munajat_app.shops
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM munajat_app.profiles WHERE user_id = auth.uid() AND role = 'admin')
    );

-- SHOP IMAGES: Public read for approved shops, owner can manage
CREATE POLICY "Public can view images of approved shops" ON munajat_app.shop_images
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM munajat_app.shops WHERE id = shop_id AND status = 'approved')
    );

CREATE POLICY "Owners can manage shop images" ON munajat_app.shop_images
    FOR ALL USING (
        EXISTS (SELECT 1 FROM munajat_app.shops WHERE id = shop_id AND owner_id = auth.uid())
    );

-- SHOP MENU CATEGORIES: Same as images
CREATE POLICY "Public can view menu categories" ON munajat_app.shop_menu_categories
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM munajat_app.shops WHERE id = shop_id AND status = 'approved')
    );

CREATE POLICY "Owners can manage menu categories" ON munajat_app.shop_menu_categories
    FOR ALL USING (
        EXISTS (SELECT 1 FROM munajat_app.shops WHERE id = shop_id AND owner_id = auth.uid())
    );

-- SHOP MENU ITEMS: Same pattern
CREATE POLICY "Public can view menu items" ON munajat_app.shop_menu_items
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM munajat_app.shops WHERE id = shop_id AND status = 'approved')
    );

CREATE POLICY "Owners can manage menu items" ON munajat_app.shop_menu_items
    FOR ALL USING (
        EXISTS (SELECT 1 FROM munajat_app.shops WHERE id = shop_id AND owner_id = auth.uid())
    );

-- REVIEWS: Public read, users can manage their own
CREATE POLICY "Public can view reviews" ON munajat_app.shop_reviews
    FOR SELECT USING (true);

CREATE POLICY "Users can create reviews" ON munajat_app.shop_reviews
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own reviews" ON munajat_app.shop_reviews
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own reviews" ON munajat_app.shop_reviews
    FOR DELETE USING (auth.uid() = user_id);

-- FAVORITES: Users can manage their own
CREATE POLICY "Users can view own favorites" ON munajat_app.user_favorites
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage favorites" ON munajat_app.user_favorites
    FOR ALL USING (auth.uid() = user_id);

-- ADMIN ACTIONS: Only admins can access
CREATE POLICY "Admins can view logs" ON munajat_app.admin_actions
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM munajat_app.profiles WHERE user_id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Admins can insert logs" ON munajat_app.admin_actions
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM munajat_app.profiles WHERE user_id = auth.uid() AND role = 'admin')
    );

-- ========== INDEXES FOR PERFORMANCE ==========
CREATE INDEX IF NOT EXISTS idx_shops_owner ON munajat_app.shops(owner_id);
CREATE INDEX IF NOT EXISTS idx_shops_status ON munajat_app.shops(status);
CREATE INDEX IF NOT EXISTS idx_shop_images_shop ON munajat_app.shop_images(shop_id);
CREATE INDEX IF NOT EXISTS idx_shop_menu_categories_shop ON munajat_app.shop_menu_categories(shop_id);
CREATE INDEX IF NOT EXISTS idx_shop_menu_items_shop ON munajat_app.shop_menu_items(shop_id);
CREATE INDEX IF NOT EXISTS idx_shop_reviews_shop ON munajat_app.shop_reviews(shop_id);
CREATE INDEX IF NOT EXISTS idx_user_favorites_user ON munajat_app.user_favorites(user_id);

-- ========== STORAGE BUCKET ==========
-- Note: Run this separately or use the Supabase dashboard to create:
-- Storage bucket: "shop-images" with public read access
