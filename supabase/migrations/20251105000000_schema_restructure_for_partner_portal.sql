-- Migration: Schema Restructure for Partner Portal
-- Ensures tables exist and adds missing schemas to match TypeScript expectations
-- Date: 2024-11-05

-- ============================================
-- PART 1: VERIFY EXPECTED SCHEMA EXISTS
-- ============================================

-- First, drop dependent views and constraints
DROP VIEW IF EXISTS v_studio_imported_events_recent CASCADE;

-- Skip table renames - bookings and classes already exist with correct names
-- This migration is compatible with existing schema

-- ============================================
-- PART 2: ADD MISSING TABLES
-- ============================================

-- Create studio_staff table if it doesn't exist
CREATE TABLE IF NOT EXISTS studio_staff (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    studio_id UUID NOT NULL REFERENCES studios(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('owner', 'manager', 'instructor', 'staff')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, studio_id)
);

-- Create credit_transactions table if it doesn't exist
CREATE TABLE IF NOT EXISTS credit_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('purchase', 'use', 'refund', 'bonus', 'rollover', 'expire', 'insurance_claim')),
    amount DECIMAL(10,2) NOT NULL,
    credits_amount INTEGER,
    balance_after INTEGER NOT NULL,
    description TEXT,
    reference_id UUID, -- Can reference booking_id, purchase_id, etc.
    reference_type TEXT, -- 'booking', 'purchase', 'subscription', etc.
    stripe_payment_intent_id TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- PART 3: CREATE V_STUDIO_METRICS_DAILY VIEW
-- ============================================

-- Create the metrics view that dashboard expects
CREATE OR REPLACE VIEW v_studio_metrics_daily AS
SELECT 
    c.studio_id,
    DATE(b.created_at) as bucket_date,
    SUM(c.price) as revenue,
    COUNT(*) as booking_count,
    COUNT(DISTINCT cs.class_id) as unique_schedules,
    COUNT(DISTINCT c.instructor_id) as unique_instructors
FROM bookings b
JOIN class_schedules cs ON b.class_schedule_id = cs.id
JOIN classes c ON cs.class_id = c.id
WHERE b.status = 'confirmed'
GROUP BY c.studio_id, DATE(b.created_at);

-- ============================================
-- PART 4: RECREATE DEPENDENT VIEWS
-- ============================================

-- Recreate the studio imported events view using new table name
CREATE OR REPLACE VIEW v_studio_imported_events_recent AS
SELECT 
    id,
    studio_id,
    name as title,
    description,
    NULL as start_time,
    NULL as end_time,
    NULL as location,
    category,
    false as all_day,
    created_at,
    updated_at
FROM classes
WHERE created_at >= NOW() - INTERVAL '30 days'
ORDER BY created_at DESC;

-- ============================================
-- PART 5: UPDATE RLS POLICIES
-- ============================================

-- Update RLS policies to use new table names
-- For bookings (renamed from reservations)
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own bookings" ON bookings;
CREATE POLICY "Users can view their own bookings" ON bookings
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Studio staff can view studio bookings" ON bookings;
CREATE POLICY "Studio staff can view studio bookings" ON bookings
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM studio_staff ss
            JOIN class_schedules cs ON cs.id = bookings.class_schedule_id
            JOIN classes c ON c.id = cs.class_id
            WHERE ss.user_id = auth.uid() 
            AND ss.studio_id = c.studio_id
        )
    );

-- For classes (renamed from imported_events)
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Studio staff can manage classes" ON classes;
CREATE POLICY "Studio staff can manage classes" ON classes
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM studio_staff 
            WHERE user_id = auth.uid() 
            AND studio_id = classes.studio_id
        )
    );

DROP POLICY IF EXISTS "Public can view active classes" ON classes;
CREATE POLICY "Public can view active classes" ON classes
    FOR SELECT USING (true);

-- For credit_transactions
ALTER TABLE credit_transactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own credit transactions" ON credit_transactions;
CREATE POLICY "Users can view their own credit transactions" ON credit_transactions
    FOR SELECT USING (auth.uid() = user_id);

-- ============================================
-- PART 6: CREATE INDEXES FOR PERFORMANCE
-- ============================================

-- Indexes for bookings table
CREATE INDEX IF NOT EXISTS idx_bookings_user_id ON bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings(status);
CREATE INDEX IF NOT EXISTS idx_bookings_created_at ON bookings(created_at);

-- Indexes for classes table
CREATE INDEX IF NOT EXISTS idx_classes_studio_id ON classes(studio_id);
CREATE INDEX IF NOT EXISTS idx_classes_category ON classes(category);

-- Indexes for credit_transactions table
CREATE INDEX IF NOT EXISTS idx_credit_transactions_user_id ON credit_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_credit_transactions_type ON credit_transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_credit_transactions_created_at ON credit_transactions(created_at);

-- ============================================
-- PART 7: GRANTS AND PERMISSIONS
-- ============================================

-- Grant necessary permissions
GRANT ALL ON bookings TO authenticated;
GRANT ALL ON classes TO authenticated;
GRANT ALL ON credit_transactions TO authenticated;
GRANT SELECT ON v_studio_metrics_daily TO authenticated;
GRANT SELECT ON v_studio_imported_events_recent TO authenticated;

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Verify tables exist with correct names
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'bookings') THEN
        RAISE EXCEPTION 'bookings table was not created successfully';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'classes') THEN
        RAISE EXCEPTION 'classes table was not created successfully';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'credit_transactions') THEN
        RAISE EXCEPTION 'credit_transactions table was not created successfully';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'v_studio_metrics_daily') THEN
        RAISE EXCEPTION 'v_studio_metrics_daily view was not created successfully';
    END IF;
    
    RAISE NOTICE 'All schema changes completed successfully';
END $$;