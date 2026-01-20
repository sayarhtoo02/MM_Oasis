-- Fix RLS Policies for ads_banners Table
-- Run this in your Supabase SQL Editor

BEGIN;

-- 1. Enable RLS on ads_banners if not already enabled
ALTER TABLE munajat_app.ads_banners ENABLE ROW LEVEL SECURITY;

-- 2. Drop any existing policies (if any)
DROP POLICY IF EXISTS "Anyone can view active ads" ON munajat_app.ads_banners;
DROP POLICY IF EXISTS "Admins can manage ads" ON munajat_app.ads_banners;
DROP POLICY IF EXISTS "Admins can view all ads" ON munajat_app.ads_banners;
DROP POLICY IF EXISTS "Admins can create ads" ON munajat_app.ads_banners;
DROP POLICY IF EXISTS "Admins can update ads" ON munajat_app.ads_banners;
DROP POLICY IF EXISTS "Admins can delete ads" ON munajat_app.ads_banners;

-- 3. Create policies

-- Anyone can view active ads (for the banner widget)
CREATE POLICY "Anyone can view active ads"
ON munajat_app.ads_banners
FOR SELECT
USING (is_active = true);

-- Admins can view all ads (including inactive)
CREATE POLICY "Admins can view all ads"
ON munajat_app.ads_banners
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid() AND profiles.is_admin = true
  )
);

-- Admins can create ads
CREATE POLICY "Admins can create ads"
ON munajat_app.ads_banners
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid() AND profiles.is_admin = true
  )
);

-- Admins can update ads
CREATE POLICY "Admins can update ads"
ON munajat_app.ads_banners
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid() AND profiles.is_admin = true
  )
);

-- Admins can delete ads
CREATE POLICY "Admins can delete ads"
ON munajat_app.ads_banners
FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid() AND profiles.is_admin = true
  )
);

COMMIT;
