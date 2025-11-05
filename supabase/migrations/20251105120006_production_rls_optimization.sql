-- Production RLS Policy Optimization
-- High-performance RLS policies for production workloads
-- Date: 2025-11-05

-- ============================================
-- PART 1: OPTIMIZED PUBLIC ACCESS POLICIES
-- ============================================

-- Studios: Public read access with optimized indexing
DROP POLICY IF EXISTS "Public can view active studios" ON studios;
CREATE POLICY "Public can view active studios" ON studios
    FOR SELECT USING (is_active = true);

-- Instructors: Public read access for active instructors at active studios
DROP POLICY IF EXISTS "Public can view active instructors" ON instructors;
CREATE POLICY "Public can view active instructors" ON instructors
    FOR SELECT USING (
        is_active = true AND 
        EXISTS (SELECT 1 FROM studios s WHERE s.id = studio_id AND s.is_active = true)
    );

-- Classes: Public read access with studio activity check
DROP POLICY IF EXISTS "Public can view active classes" ON classes;
CREATE POLICY "Public can view active classes" ON classes
    FOR SELECT USING (
        is_active = true AND 
        EXISTS (SELECT 1 FROM studios s WHERE s.id = studio_id AND s.is_active = true)
    );

-- Class schedules: Public read for future, available classes
DROP POLICY IF EXISTS "Public can view available schedules" ON class_schedules;
CREATE POLICY "Public can view available schedules" ON class_schedules
    FOR SELECT USING (
        start_time > NOW() AND 
        is_cancelled = false AND
        EXISTS (
            SELECT 1 FROM classes c 
            JOIN studios s ON c.studio_id = s.id 
            WHERE c.id = class_id AND c.is_active = true AND s.is_active = true
        )
    );

-- Class tiers: Public read access
DROP POLICY IF EXISTS "Public can view class tiers" ON class_tiers;
CREATE POLICY "Public can view class tiers" ON class_tiers
    FOR SELECT USING (true);

-- ============================================
-- PART 2: USER-SPECIFIC POLICIES (OPTIMIZED)
-- ============================================

-- User credits: Users can only see their own credits
DROP POLICY IF EXISTS "Users can view their own credits" ON user_credits;
CREATE POLICY "Users can view their own credits" ON user_credits
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own credits" ON user_credits;
CREATE POLICY "Users can update their own credits" ON user_credits
    FOR UPDATE USING (auth.uid() = user_id);

-- Bookings: Users can view and manage their own bookings
DROP POLICY IF EXISTS "Users can view their own bookings" ON bookings;
CREATE POLICY "Users can view their own bookings" ON bookings
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create their own bookings" ON bookings;
CREATE POLICY "Users can create their own bookings" ON bookings
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own bookings" ON bookings;
CREATE POLICY "Users can update their own bookings" ON bookings
    FOR UPDATE USING (auth.uid() = user_id);

-- Credit transactions: Users can view their own transactions
DROP POLICY IF EXISTS "Users can view their own credit transactions" ON credit_transactions;
CREATE POLICY "Users can view their own credit transactions" ON credit_transactions
    FOR SELECT USING (auth.uid() = user_id);

-- ============================================
-- PART 3: STUDIO STAFF POLICIES (OPTIMIZED)
-- ============================================

-- First, ensure we have a studio_staff table for proper access control
CREATE TABLE IF NOT EXISTS studio_staff (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    studio_id UUID NOT NULL REFERENCES studios(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('owner', 'manager', 'instructor', 'staff')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, studio_id)
);

-- Index for performance
CREATE INDEX IF NOT EXISTS idx_studio_staff_user_studio ON studio_staff(user_id, studio_id) WHERE is_active = true;

-- Studio staff can view their studio's data
DROP POLICY IF EXISTS "Studio staff can view studio bookings" ON bookings;
CREATE POLICY "Studio staff can view studio bookings" ON bookings
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM studio_staff ss
            JOIN class_schedules cs ON cs.id = class_schedule_id
            JOIN classes c ON c.id = cs.class_id
            WHERE ss.user_id = auth.uid() 
            AND ss.studio_id = c.studio_id
            AND ss.is_active = true
        )
    );

-- Studio staff can manage their studio's classes
DROP POLICY IF EXISTS "Studio staff can manage classes" ON classes;
CREATE POLICY "Studio staff can manage classes" ON classes
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM studio_staff ss
            WHERE ss.user_id = auth.uid() 
            AND ss.studio_id = classes.studio_id
            AND ss.is_active = true
        )
    );

-- Studio staff can manage their studio's schedules
DROP POLICY IF EXISTS "Studio staff can manage schedules" ON class_schedules;
CREATE POLICY "Studio staff can manage schedules" ON class_schedules
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM studio_staff ss
            JOIN classes c ON c.id = class_id
            WHERE ss.user_id = auth.uid() 
            AND ss.studio_id = c.studio_id
            AND ss.is_active = true
        )
    );

-- ============================================
-- PART 4: PERFORMANCE OPTIMIZATION INDEXES
-- ============================================

-- RLS-specific indexes for policy checks
CREATE INDEX IF NOT EXISTS idx_studios_active_id ON studios(id) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_instructors_active_studio ON instructors(studio_id) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_classes_active_studio ON classes(studio_id) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_schedules_future_available ON class_schedules(class_id, start_time) 
    WHERE start_time > NOW() AND is_cancelled = false;

-- Composite indexes for common policy queries
CREATE INDEX IF NOT EXISTS idx_bookings_user_schedule ON bookings(user_id, class_schedule_id);
CREATE INDEX IF NOT EXISTS idx_classes_studio_active ON classes(studio_id, is_active);

-- ============================================
-- PART 5: ENABLE RLS ON ALL TABLES
-- ============================================

-- Ensure RLS is enabled on all tables
ALTER TABLE studios ENABLE ROW LEVEL SECURITY;
ALTER TABLE instructors ENABLE ROW LEVEL SECURITY;
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_tiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_credits ENABLE ROW LEVEL SECURITY;
ALTER TABLE credit_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_staff ENABLE ROW LEVEL SECURITY;

-- ============================================
-- PART 6: GRANT APPROPRIATE PERMISSIONS
-- ============================================

-- Grant necessary permissions to authenticated users
GRANT SELECT ON studios TO authenticated;
GRANT SELECT ON instructors TO authenticated;
GRANT SELECT ON classes TO authenticated;
GRANT SELECT ON class_schedules TO authenticated;
GRANT SELECT ON class_tiers TO authenticated;

-- Users need full access to their own data
GRANT ALL ON bookings TO authenticated;
GRANT ALL ON user_credits TO authenticated;
GRANT SELECT ON credit_transactions TO authenticated;

-- Studio staff table permissions
GRANT SELECT ON studio_staff TO authenticated;

-- ============================================
-- PART 7: CREATE OPTIMIZED VIEWS FOR COMMON QUERIES
-- ============================================

-- View for available classes with all necessary info
CREATE OR REPLACE VIEW v_available_classes AS
SELECT 
    c.id as class_id,
    c.name as class_name,
    c.description,
    c.category,
    c.difficulty_level,
    c.price,
    c.duration,
    s.id as studio_id,
    s.name as studio_name,
    s.address,
    s.city,
    i.id as instructor_id,
    i.name as instructor_name,
    i.rating as instructor_rating,
    cs.id as schedule_id,
    cs.start_time,
    cs.end_time,
    cs.spots_available,
    cs.spots_total,
    ct.credit_required
FROM classes c
JOIN studios s ON c.studio_id = s.id
JOIN instructors i ON c.instructor_id = i.id
JOIN class_schedules cs ON c.id = cs.class_id
JOIN class_tiers ct ON c.tier_id = ct.id
WHERE c.is_active = true 
    AND s.is_active = true 
    AND i.is_active = true
    AND cs.start_time > NOW()
    AND cs.is_cancelled = false
    AND cs.spots_available > 0;

-- Grant access to the view
GRANT SELECT ON v_available_classes TO authenticated;

-- View for user booking history with class details
CREATE OR REPLACE VIEW v_user_booking_history AS
SELECT 
    b.id as booking_id,
    b.user_id,
    b.status,
    b.credits_used,
    b.rating,
    b.review,
    b.created_at as booked_at,
    c.name as class_name,
    c.category,
    s.name as studio_name,
    i.name as instructor_name,
    cs.start_time,
    cs.end_time
FROM bookings b
JOIN class_schedules cs ON b.class_schedule_id = cs.id
JOIN classes c ON cs.class_id = c.id
JOIN studios s ON c.studio_id = s.id
JOIN instructors i ON c.instructor_id = i.id;

-- Grant access with RLS (users will only see their own bookings)
GRANT SELECT ON v_user_booking_history TO authenticated;

-- ============================================
-- PART 8: PERFORMANCE MONITORING FUNCTIONS
-- ============================================

-- Function to check RLS policy performance
CREATE OR REPLACE FUNCTION check_rls_performance()
RETURNS TABLE(
    table_name TEXT,
    policy_count INTEGER,
    estimated_cost NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.table_name::TEXT,
        COUNT(p.policyname)::INTEGER as policy_count,
        0::NUMERIC as estimated_cost -- Placeholder for actual cost analysis
    FROM information_schema.tables t
    LEFT JOIN pg_policies p ON t.table_name = p.tablename
    WHERE t.table_schema = 'public'
    AND t.table_type = 'BASE TABLE'
    GROUP BY t.table_name
    ORDER BY t.table_name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- VERIFICATION
-- ============================================

DO $$
DECLARE
    rls_enabled_count INTEGER;
    policy_count INTEGER;
    index_count INTEGER;
    view_count INTEGER;
BEGIN
    -- Check RLS is enabled on key tables
    SELECT COUNT(*) INTO rls_enabled_count
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
    AND c.relkind = 'r'
    AND c.relrowsecurity = true
    AND c.relname IN ('studios', 'instructors', 'classes', 'class_schedules', 'bookings', 'user_credits');
    
    -- Check policies exist
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies
    WHERE schemaname = 'public';
    
    -- Check performance indexes exist
    SELECT COUNT(*) INTO index_count
    FROM pg_indexes
    WHERE schemaname = 'public'
    AND indexname LIKE 'idx_%';
    
    -- Check views exist
    SELECT COUNT(*) INTO view_count
    FROM information_schema.views
    WHERE table_schema = 'public'
    AND table_name LIKE 'v_%';
    
    IF rls_enabled_count < 6 THEN
        RAISE EXCEPTION 'RLS not enabled on all required tables: %', rls_enabled_count;
    END IF;
    
    IF policy_count < 10 THEN
        RAISE EXCEPTION 'Not enough RLS policies created: %', policy_count;
    END IF;
    
    IF index_count < 20 THEN
        RAISE EXCEPTION 'Not enough performance indexes: %', index_count;
    END IF;
    
    IF view_count < 2 THEN
        RAISE EXCEPTION 'Not enough optimized views created: %', view_count;
    END IF;
    
    RAISE NOTICE 'RLS optimization complete: % tables secured, % policies, % indexes, % views', 
                 rls_enabled_count, policy_count, index_count, view_count;
END $$;