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
  is_approved BOOLEAN DEFAULT true,
  is_online BOOLEAN DEFAULT false,
  company_name TEXT,
  fcm_token TEXT,
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
  is_online BOOLEAN DEFAULT false,
  is_approved BOOLEAN DEFAULT true,
  is_active BOOLEAN DEFAULT true,
  data_ref TEXT,
  fcm_token TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  current_address TEXT,
  heading DOUBLE PRECISION,
  last_location_update TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

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
  rating DOUBLE PRECISION,
  review TEXT,
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
ALTER PUBLICATION supabase_realtime ADD TABLE orders;
ALTER PUBLICATION supabase_realtime ADD TABLE partners;
ALTER PUBLICATION supabase_realtime ADD TABLE ride_requests;
ALTER PUBLICATION supabase_realtime ADD TABLE user_notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE partner_notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE admin_alerts;

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
ALTER TABLE admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE glm_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE pending_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE partner_notifications ENABLE ROW LEVEL SECURITY;

-- Allow all access with anon key (you can restrict later for production)
CREATE POLICY "Allow all access" ON users FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all access" ON drivers FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all access" ON partners FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all access" ON orders FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all access" ON ride_requests FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all access" ON order_reviews FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all access" ON admins FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all access" ON glm_accounts FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all access" ON notification_logs FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all access" ON pending_notifications FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all access" ON admin_notifications FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all access" ON admin_alerts FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all access" ON user_notifications FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all access" ON partner_notifications FOR ALL USING (true) WITH CHECK (true);
