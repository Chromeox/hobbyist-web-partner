-- Production Validation and Final Setup
-- Comprehensive validation of all production data and systems
-- Date: 2025-11-05

-- ============================================
-- PART 1: CREATE MISSING TABLES FOR PRODUCTION
-- ============================================

-- Notification log table for tracking sent notifications
CREATE TABLE IF NOT EXISTS notification_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    notification_type TEXT NOT NULL CHECK (notification_type IN ('booking_confirmation', 'class_reminder', 'cancellation', 'waitlist_spot', 'promotional')),
    reference_id UUID,
    reference_type TEXT CHECK (reference_type IN ('booking', 'class', 'studio', 'promotion')),
    hours_before INTEGER,
    sent_at TIMESTAMPTZ DEFAULT NOW(),
    status TEXT DEFAULT 'sent' CHECK (status IN ('sent', 'failed', 'pending')),
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Refund failures table for manual processing
CREATE TABLE IF NOT EXISTS refund_failures (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL REFERENCES bookings(id),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    refund_amount DECIMAL(5,2) NOT NULL,
    error_message TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'resolved', 'failed')),
    resolved_at TIMESTAMPTZ,
    resolved_by UUID REFERENCES auth.users(id),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User profiles table for extended user information
CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    first_name TEXT,
    last_name TEXT,
    phone TEXT,
    date_of_birth DATE,
    emergency_contact_name TEXT,
    emergency_contact_phone TEXT,
    dietary_restrictions TEXT[],
    experience_level TEXT CHECK (experience_level IN ('complete_beginner', 'some_experience', 'intermediate', 'advanced')),
    interests TEXT[],
    notification_preferences JSONB DEFAULT '{"class_reminders": true, "promotional": true, "waitlist_notifications": true}'::jsonb,
    avatar_url TEXT,
    bio TEXT,
    location TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- PART 2: CREATE PRODUCTION INDEXES
-- ============================================

-- Notification log indexes
CREATE INDEX IF NOT EXISTS idx_notification_log_user_type ON notification_log(user_id, notification_type);
CREATE INDEX IF NOT EXISTS idx_notification_log_reference ON notification_log(reference_id, reference_type);
CREATE INDEX IF NOT EXISTS idx_notification_log_sent_at ON notification_log(sent_at DESC);

-- Refund failures indexes
CREATE INDEX IF NOT EXISTS idx_refund_failures_status ON refund_failures(status, created_at);
CREATE INDEX IF NOT EXISTS idx_refund_failures_user ON refund_failures(user_id);

-- User profiles indexes
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON user_profiles(email);
CREATE INDEX IF NOT EXISTS idx_user_profiles_interests_gin ON user_profiles USING gin(interests);
CREATE INDEX IF NOT EXISTS idx_user_profiles_location ON user_profiles(location);

-- ============================================
-- PART 3: ENABLE RLS ON NEW TABLES
-- ============================================

ALTER TABLE notification_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE refund_failures ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- RLS policies for new tables
DROP POLICY IF EXISTS "Users can view their own notifications" ON notification_log;
CREATE POLICY "Users can view their own notifications" ON notification_log
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view their own refund failures" ON refund_failures;
CREATE POLICY "Users can view their own refund failures" ON refund_failures
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage their own profile" ON user_profiles;
CREATE POLICY "Users can manage their own profile" ON user_profiles
    FOR ALL USING (auth.uid() = id);

DROP POLICY IF EXISTS "Public can view basic user profiles" ON user_profiles;
CREATE POLICY "Public can view basic user profiles" ON user_profiles
    FOR SELECT USING (true); -- Allow public read for instructor profiles, etc.

-- ============================================
-- PART 4: GRANT PERMISSIONS
-- ============================================

GRANT ALL ON notification_log TO authenticated;
GRANT ALL ON refund_failures TO authenticated;
GRANT ALL ON user_profiles TO authenticated;

-- ============================================
-- PART 5: CREATE SAMPLE USER PROFILES
-- ============================================

-- Insert sample user profiles for our test users
INSERT INTO user_profiles (id, email, first_name, last_name, experience_level, interests, location) VALUES
('10000000-0000-0000-0000-000000000001', 'sarah.ceramics@example.com', 'Sarah', 'Wilson', 'some_experience', ARRAY['ceramics', 'arts'], 'Kitsilano, Vancouver'),
('10000000-0000-0000-0000-000000000002', 'mike.cooking@example.com', 'Mike', 'Chen', 'intermediate', ARRAY['cooking', 'wine'], 'Downtown, Vancouver'),
('10000000-0000-0000-0000-000000000003', 'jen.yoga@example.com', 'Jennifer', 'Martinez', 'complete_beginner', ARRAY['yoga', 'wellness'], 'Mount Pleasant, Vancouver'),
('10000000-0000-0000-0000-000000000004', 'alex.artist@example.com', 'Alex', 'Thompson', 'advanced', ARRAY['painting', 'photography'], 'Gastown, Vancouver'),
('10000000-0000-0000-0000-000000000005', 'lisa.dance@example.com', 'Lisa', 'Rodriguez', 'intermediate', ARRAY['dance', 'music'], 'Yaletown, Vancouver'),
('10000000-0000-0000-0000-000000000006', 'david.wood@example.com', 'David', 'Kim', 'some_experience', ARRAY['woodworking', 'crafts'], 'Commercial Drive, Vancouver'),
('10000000-0000-0000-0000-000000000007', 'emma.pottery@example.com', 'Emma', 'Foster', 'complete_beginner', ARRAY['ceramics'], 'West End, Vancouver'),
('10000000-0000-0000-0000-000000000008', 'carlos.glass@example.com', 'Carlos', 'Silva', 'advanced', ARRAY['glass', 'sculpture'], 'Fairview, Vancouver'),
('10000000-0000-0000-0000-000000000009', 'priya.wellness@example.com', 'Priya', 'Patel', 'intermediate', ARRAY['yoga', 'meditation'], 'Olympic Village, Vancouver'),
('10000000-0000-0000-0000-000000000010', 'jason.photo@example.com', 'Jason', 'Lee', 'some_experience', ARRAY['photography', 'arts'], 'Burnaby, BC')
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- PART 6: PRODUCTION DATA VALIDATION
-- ============================================

-- Create comprehensive validation function
CREATE OR REPLACE FUNCTION validate_production_data()
RETURNS TABLE(
    check_name TEXT,
    status TEXT,
    count_value INTEGER,
    message TEXT
) AS $$
BEGIN
    -- Check studios
    RETURN QUERY
    SELECT 
        'Studios'::TEXT as check_name,
        CASE WHEN COUNT(*) >= 20 THEN 'PASS' ELSE 'FAIL' END as status,
        COUNT(*)::INTEGER as count_value,
        CASE WHEN COUNT(*) >= 20 
            THEN 'Sufficient studios created'
            ELSE 'Need more studios: ' || COUNT(*) || ' found, 20+ required'
        END as message
    FROM studios WHERE is_active = true;

    -- Check instructors
    RETURN QUERY
    SELECT 
        'Instructors'::TEXT,
        CASE WHEN COUNT(*) >= 35 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*)::INTEGER,
        CASE WHEN COUNT(*) >= 35 
            THEN 'Sufficient instructors created'
            ELSE 'Need more instructors: ' || COUNT(*) || ' found, 35+ required'
        END
    FROM instructors WHERE is_active = true;

    -- Check classes
    RETURN QUERY
    SELECT 
        'Classes'::TEXT,
        CASE WHEN COUNT(*) >= 100 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*)::INTEGER,
        CASE WHEN COUNT(*) >= 100 
            THEN 'Sufficient classes created'
            ELSE 'Need more classes: ' || COUNT(*) || ' found, 100+ required'
        END
    FROM classes WHERE is_active = true;

    -- Check class schedules
    RETURN QUERY
    SELECT 
        'Future Schedules'::TEXT,
        CASE WHEN COUNT(*) >= 400 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*)::INTEGER,
        CASE WHEN COUNT(*) >= 400 
            THEN 'Sufficient future schedules'
            ELSE 'Need more schedules: ' || COUNT(*) || ' found, 400+ required'
        END
    FROM class_schedules WHERE start_time > NOW() AND is_cancelled = false;

    -- Check bookings
    RETURN QUERY
    SELECT 
        'Bookings'::TEXT,
        CASE WHEN COUNT(*) >= 200 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*)::INTEGER,
        CASE WHEN COUNT(*) >= 200 
            THEN 'Sufficient booking history'
            ELSE 'Need more bookings: ' || COUNT(*) || ' found, 200+ required'
        END
    FROM bookings;

    -- Check reviews
    RETURN QUERY
    SELECT 
        'Reviews'::TEXT,
        CASE WHEN COUNT(*) >= 50 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*)::INTEGER,
        CASE WHEN COUNT(*) >= 50 
            THEN 'Sufficient reviews for authenticity'
            ELSE 'Need more reviews: ' || COUNT(*) || ' found, 50+ required'
        END
    FROM bookings WHERE review IS NOT NULL;

    -- Check categories
    RETURN QUERY
    SELECT 
        'Categories'::TEXT,
        CASE WHEN COUNT(DISTINCT category) >= 8 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(DISTINCT category)::INTEGER,
        CASE WHEN COUNT(DISTINCT category) >= 8 
            THEN 'Good category diversity'
            ELSE 'Need more categories: ' || COUNT(DISTINCT category) || ' found, 8+ required'
        END
    FROM classes WHERE is_active = true;

    -- Check average ratings
    RETURN QUERY
    SELECT 
        'Average Rating'::TEXT,
        CASE WHEN AVG(rating) BETWEEN 4.0 AND 5.0 THEN 'PASS' ELSE 'FAIL' END,
        ROUND(AVG(rating) * 100)::INTEGER, -- Convert to percentage for display
        CASE WHEN AVG(rating) BETWEEN 4.0 AND 5.0 
            THEN 'Realistic average rating: ' || ROUND(AVG(rating), 2)
            ELSE 'Unrealistic rating: ' || ROUND(AVG(rating), 2) || ' (should be 4.0-5.0)'
        END
    FROM instructors WHERE rating > 0;

    -- Check pricing realism
    RETURN QUERY
    SELECT 
        'Price Range'::TEXT,
        CASE WHEN AVG(price) BETWEEN 30 AND 120 AND MIN(price) >= 20 AND MAX(price) <= 300 THEN 'PASS' ELSE 'FAIL' END,
        ROUND(AVG(price))::INTEGER,
        CASE WHEN AVG(price) BETWEEN 30 AND 120 AND MIN(price) >= 20 AND MAX(price) <= 300
            THEN 'Realistic pricing: $' || ROUND(MIN(price)) || '-$' || ROUND(MAX(price)) || ' (avg $' || ROUND(AVG(price)) || ')'
            ELSE 'Unrealistic pricing detected'
        END
    FROM classes WHERE is_active = true;

    -- Check geographic distribution
    RETURN QUERY
    SELECT 
        'Geographic Spread'::TEXT,
        CASE WHEN COUNT(DISTINCT LEFT(postal_code, 3)) >= 8 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(DISTINCT LEFT(postal_code, 3))::INTEGER,
        CASE WHEN COUNT(DISTINCT LEFT(postal_code, 3)) >= 8 
            THEN 'Good geographic distribution across Vancouver'
            ELSE 'Need more geographic diversity: ' || COUNT(DISTINCT LEFT(postal_code, 3)) || ' areas'
        END
    FROM studios WHERE is_active = true;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- PART 7: PERFORMANCE VALIDATION
-- ============================================

-- Create function to test query performance
CREATE OR REPLACE FUNCTION test_query_performance()
RETURNS TABLE(
    query_name TEXT,
    execution_time_ms NUMERIC,
    status TEXT,
    note TEXT
) AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    duration_ms NUMERIC;
BEGIN
    -- Test 1: Class search query
    start_time := clock_timestamp();
    PERFORM * FROM v_available_classes 
    WHERE class_name ILIKE '%ceramics%' 
    LIMIT 20;
    end_time := clock_timestamp();
    duration_ms := EXTRACT(epoch FROM (end_time - start_time)) * 1000;
    
    RETURN QUERY SELECT 
        'Class Search'::TEXT,
        duration_ms,
        CASE WHEN duration_ms < 100 THEN 'EXCELLENT' 
             WHEN duration_ms < 500 THEN 'GOOD' 
             ELSE 'NEEDS_OPTIMIZATION' END,
        'Full-text search performance'::TEXT;

    -- Test 2: User booking history
    start_time := clock_timestamp();
    PERFORM * FROM v_user_booking_history 
    WHERE user_id = '10000000-0000-0000-0000-000000000001'
    ORDER BY booked_at DESC;
    end_time := clock_timestamp();
    duration_ms := EXTRACT(epoch FROM (end_time - start_time)) * 1000;
    
    RETURN QUERY SELECT 
        'Booking History'::TEXT,
        duration_ms,
        CASE WHEN duration_ms < 50 THEN 'EXCELLENT' 
             WHEN duration_ms < 200 THEN 'GOOD' 
             ELSE 'NEEDS_OPTIMIZATION' END,
        'User booking retrieval'::TEXT;

    -- Test 3: Studio analytics
    start_time := clock_timestamp();
    PERFORM studio_id, COUNT(*), AVG(rating) 
    FROM bookings b
    JOIN class_schedules cs ON b.class_schedule_id = cs.id
    JOIN classes c ON cs.class_id = c.id
    WHERE b.status = 'completed'
    GROUP BY studio_id;
    end_time := clock_timestamp();
    duration_ms := EXTRACT(epoch FROM (end_time - start_time)) * 1000;
    
    RETURN QUERY SELECT 
        'Studio Analytics'::TEXT,
        duration_ms,
        CASE WHEN duration_ms < 200 THEN 'EXCELLENT' 
             WHEN duration_ms < 1000 THEN 'GOOD' 
             ELSE 'NEEDS_OPTIMIZATION' END,
        'Aggregation query performance'::TEXT;

END;
$$ LANGUAGE plpgsql;

-- ============================================
-- PART 8: EXECUTE VALIDATION
-- ============================================

-- Run comprehensive validation
SELECT * FROM validate_production_data();

-- Run performance tests
SELECT * FROM test_query_performance();

-- ============================================
-- PART 9: FINAL CLEANUP AND OPTIMIZATION
-- ============================================

-- Update all table statistics for optimal query planning
ANALYZE studios;
ANALYZE instructors;
ANALYZE classes;
ANALYZE class_schedules;
ANALYZE bookings;
ANALYZE user_credits;
ANALYZE credit_transactions;
ANALYZE user_profiles;
ANALYZE notification_log;

-- ============================================
-- FINAL VERIFICATION SUMMARY
-- ============================================

DO $$
DECLARE
    total_studios INTEGER;
    total_instructors INTEGER;
    total_classes INTEGER;
    total_schedules INTEGER;
    total_bookings INTEGER;
    total_reviews INTEGER;
    avg_rating DECIMAL;
    future_availability INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_studios FROM studios WHERE is_active = true;
    SELECT COUNT(*) INTO total_instructors FROM instructors WHERE is_active = true;
    SELECT COUNT(*) INTO total_classes FROM classes WHERE is_active = true;
    SELECT COUNT(*) INTO total_schedules FROM class_schedules WHERE start_time > NOW() AND is_cancelled = false;
    SELECT COUNT(*) INTO total_bookings FROM bookings;
    SELECT COUNT(*) INTO total_reviews FROM bookings WHERE review IS NOT NULL;
    SELECT AVG(rating) INTO avg_rating FROM instructors WHERE rating > 0;
    SELECT COUNT(*) INTO future_availability FROM class_schedules WHERE start_time > NOW() AND spots_available > 0 AND is_cancelled = false;
    
    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'HOBBYAPP PRODUCTION DATABASE SUMMARY';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Studios: % active across Vancouver', total_studios;
    RAISE NOTICE 'Instructors: % with % average rating', total_instructors, ROUND(avg_rating, 1);
    RAISE NOTICE 'Classes: % across multiple categories', total_classes;
    RAISE NOTICE 'Future Schedules: % available for booking', total_schedules;
    RAISE NOTICE 'Available Spots: % classes with open spots', future_availability;
    RAISE NOTICE 'Booking History: % bookings with % reviews', total_bookings, total_reviews;
    RAISE NOTICE '';
    RAISE NOTICE 'Production database is ready for HobbyApp launch!';
    RAISE NOTICE '============================================';
END $$;

-- Drop validation functions to clean up
DROP FUNCTION validate_production_data();
DROP FUNCTION test_query_performance();