-- Orders System Migration for Halal Shop
-- Run this in Supabase SQL Editor

-- 1. Create shop_payment_methods table
CREATE TABLE IF NOT EXISTS munajat_app.shop_payment_methods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID REFERENCES munajat_app.shops(id) ON DELETE CASCADE,
  method_type TEXT NOT NULL, -- bank, kpay, wavepay, ayapay, cbpay, etc.
  account_name TEXT,
  account_number TEXT,
  qr_code_url TEXT,
  is_active BOOLEAN DEFAULT true,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Create orders table
CREATE TABLE IF NOT EXISTS munajat_app.orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID REFERENCES munajat_app.shops(id),
  customer_id UUID REFERENCES auth.users(id),
  status TEXT DEFAULT 'pending_payment',
  -- Statuses: pending_payment, payment_uploaded, payment_confirmed, preparing, ready, completed, cancelled
  order_type TEXT DEFAULT 'in_app', -- in_app, phone
  total_amount DECIMAL(10,2) NOT NULL,
  payment_screenshot_url TEXT,
  notes TEXT,
  customer_name TEXT,
  customer_phone TEXT,
  delivery_address TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Create order_items table
CREATE TABLE IF NOT EXISTS munajat_app.order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES munajat_app.orders(id) ON DELETE CASCADE,
  menu_item_id UUID REFERENCES munajat_app.shop_menu_items(id),
  item_name TEXT NOT NULL,
  item_price DECIMAL(10,2) NOT NULL,
  quantity INTEGER DEFAULT 1,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 4. Enable RLS
ALTER TABLE munajat_app.shop_payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE munajat_app.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE munajat_app.order_items ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies for shop_payment_methods
-- Public can view active payment methods
CREATE POLICY "Anyone can view active payment methods"
  ON munajat_app.shop_payment_methods FOR SELECT
  USING (is_active = true);

-- Shop owners can manage their payment methods
CREATE POLICY "Owners can manage payment methods"
  ON munajat_app.shop_payment_methods FOR ALL
  USING (
    shop_id IN (SELECT id FROM munajat_app.shops WHERE owner_id = auth.uid())
  );

-- 6. RLS Policies for orders
-- Customers can view their own orders
CREATE POLICY "Customers can view own orders"
  ON munajat_app.orders FOR SELECT
  USING (customer_id = auth.uid());

-- Customers can create orders
CREATE POLICY "Customers can create orders"
  ON munajat_app.orders FOR INSERT
  WITH CHECK (customer_id = auth.uid());

-- Customers can update their own orders (for payment upload)
CREATE POLICY "Customers can update own orders"
  ON munajat_app.orders FOR UPDATE
  USING (customer_id = auth.uid());

-- Shop owners can view orders for their shops
CREATE POLICY "Owners can view shop orders"
  ON munajat_app.orders FOR SELECT
  USING (
    shop_id IN (SELECT id FROM munajat_app.shops WHERE owner_id = auth.uid())
  );

-- Shop owners can update orders for their shops
CREATE POLICY "Owners can update shop orders"
  ON munajat_app.orders FOR UPDATE
  USING (
    shop_id IN (SELECT id FROM munajat_app.shops WHERE owner_id = auth.uid())
  );

-- 7. RLS Policies for order_items
-- Anyone involved can view order items
CREATE POLICY "Users can view order items"
  ON munajat_app.order_items FOR SELECT
  USING (
    order_id IN (
      SELECT id FROM munajat_app.orders 
      WHERE customer_id = auth.uid()
         OR shop_id IN (SELECT id FROM munajat_app.shops WHERE owner_id = auth.uid())
    )
  );

-- Customers can add items to their orders
CREATE POLICY "Customers can add order items"
  ON munajat_app.order_items FOR INSERT
  WITH CHECK (
    order_id IN (SELECT id FROM munajat_app.orders WHERE customer_id = auth.uid())
  );

-- 8. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_orders_shop_id ON munajat_app.orders(shop_id);
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON munajat_app.orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON munajat_app.orders(status);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON munajat_app.order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_shop_payment_methods_shop_id ON munajat_app.shop_payment_methods(shop_id);

-- 9. Create updated_at trigger for orders
CREATE OR REPLACE FUNCTION munajat_app.update_orders_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER orders_updated_at
  BEFORE UPDATE ON munajat_app.orders
  FOR EACH ROW
  EXECUTE FUNCTION munajat_app.update_orders_updated_at();
