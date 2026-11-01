-- ==============================================================================
-- NEXORA E-COMMERCE & LOGISTICS ECOSYSTEM
-- Fully Idempotent Supabase Database Schema & Migration
-- Supports both fresh databases and pre-existing tables.
-- ==============================================================================

-- 1. Enable Required Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==============================================================================
-- 2. User Profiles Table (Linked to Supabase auth.users)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Safely add columns if profiles table already existed
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS first_name TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS last_name TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS full_name TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS mobile_number TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS date_of_birth DATE;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS role TEXT NOT NULL DEFAULT 'buyer';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS account_status TEXT NOT NULL DEFAULT 'Active';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS wallet_balance NUMERIC(12, 2) NOT NULL DEFAULT 0.00;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS voucher_count INT NOT NULL DEFAULT 1;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS referral_code TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS referred_by TEXT;

CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);

-- ==============================================================================
-- 3. Automatic Trigger for New User Registrations (Email & Google OAuth)
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    v_full_name TEXT;
    v_first_name TEXT;
    v_last_name TEXT;
    v_avatar_url TEXT;
BEGIN
    v_full_name := COALESCE(
        new.raw_user_meta_data->>'full_name',
        new.raw_user_meta_data->>'name',
        ''
    );

    v_first_name := COALESCE(
        new.raw_user_meta_data->>'first_name',
        new.raw_user_meta_data->>'given_name',
        split_part(v_full_name, ' ', 1),
        ''
    );

    v_last_name := COALESCE(
        new.raw_user_meta_data->>'last_name',
        new.raw_user_meta_data->>'family_name',
        substring(v_full_name from position(' ' in v_full_name) + 1),
        ''
    );

    v_avatar_url := COALESCE(
        new.raw_user_meta_data->>'avatar_url',
        new.raw_user_meta_data->>'picture',
        ''
    );

    INSERT INTO public.profiles (
        id,
        first_name,
        last_name,
        full_name,
        email,
        mobile_number,
        avatar_url,
        account_status,
        role,
        wallet_balance,
        voucher_count
    ) VALUES (
        new.id,
        NULLIF(v_first_name, ''),
        NULLIF(v_last_name, ''),
        COALESCE(NULLIF(v_full_name, ''), NULLIF(concat_ws(' ', v_first_name, v_last_name), ''), split_part(new.email, '@', 1)),
        new.email,
        new.raw_user_meta_data->>'mobile_number',
        NULLIF(v_avatar_url, ''),
        'Active',
        COALESCE(new.raw_user_meta_data->>'role', 'buyer'),
        0.00,
        1
    )
    ON CONFLICT (id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        avatar_url = COALESCE(EXCLUDED.avatar_url, profiles.avatar_url),
        updated_at = timezone('utc'::text, now());

    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ==============================================================================
-- 4. Customer Delivery Addresses Table
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.addresses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.addresses ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE public.addresses ADD COLUMN IF NOT EXISTS recipient_name TEXT;
ALTER TABLE public.addresses ADD COLUMN IF NOT EXISTS phone_number TEXT;
ALTER TABLE public.addresses ADD COLUMN IF NOT EXISTS street_address TEXT;
ALTER TABLE public.addresses ADD COLUMN IF NOT EXISTS barangay TEXT;
ALTER TABLE public.addresses ADD COLUMN IF NOT EXISTS city TEXT;
ALTER TABLE public.addresses ADD COLUMN IF NOT EXISTS province TEXT DEFAULT 'Laguna';
ALTER TABLE public.addresses ADD COLUMN IF NOT EXISTS postal_code TEXT;
ALTER TABLE public.addresses ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION;
ALTER TABLE public.addresses ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;
ALTER TABLE public.addresses ADD COLUMN IF NOT EXISTS label TEXT DEFAULT 'Home';
ALTER TABLE public.addresses ADD COLUMN IF NOT EXISTS is_default BOOLEAN DEFAULT false;

CREATE INDEX IF NOT EXISTS idx_addresses_user_id ON public.addresses(user_id);

-- ==============================================================================
-- 5. Orders Table (Synchronized between Buyer and Rider Apps)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.orders (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id TEXT UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Safely add all required columns if table already existed without them
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS order_id TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS buyer_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS buyer_name TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS buyer_phone TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS buyer_email TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS shipping_address TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_lat DOUBLE PRECISION;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_lng DOUBLE PRECISION;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'pending';
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS payment_method TEXT DEFAULT 'Cash on Delivery';
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS total_price NUMERIC(10, 2) DEFAULT 0.00;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS subtotal NUMERIC(10, 2) DEFAULT 0.00;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS shipping_fee NUMERIC(10, 2) DEFAULT 0.00;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS discount NUMERIC(10, 2) DEFAULT 0.00;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS items JSONB DEFAULT '[]'::jsonb;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS courier_id TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS courier_name TEXT DEFAULT 'Pedro Jose Garcia';
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS courier_rating NUMERIC(3, 2) DEFAULT 4.98;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS courier_avatar_url TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS courier_phone TEXT DEFAULT '+63 918 555 0192';
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS courier_plate_number TEXT DEFAULT '123ABC';
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS is_rider_accepted BOOLEAN DEFAULT false;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS is_rated BOOLEAN DEFAULT false;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS proof_of_delivery_photo_url TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_completed_at TIMESTAMPTZ;

-- Indexes on orders
CREATE INDEX IF NOT EXISTS idx_orders_order_id ON public.orders(order_id);
CREATE INDEX IF NOT EXISTS idx_orders_buyer_id ON public.orders(buyer_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_courier_id ON public.orders(courier_id);

-- ==============================================================================
-- 6. Courier & Rider Fleet Profiles Table
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.rider_profiles (
    id TEXT PRIMARY KEY,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.rider_profiles ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.rider_profiles ADD COLUMN IF NOT EXISTS name TEXT;
ALTER TABLE public.rider_profiles ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE public.rider_profiles ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE public.rider_profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE public.rider_profiles ADD COLUMN IF NOT EXISTS rating NUMERIC(3, 2) DEFAULT 5.00;
ALTER TABLE public.rider_profiles ADD COLUMN IF NOT EXISTS total_deliveries INT DEFAULT 0;
ALTER TABLE public.rider_profiles ADD COLUMN IF NOT EXISTS completion_rate NUMERIC(5, 2) DEFAULT 100.00;
ALTER TABLE public.rider_profiles ADD COLUMN IF NOT EXISTS tier TEXT DEFAULT 'Tier 1 Rider';
ALTER TABLE public.rider_profiles ADD COLUMN IF NOT EXISTS vehicle_type TEXT DEFAULT 'Motorcycle';
ALTER TABLE public.rider_profiles ADD COLUMN IF NOT EXISTS vehicle_model TEXT DEFAULT 'Honda Click 150i';
ALTER TABLE public.rider_profiles ADD COLUMN IF NOT EXISTS plate_number TEXT;
ALTER TABLE public.rider_profiles ADD COLUMN IF NOT EXISTS assigned_hub TEXT DEFAULT 'Pasig Central Sorting Hub';
ALTER TABLE public.rider_profiles ADD COLUMN IF NOT EXISTS account_status TEXT DEFAULT 'Active';
ALTER TABLE public.rider_profiles ADD COLUMN IF NOT EXISTS wallet_balance NUMERIC(12, 2) DEFAULT 0.00;
ALTER TABLE public.rider_profiles ADD COLUMN IF NOT EXISTS today_earnings NUMERIC(10, 2) DEFAULT 0.00;
ALTER TABLE public.rider_profiles ADD COLUMN IF NOT EXISTS is_online BOOLEAN DEFAULT false;
ALTER TABLE public.rider_profiles ADD COLUMN IF NOT EXISTS current_lat DOUBLE PRECISION;
ALTER TABLE public.rider_profiles ADD COLUMN IF NOT EXISTS current_lng DOUBLE PRECISION;

-- Seed Default Courier Rider
INSERT INTO public.rider_profiles (
    id, name, phone, email, rating, total_deliveries, completion_rate,
    tier, vehicle_type, vehicle_model, plate_number, is_online
) VALUES (
    'NX-RD-001',
    'Pedro Jose Garcia',
    '+63 918 555 0192',
    'pedro.garcia@bilishatid.ph',
    4.98,
    1248,
    99.4,
    'Tier 1 Rider',
    'Motorcycle',
    'Honda Click 150i',
    '123ABC',
    true
) ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    phone = EXCLUDED.phone;

-- ==============================================================================
-- 7. Rider Reviews Table
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.rider_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.rider_reviews ADD COLUMN IF NOT EXISTS order_id TEXT;
ALTER TABLE public.rider_reviews ADD COLUMN IF NOT EXISTS rider_id TEXT;
ALTER TABLE public.rider_reviews ADD COLUMN IF NOT EXISTS buyer_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE public.rider_reviews ADD COLUMN IF NOT EXISTS customer_name TEXT;
ALTER TABLE public.rider_reviews ADD COLUMN IF NOT EXISTS driver_rating INT DEFAULT 5;
ALTER TABLE public.rider_reviews ADD COLUMN IF NOT EXISTS delivery_rating INT DEFAULT 5;
ALTER TABLE public.rider_reviews ADD COLUMN IF NOT EXISTS comment TEXT;
ALTER TABLE public.rider_reviews ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}';

CREATE INDEX IF NOT EXISTS idx_rider_reviews_rider_id ON public.rider_reviews(rider_id);
CREATE INDEX IF NOT EXISTS idx_rider_reviews_order_id ON public.rider_reviews(order_id);

-- ==============================================================================
-- 8. Real-Time Chat Messages Table
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.chat_messages (
    id TEXT PRIMARY KEY,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.chat_messages ADD COLUMN IF NOT EXISTS order_id TEXT;
ALTER TABLE public.chat_messages ADD COLUMN IF NOT EXISTS sender TEXT;
ALTER TABLE public.chat_messages ADD COLUMN IF NOT EXISTS sender_name TEXT;
ALTER TABLE public.chat_messages ADD COLUMN IF NOT EXISTS text TEXT;
ALTER TABLE public.chat_messages ADD COLUMN IF NOT EXISTS attachment_url TEXT;
ALTER TABLE public.chat_messages ADD COLUMN IF NOT EXISTS attachment_type TEXT;
ALTER TABLE public.chat_messages ADD COLUMN IF NOT EXISTS is_edited BOOLEAN DEFAULT false;
ALTER TABLE public.chat_messages ADD COLUMN IF NOT EXISTS is_unsent BOOLEAN DEFAULT false;

CREATE INDEX IF NOT EXISTS idx_chat_messages_order_id ON public.chat_messages(order_id);

-- ==============================================================================
-- 9. Row Level Security (RLS) & Policies (Safe Drop & Recreate)
-- ==============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rider_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rider_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

-- Profiles
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;
CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
CREATE POLICY "Users can insert their own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- Addresses
DROP POLICY IF EXISTS "Users can view own addresses" ON public.addresses;
CREATE POLICY "Users can view own addresses" ON public.addresses FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own addresses" ON public.addresses;
CREATE POLICY "Users can insert own addresses" ON public.addresses FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own addresses" ON public.addresses;
CREATE POLICY "Users can update own addresses" ON public.addresses FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own addresses" ON public.addresses;
CREATE POLICY "Users can delete own addresses" ON public.addresses FOR DELETE USING (auth.uid() = user_id);

-- Orders
DROP POLICY IF EXISTS "Orders select policy" ON public.orders;
CREATE POLICY "Orders select policy" ON public.orders FOR SELECT USING (true);

DROP POLICY IF EXISTS "Orders insert policy" ON public.orders;
CREATE POLICY "Orders insert policy" ON public.orders FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Orders update policy" ON public.orders;
CREATE POLICY "Orders update policy" ON public.orders FOR UPDATE USING (true);

-- Rider Profiles
DROP POLICY IF EXISTS "Rider profiles viewable by all" ON public.rider_profiles;
CREATE POLICY "Rider profiles viewable by all" ON public.rider_profiles FOR SELECT USING (true);

DROP POLICY IF EXISTS "Rider profiles update policy" ON public.rider_profiles;
CREATE POLICY "Rider profiles update policy" ON public.rider_profiles FOR UPDATE USING (true);

-- Rider Reviews
DROP POLICY IF EXISTS "Rider reviews viewable by all" ON public.rider_reviews;
CREATE POLICY "Rider reviews viewable by all" ON public.rider_reviews FOR SELECT USING (true);

DROP POLICY IF EXISTS "Rider reviews insert policy" ON public.rider_reviews;
CREATE POLICY "Rider reviews insert policy" ON public.rider_reviews FOR INSERT WITH CHECK (true);

-- Chat Messages
DROP POLICY IF EXISTS "Chat messages select policy" ON public.chat_messages;
CREATE POLICY "Chat messages select policy" ON public.chat_messages FOR SELECT USING (true);

DROP POLICY IF EXISTS "Chat messages insert policy" ON public.chat_messages;
CREATE POLICY "Chat messages insert policy" ON public.chat_messages FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Chat messages update policy" ON public.chat_messages;
CREATE POLICY "Chat messages update policy" ON public.chat_messages FOR UPDATE USING (true);

-- ==============================================================================
-- 10. Enable Supabase Realtime Replication
-- ==============================================================================
DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.rider_profiles;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;
