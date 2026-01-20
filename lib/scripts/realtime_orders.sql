-- Enable Realtime for orders table
-- Run this in Supabase SQL Editor

-- 1. Enable replication for the orders table
ALTER TABLE munajat_app.orders REPLICA IDENTITY FULL;

-- 2. Add orders table to the supabase_realtime publication
BEGIN;
  DROP PUBLICATION IF EXISTS supabase_realtime;
  CREATE PUBLICATION supabase_realtime FOR TABLE munajat_app.orders;
COMMIT;
