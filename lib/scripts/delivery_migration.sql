-- Add delivery information to shops table

ALTER TABLE munajat_app.shops 
ADD COLUMN IF NOT EXISTS is_delivery_available BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS delivery_range TEXT; -- e.g. "5 miles", "10 km", "Downtown area"

-- No RLS changes needed as existing policies cover the table
