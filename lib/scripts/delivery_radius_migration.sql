-- Add delivery_radius_km for distance calculations
ALTER TABLE munajat_app.shops
ADD COLUMN IF NOT EXISTS delivery_radius_km FLOAT DEFAULT 5.0; -- Default 5km radius
