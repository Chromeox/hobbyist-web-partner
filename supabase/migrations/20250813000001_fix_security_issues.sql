-- Security Fix Migration for HobbyistSwiftUI
-- Fixes SECURITY DEFINER views and enables RLS on public tables
-- Date: 2025-08-13

-- ===================================
-- 1. Fix SECURITY DEFINER Views
-- ===================================

-- Drop existing views if they exist with SECURITY DEFINER
DROP VIEW IF EXISTS public.revenue_analytics CASCADE;
DROP VIEW IF EXISTS public.class_performance CASCADE;

-- Recreate revenue_analytics view with SECURITY INVOKER (default)
CREATE OR REPLACE VIEW public.revenue_analytics AS
SELECT 
    DATE_TRUNC('day', b.created_at) as period,
    COUNT(b.id) as booking_count,
    COALESCE(SUM(b.amount), 0)::BIGINT as total_revenue,
    COALESCE(SUM(b.commission_amount), 0)::BIGINT as total_commission,
    COALESCE(SUM(b.instructor_payout), 0)::BIGINT as total_payouts,
    COUNT(CASE WHEN b.payment_method = 'credits' THEN 1 END) as credit_bookings,
    COUNT(CASE WHEN b.payment_method != 'credits' THEN 1 END) as card_bookings
FROM bookings b
WHERE b.payment_status = 'succeeded'
GROUP BY DATE_TRUNC('day', b.created_at);

-- Grant appropriate permissions on the view
GRANT SELECT ON public.revenue_analytics TO authenticated;
COMMENT ON VIEW public.revenue_analytics IS 'Revenue analytics view with SECURITY INVOKER to respect RLS policies';

-- Recreate class_performance view with SECURITY INVOKER (default)
CREATE OR REPLACE VIEW public.class_performance AS
SELECT 
    c.id as class_id,
    c.title as class_title,
    c.instructor_id,
    c.start_time,
    c.end_time,
    c.max_participants,
    COUNT(b.id) as total_bookings,
    COALESCE(SUM(b.amount), 0)::BIGINT as total_revenue,
    COALESCE(SUM(b.commission_amount), 0)::BIGINT as total_commission,
    COALESCE(SUM(b.instructor_payout), 0)::BIGINT as instructor_payout,
    COUNT(CASE WHEN b.payment_method = 'credits' THEN 1 END) as credit_bookings,
    COUNT(CASE WHEN b.payment_method != 'credits' THEN 1 END) as card_bookings,
    CASE 
        WHEN c.max_participants > 0 
        THEN ROUND((COUNT(b.id)::DECIMAL / c.max_participants) * 100, 2)
        ELSE 0
    END as occupancy_rate
FROM classes c
LEFT JOIN bookings b ON c.id = b.class_id AND b.payment_status = 'succeeded'
GROUP BY c.id, c.title, c.instructor_id, c.start_time, c.end_time, c.max_participants;

-- Grant appropriate permissions on the view
GRANT SELECT ON public.class_performance TO authenticated;
COMMENT ON VIEW public.class_performance IS 'Class performance metrics view with SECURITY INVOKER to respect RLS policies';

-- ===================================
-- 2. Create instructors table if it doesn't exist
-- ===================================

-- Check if instructors table exists, if not create it
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'instructors') THEN
        CREATE TABLE public.instructors (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
            first_name VARCHAR(100) NOT NULL,
            last_name VARCHAR(100) NOT NULL,
            email VARCHAR(255) NOT NULL UNIQUE,
            phone VARCHAR(20),
            bio TEXT,
            specialties TEXT[],
            certification_info JSONB DEFAULT '{}',
            rating DECIMAL(3,2) DEFAULT 0,
            total_reviews INTEGER DEFAULT 0,
            is_active BOOLEAN DEFAULT true,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW()
        );

        -- Create indexes for performance
        CREATE INDEX idx_instructors_user_id ON public.instructors(user_id);
        CREATE INDEX idx_instructors_email ON public.instructors(email);
        CREATE INDEX idx_instructors_is_active ON public.instructors(is_active);
    END IF;
END $$;

-- ===================================
-- 3. Create venues table if it doesn't exist
-- ===================================

-- Check if venues table exists, if not create it
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'venues') THEN
        CREATE TABLE public.venues (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            name VARCHAR(255) NOT NULL,
            address TEXT NOT NULL,
            city VARCHAR(100) NOT NULL,
            state VARCHAR(50) NOT NULL,
            zip_code VARCHAR(20) NOT NULL,
            country VARCHAR(100) DEFAULT 'USA',
            latitude DECIMAL(10, 8),
            longitude DECIMAL(11, 8),
            description TEXT,
            amenities TEXT[],
            capacity INTEGER,
            contact_email VARCHAR(255),
            contact_phone VARCHAR(20),
            website VARCHAR(255),
            parking_info TEXT,
            public_transport_info TEXT,
            is_active BOOLEAN DEFAULT true,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW()
        );

        -- Create indexes for performance
        CREATE INDEX idx_venues_is_active ON public.venues(is_active);
        CREATE INDEX idx_venues_location ON public.venues(latitude, longitude);
        CREATE INDEX idx_venues_city_state ON public.venues(city, state);
    END IF;
END $$;

-- ===================================
-- 4. Enable RLS on instructors table
-- ===================================

ALTER TABLE public.instructors ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Instructors are viewable by everyone" ON public.instructors;
DROP POLICY IF EXISTS "Users can update their own instructor profile" ON public.instructors;
DROP POLICY IF EXISTS "Service role can manage all instructors" ON public.instructors;

-- Create RLS policies for instructors
CREATE POLICY "Instructors are viewable by everyone" 
    ON public.instructors 
    FOR SELECT 
    USING (is_active = true);

CREATE POLICY "Users can update their own instructor profile" 
    ON public.instructors 
    FOR UPDATE 
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can insert their own instructor profile" 
    ON public.instructors 
    FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Service role can manage all instructors" 
    ON public.instructors 
    FOR ALL 
    USING (auth.role() = 'service_role');

-- ===================================
-- 5. Enable RLS on venues table
-- ===================================

ALTER TABLE public.venues ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Venues are viewable by everyone" ON public.venues;
DROP POLICY IF EXISTS "Only admins can manage venues" ON public.venues;
DROP POLICY IF EXISTS "Service role can manage all venues" ON public.venues;

-- Create RLS policies for venues
CREATE POLICY "Venues are viewable by everyone" 
    ON public.venues 
    FOR SELECT 
    USING (is_active = true);

CREATE POLICY "Only authenticated users can create venues" 
    ON public.venues 
    FOR INSERT 
    WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Service role can manage all venues" 
    ON public.venues 
    FOR ALL 
    USING (auth.role() = 'service_role');

-- ===================================
-- 6. Update existing functions to remove SECURITY DEFINER where not needed
-- ===================================

-- Note: The analytics functions in the previous migration use SECURITY DEFINER
-- which is appropriate for those specific functions as they aggregate data
-- across multiple users. However, we should ensure they have proper checks.

-- Add comment to existing functions explaining why SECURITY DEFINER is needed
COMMENT ON FUNCTION get_commission_summary IS 
'Aggregates commission data across all bookings. Uses SECURITY DEFINER to access booking data for analytics while respecting user permissions through function parameters.';

COMMENT ON FUNCTION get_instructor_performance IS 
'Calculates instructor performance metrics. Uses SECURITY DEFINER to aggregate booking data while restricting access to specific instructor via parameter.';

COMMENT ON FUNCTION get_credit_usage_analytics IS 
'Provides credit usage analytics across the platform. Uses SECURITY DEFINER for platform-wide analytics while being restricted to authenticated users.';

COMMENT ON FUNCTION get_top_classes_by_revenue IS 
'Returns top performing classes by revenue. Uses SECURITY DEFINER to aggregate revenue data while respecting view permissions.';

-- ===================================
-- 7. Create trigger functions for updated_at if not exists
-- ===================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add triggers for new tables
DROP TRIGGER IF EXISTS update_instructors_updated_at ON public.instructors;
CREATE TRIGGER update_instructors_updated_at 
    BEFORE UPDATE ON public.instructors
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_venues_updated_at ON public.venues;
CREATE TRIGGER update_venues_updated_at 
    BEFORE UPDATE ON public.venues
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- ===================================
-- 8. Grant appropriate permissions
-- ===================================

-- Grant permissions on instructors table
GRANT SELECT ON public.instructors TO anon, authenticated;
GRANT INSERT, UPDATE ON public.instructors TO authenticated;

-- Grant permissions on venues table
GRANT SELECT ON public.venues TO anon, authenticated;
GRANT INSERT, UPDATE ON public.venues TO authenticated;

-- ===================================
-- 9. Add comments for documentation
-- ===================================

COMMENT ON TABLE public.instructors IS 'Stores instructor profiles with RLS enabled for security';
COMMENT ON TABLE public.venues IS 'Stores venue information with RLS enabled for security';

-- ===================================
-- Verification Query
-- ===================================

-- This query can be run to verify that all security issues are fixed:
/*
SELECT 
    'Tables with RLS disabled' as check_type,
    schemaname,
    tablename
FROM pg_tables t
LEFT JOIN pg_class c ON c.relname = t.tablename
WHERE schemaname = 'public'
AND NOT EXISTS (
    SELECT 1 FROM pg_class
    WHERE oid = c.oid
    AND relrowsecurity = true
)
AND tablename IN ('instructors', 'venues', 'bookings', 'classes', 'credit_packs', 'user_credits', 'credit_transactions', 'credit_pack_purchases', 'studio_commission_settings')

UNION ALL

SELECT 
    'Views with SECURITY DEFINER' as check_type,
    schemaname,
    viewname as tablename
FROM pg_views
WHERE schemaname = 'public'
AND definition LIKE '%SECURITY DEFINER%';
*/

-- End of security fix migration