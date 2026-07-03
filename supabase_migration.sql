-- =============================================
-- Supabase Migration SQL for NeoSaver App
-- Run this in Supabase Dashboard > SQL Editor
-- =============================================

-- 1. USERS TABLE
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,  -- Firebase UID
  name TEXT,
  first_name TEXT,
  last_name TEXT,
  phone TEXT,
  address TEXT,
  post_code TEXT,
  email TEXT,
  role TEXT DEFAULT 'user',
  accepted_terms BOOLEAN DEFAULT true,
  profile_image_url TEXT,
  fcm_token TEXT,
  last_token_update TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true,
  last_login TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. DRIVERS TABLE
CREATE TABLE IF NOT EXISTS drivers (
  id TEXT PRIMARY KEY,  -- Firebase UID
  name TEXT,
  first_name TEXT,
  last_name TEXT,
  phone TEXT,
  address TEXT,
  post_code TEXT,
  email TEXT,
  role TEXT DEFAULT 'driver',
  accepted_terms BOOLEAN DEFAULT true,
  profile_image_url TEXT,
  license_image_url TEXT,
  ambulance_image_url TEXT,
  nid_image_url TEXT,
  registration_papers_image_url TEXT,
  fcm_token TEXT,
  last_token_update TIMESTAMPTZ,
  is_approved BOOLEAN DEFAULT true,
  is_online BOOLEAN DEFAULT false,
  company_name TEXT,
  last_login TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. PARTNERS TABLE (lightweight reference)
CREATE TABLE IF NOT EXISTS partners (
  id TEXT PRIMARY KEY,  -- Firebase UID
  role TEXT DEFAULT 'driver',
  name TEXT,
  phone TEXT,
  profile_image_url TEXT,
  ambulance_image_url TEXT,
  ambulance_type TEXT,
  vehicle_number TEXT,
  license_number TEXT,
  company_name TEXT,
  contact TEXT,
  coverage_area TEXT,
  indoor_city_rate DOUBLE PRECISION,
  outdoor_city_rate DOUBLE PRECISION,
  service_rate DOUBLE PRECISION,
  rates_last_updated TIMESTAMPTZ,
  is_online BOOLEAN DEFAULT false,
  is_approved BOOLEAN DEFAULT true,
  is_active BOOLEAN DEFAULT true,
  data_ref TEXT,
  fcm_token TEXT,
  last_token_update TIMESTAMPTZ,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  current_address TEXT,
  heading DOUBLE PRECISION,
  last_location_update TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Ensure new partner profile fields exist for existing schemas
ALTER TABLE partners ADD COLUMN IF NOT EXISTS profile_image_url TEXT;
ALTER TABLE partners ADD COLUMN IF NOT EXISTS ambulance_image_url TEXT;
ALTER TABLE partners ADD COLUMN IF NOT EXISTS ambulance_type TEXT;
ALTER TABLE partners ADD COLUMN IF NOT EXISTS vehicle_number TEXT;
ALTER TABLE partners ADD COLUMN IF NOT EXISTS license_number TEXT;
ALTER TABLE partners ADD COLUMN IF NOT EXISTS company_name TEXT;
ALTER TABLE partners ADD COLUMN IF NOT EXISTS contact TEXT;
ALTER TABLE partners ADD COLUMN IF NOT EXISTS coverage_area TEXT;
ALTER TABLE partners ADD COLUMN IF NOT EXISTS indoor_city_rate DOUBLE PRECISION;
ALTER TABLE partners ADD COLUMN IF NOT EXISTS outdoor_city_rate DOUBLE PRECISION;
ALTER TABLE partners ADD COLUMN IF NOT EXISTS service_rate DOUBLE PRECISION;
ALTER TABLE partners ADD COLUMN IF NOT EXISTS rates_last_updated TIMESTAMPTZ;

-- 4. ORDERS TABLE
CREATE TABLE IF NOT EXISTS orders (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  partner_id TEXT,
  user_name TEXT,
  user_phone TEXT,
  partner_name TEXT,
  partner_phone TEXT,
  company_name TEXT,
  pickup_address TEXT,
  destination_address TEXT,
  pickup_latitude DOUBLE PRECISION,
  pickup_longitude DOUBLE PRECISION,
  destination_latitude DOUBLE PRECISION,
  destination_longitude DOUBLE PRECISION,
  status TEXT DEFAULT 'pending',
  type TEXT DEFAULT 'ambulance',
  urgency TEXT,
  notes TEXT,
  fare DOUBLE PRECISION,
  initial_fare DOUBLE PRECISION,
  counter_fare DOUBLE PRECISION,
  final_fare DOUBLE PRECISION,
  user_fare DOUBLE PRECISION,
  partner_fare DOUBLE PRECISION,
  distance_km DOUBLE PRECISION,
  duration_mins DOUBLE PRECISION,
  fare_status TEXT,
  payment_method TEXT,
  rating DOUBLE PRECISION,
  review TEXT,
  is_rated BOOLEAN DEFAULT false,
  accepted_at TIMESTAMPTZ,
  picked_up_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  -- Store any extra JSON data
  extra_data JSONB DEFAULT '{}'::jsonb
);

-- 5. RIDE REQUESTS TABLE
CREATE TABLE IF NOT EXISTS ride_requests (
  id TEXT PRIMARY KEY,
  request_id TEXT,
  user_id TEXT,
  user_name TEXT,
  user_phone TEXT,
  driver_id TEXT,
  pickup_address TEXT,
  destination_address TEXT,
  pickup_latitude DOUBLE PRECISION,
  pickup_longitude DOUBLE PRECISION,
  notes TEXT,
  urgency TEXT,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. ORDER REVIEWS TABLE
CREATE TABLE IF NOT EXISTS order_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id TEXT,
  user_id TEXT,
  partner_id TEXT,
  company_name TEXT,
  driver_rating DOUBLE PRECISION,
  company_rating DOUBLE PRECISION,
  complaint TEXT,
  timestamp TIMESTAMPTZ,
  rating DOUBLE PRECISION,
  review TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT,
  name TEXT,
  email TEXT,
  feedback TEXT,
  rating INTEGER,
  attachment_urls JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. ADMINS TABLE
CREATE TABLE IF NOT EXISTS admins (
  id TEXT PRIMARY KEY,  -- Firebase UID
  email TEXT,
  role TEXT DEFAULT 'admin',
  name TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_login TIMESTAMPTZ
);

-- 8. GLM ACCOUNTS TABLE
CREATE TABLE IF NOT EXISTS glm_accounts (
  id TEXT PRIMARY KEY,
  name TEXT,
  email TEXT,
  phone TEXT,
  password TEXT,
  area TEXT,
  score INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. NOTIFICATION LOGS TABLE
CREATE TABLE IF NOT EXISTS notification_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type TEXT,
  title TEXT,
  body TEXT,
  recipient_id TEXT,
  recipient_type TEXT,
  sender_id TEXT,
  status TEXT,
  error TEXT,
  extra_data JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. PENDING NOTIFICATIONS TABLE
CREATE TABLE IF NOT EXISTS pending_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_id TEXT,
  recipient_type TEXT,
  title TEXT,
  body TEXT,
  data JSONB DEFAULT '{}'::jsonb,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. ADMIN NOTIFICATIONS TABLE
CREATE TABLE IF NOT EXISTS admin_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT,
  message TEXT,
  target TEXT,
  recipient_count INTEGER DEFAULT 0,
  sent_at TIMESTAMPTZ DEFAULT NOW()
);

-- 12. ADMIN ALERTS TABLE
CREATE TABLE IF NOT EXISTS admin_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type TEXT,
  title TEXT,
  message TEXT,
  order_id TEXT,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 13. USER NOTIFICATIONS TABLE (replaces Firestore subcollection users/{uid}/notifications)
CREATE TABLE IF NOT EXISTS user_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,
  title TEXT,
  body TEXT,
  type TEXT,
  order_id TEXT,
  is_read BOOLEAN DEFAULT false,
  extra_data JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 14. PARTNER NOTIFICATIONS TABLE (replaces Firestore subcollection partners/{pid}/notifications)
CREATE TABLE IF NOT EXISTS partner_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  partner_id TEXT NOT NULL,
  title TEXT,
  body TEXT,
  type TEXT,
  order_id TEXT,
  is_read BOOLEAN DEFAULT false,
  extra_data JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE users ADD COLUMN IF NOT EXISTS last_token_update TIMESTAMPTZ;
ALTER TABLE drivers ADD COLUMN IF NOT EXISTS last_token_update TIMESTAMPTZ;
ALTER TABLE partners ADD COLUMN IF NOT EXISTS last_token_update TIMESTAMPTZ;

-- =============================================
-- INDEXES for better query performance
-- =============================================
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_partner_id ON orders(partner_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_ride_requests_driver_id ON ride_requests(driver_id);
CREATE INDEX IF NOT EXISTS idx_ride_requests_status ON ride_requests(status);
CREATE INDEX IF NOT EXISTS idx_partners_is_online ON partners(is_online);
CREATE INDEX IF NOT EXISTS idx_user_notifications_user_id ON user_notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_partner_notifications_partner_id ON partner_notifications(partner_id);
CREATE INDEX IF NOT EXISTS idx_order_reviews_order_id ON order_reviews(order_id);
CREATE INDEX IF NOT EXISTS idx_notification_logs_recipient_id ON notification_logs(recipient_id);

-- =============================================
-- ENABLE REALTIME for tables that need live updates
-- =============================================
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'orders') THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'partners') THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.partners;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'ride_requests') THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.ride_requests;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'user_notifications') THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.user_notifications;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'partner_notifications') THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.partner_notifications;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'admin_alerts') THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.admin_alerts;
    END IF;
  END IF;
END $$;

-- =============================================
-- ROW LEVEL SECURITY (RLS) - Basic policies
-- For now, allow all operations (you can tighten later)
-- =============================================
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE partners ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE ride_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE glm_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE pending_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE partner_notifications ENABLE ROW LEVEL SECURITY;

-- Allow all access with anon key (you can restrict later for production)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'users' AND policyname = 'Allow all access') THEN
    CREATE POLICY "Allow all access" ON users FOR ALL USING (true) WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'drivers' AND policyname = 'Allow all access') THEN
    CREATE POLICY "Allow all access" ON drivers FOR ALL USING (true) WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'partners' AND policyname = 'Allow all access') THEN
    CREATE POLICY "Allow all access" ON partners FOR ALL USING (true) WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'orders' AND policyname = 'Allow all access') THEN
    CREATE POLICY "Allow all access" ON orders FOR ALL USING (true) WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ride_requests' AND policyname = 'Allow all access') THEN
    CREATE POLICY "Allow all access" ON ride_requests FOR ALL USING (true) WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'order_reviews' AND policyname = 'Allow all access') THEN
    CREATE POLICY "Allow all access" ON order_reviews FOR ALL USING (true) WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'feedback' AND policyname = 'Allow all access') THEN
    CREATE POLICY "Allow all access" ON feedback FOR ALL USING (true) WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'admins' AND policyname = 'Allow all access') THEN
    CREATE POLICY "Allow all access" ON admins FOR ALL USING (true) WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'glm_accounts' AND policyname = 'Allow all access') THEN
    CREATE POLICY "Allow all access" ON glm_accounts FOR ALL USING (true) WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'notification_logs' AND policyname = 'Allow all access') THEN
    CREATE POLICY "Allow all access" ON notification_logs FOR ALL USING (true) WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'pending_notifications' AND policyname = 'Allow all access') THEN
    CREATE POLICY "Allow all access" ON pending_notifications FOR ALL USING (true) WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'admin_notifications' AND policyname = 'Allow all access') THEN
    CREATE POLICY "Allow all access" ON admin_notifications FOR ALL USING (true) WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'admin_alerts' AND policyname = 'Allow all access') THEN
    CREATE POLICY "Allow all access" ON admin_alerts FOR ALL USING (true) WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'user_notifications' AND policyname = 'Allow all access') THEN
    CREATE POLICY "Allow all access" ON user_notifications FOR ALL USING (true) WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'partner_notifications' AND policyname = 'Allow all access') THEN
    CREATE POLICY "Allow all access" ON partner_notifications FOR ALL USING (true) WITH CHECK (true);
  END IF;
END $$;

-- =============================================
-- PATCH: Add ALL missing columns to orders table
-- Run this in Supabase Dashboard > SQL Editor
-- =============================================
ALTER TABLE orders ADD COLUMN IF NOT EXISTS partner_live_location JSONB;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS partner_location JSONB;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS pickup_latitude DOUBLE PRECISION;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS pickup_longitude DOUBLE PRECISION;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS destination_latitude DOUBLE PRECISION;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS destination_longitude DOUBLE PRECISION;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS destination_address TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS patient_name TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS pickup_address TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS urgency TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS negotiation JSONB;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS company_name TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS driver_name TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS driver_id TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS fare_amount DOUBLE PRECISION;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS final_fare DOUBLE PRECISION;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS phone TEXT;

-- IMPORTANT: Reload PostgREST schema cache after adding columns
NOTIFY pgrst, 'reload schema';
