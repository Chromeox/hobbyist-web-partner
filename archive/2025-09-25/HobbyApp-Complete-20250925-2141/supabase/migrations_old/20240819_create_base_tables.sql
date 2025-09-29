-- Create Base Tables (if they don't exist)
-- This migration ensures all prerequisite tables exist

-- User Credits Table
CREATE TABLE IF NOT EXISTS user_credits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    total_credits INTEGER DEFAULT 0,
    used_credits INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_user_credits UNIQUE (user_id)
);

-- Studios Table
CREATE TABLE IF NOT EXISTS studios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    address TEXT,
    city TEXT DEFAULT 'Vancouver',
    commission_rate DECIMAL(5,2) DEFAULT 30.00, -- Platform takes 30%
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Instructors Table
CREATE TABLE IF NOT EXISTS instructors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    studio_id UUID REFERENCES studios(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT,
    bio TEXT,
    specialties TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Classes Table
CREATE TABLE IF NOT EXISTS classes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    studio_id UUID REFERENCES studios(id) ON DELETE CASCADE,
    instructor_id UUID REFERENCES instructors(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    description TEXT,
    category TEXT,
    difficulty_level TEXT CHECK (difficulty_level IN ('beginner', 'intermediate', 'advanced', 'all_levels')),
    price DECIMAL(10,2),
    duration INTEGER, -- in minutes
    max_participants INTEGER DEFAULT 20,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Class Schedules Table
CREATE TABLE IF NOT EXISTS class_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_id UUID REFERENCES classes(id) ON DELETE CASCADE,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    spots_available INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Bookings Table
CREATE TABLE IF NOT EXISTS bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    class_schedule_id UUID REFERENCES class_schedules(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'confirmed' CHECK (status IN ('confirmed', 'cancelled', 'completed', 'no_show')),
    credits_used INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Credit Transactions Table
CREATE TABLE IF NOT EXISTS credit_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('purchase', 'use', 'refund', 'bonus', 'rollover')),
    amount INTEGER NOT NULL,
    balance_after INTEGER NOT NULL,
    description TEXT,
    reference_id UUID, -- Can reference booking_id, purchase_id, etc.
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on all tables
ALTER TABLE user_credits ENABLE ROW LEVEL SECURITY;
ALTER TABLE studios ENABLE ROW LEVEL SECURITY;
ALTER TABLE instructors ENABLE ROW LEVEL SECURITY;
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE credit_transactions ENABLE ROW LEVEL SECURITY;

-- Create basic RLS policies (with existence checks)
DO $$ 
BEGIN
    -- Policy for user_credits
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'user_credits' 
        AND policyname = 'Users can view own credits'
    ) THEN
        CREATE POLICY "Users can view own credits" 
            ON user_credits FOR ALL 
            USING (auth.uid() = user_id);
    END IF;

    -- Policy for studios
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'studios' 
        AND policyname = 'Public can view studios'
    ) THEN
        CREATE POLICY "Public can view studios" 
            ON studios FOR SELECT 
            USING (true);
    END IF;

    -- Policy for instructors
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'instructors' 
        AND policyname = 'Public can view instructors'
    ) THEN
        CREATE POLICY "Public can view instructors" 
            ON instructors FOR SELECT 
            USING (true);
    END IF;

    -- Policy for classes
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'classes' 
        AND policyname = 'Public can view classes'
    ) THEN
        CREATE POLICY "Public can view classes" 
            ON classes FOR SELECT 
            USING (true);
    END IF;

    -- Policy for class_schedules
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'class_schedules' 
        AND policyname = 'Public can view schedules'
    ) THEN
        CREATE POLICY "Public can view schedules" 
            ON class_schedules FOR SELECT 
            USING (true);
    END IF;

    -- Policy for bookings
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'bookings' 
        AND policyname = 'Users can view own bookings'
    ) THEN
        CREATE POLICY "Users can view own bookings" 
            ON bookings FOR ALL 
            USING (auth.uid() = user_id);
    END IF;

    -- Policy for credit_transactions
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'credit_transactions' 
        AND policyname = 'Users can view own transactions'
    ) THEN
        CREATE POLICY "Users can view own transactions" 
            ON credit_transactions FOR SELECT 
            USING (auth.uid() = user_id);
    END IF;
END $$;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_credits_user_id ON user_credits(user_id);
CREATE INDEX IF NOT EXISTS idx_classes_studio_id ON classes(studio_id);
CREATE INDEX IF NOT EXISTS idx_class_schedules_class_id ON class_schedules(class_id);
CREATE INDEX IF NOT EXISTS idx_class_schedules_start_time ON class_schedules(start_time);
CREATE INDEX IF NOT EXISTS idx_bookings_user_id ON bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_schedule_id ON bookings(class_schedule_id);
CREATE INDEX IF NOT EXISTS idx_credit_transactions_user_id ON credit_transactions(user_id);

COMMENT ON TABLE user_credits IS 'Tracks user credit balances';
COMMENT ON TABLE studios IS 'Partner studios offering classes';
COMMENT ON TABLE classes IS 'Class definitions and details';
COMMENT ON TABLE class_schedules IS 'Scheduled class sessions';
COMMENT ON TABLE bookings IS 'User bookings for classes';
COMMENT ON TABLE credit_transactions IS 'Credit transaction history';
