-- ============================================
-- COMBINED SECURITY MIGRATION FOR HOBBYIST
-- This file contains only the security enhancements
-- Run this if you already have tables set up
-- ============================================

-- ============================================
-- PART 1: ENABLE RLS ON ALL TABLES
-- ============================================

DO $$
DECLARE
    r RECORD;
BEGIN
    -- Enable RLS on all existing public tables
    FOR r IN 
        SELECT schemaname, tablename 
        FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename NOT LIKE 'pg_%'
        AND tablename NOT IN ('schema_migrations', 'supabase_migrations')
    LOOP
        EXECUTE format('ALTER TABLE %I.%I ENABLE ROW LEVEL SECURITY', r.schemaname, r.tablename);
        RAISE NOTICE 'Enabled RLS on %.%', r.schemaname, r.tablename;
    END LOOP;
END $$;

-- ============================================
-- PART 2: CREATE OPTIMIZED RLS POLICIES
-- ============================================

-- User Credits - Users can only manage their own credits
DROP POLICY IF EXISTS "Users can view own credits" ON user_credits;
CREATE POLICY "Users manage own credits" ON user_credits
    FOR ALL 
    USING (user_id = (SELECT auth.uid()))
    WITH CHECK (user_id = (SELECT auth.uid()));

-- Bookings - Users can only manage their own bookings
DROP POLICY IF EXISTS "Users can view own bookings" ON bookings;
DROP POLICY IF EXISTS "Users can create own bookings" ON bookings;
DROP POLICY IF EXISTS "Users can update own bookings" ON bookings;
CREATE POLICY "Users manage own bookings" ON bookings
    FOR ALL 
    USING (user_id = (SELECT auth.uid()))
    WITH CHECK (user_id = (SELECT auth.uid()));

-- Classes - Public can view active classes
DROP POLICY IF EXISTS "Public can view active classes" ON classes;
CREATE POLICY "Public can view active classes" ON classes
    FOR SELECT 
    USING (is_active = true);

-- Class Schedules - Public can view future schedules
DROP POLICY IF EXISTS "Public can view future schedules" ON class_schedules;
CREATE POLICY "Public can view future schedules" ON class_schedules
    FOR SELECT 
    USING (start_time > NOW() AND is_cancelled = false);

-- Studios - Public can view active studios
DROP POLICY IF EXISTS "Public can view active studios" ON studios;
CREATE POLICY "Public can view active studios" ON studios
    FOR SELECT 
    USING (is_active = true);

-- Instructors - Public can view active instructors
DROP POLICY IF EXISTS "Public can view active instructors" ON instructors;
CREATE POLICY "Public can view active instructors" ON instructors
    FOR SELECT 
    USING (is_active = true);

-- Credit Transactions - Users can only view their own
DROP POLICY IF EXISTS "Users can view own transactions" ON credit_transactions;
CREATE POLICY "Users view own transactions" ON credit_transactions
    FOR SELECT 
    USING (user_id = (SELECT auth.uid()));

-- ============================================
-- PART 3: CREATE SECURITY AUDIT TABLES
-- ============================================

-- Security audit log table
CREATE TABLE IF NOT EXISTS security_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type TEXT NOT NULL,
    user_id UUID REFERENCES auth.users(id),
    ip_address INET,
    user_agent TEXT,
    resource_type TEXT,
    resource_id UUID,
    action TEXT,
    result TEXT,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on audit log
ALTER TABLE security_audit_log ENABLE ROW LEVEL SECURITY;

-- Only admins can view audit logs
CREATE POLICY "Admins view audit logs" ON security_audit_log
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = (SELECT auth.uid())
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
    );

-- Failed login attempts tracking
CREATE TABLE IF NOT EXISTS failed_login_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL,
    ip_address INET,
    user_agent TEXT,
    error_message TEXT,
    attempt_count INTEGER DEFAULT 1,
    locked_until TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE failed_login_attempts ENABLE ROW LEVEL SECURITY;

-- No direct access to failed login attempts
CREATE POLICY "System only access" ON failed_login_attempts
    FOR ALL
    USING (FALSE);

-- ============================================
-- PART 4: CREATE RATE LIMITING TABLES
-- ============================================

-- API Rate limiting table
CREATE TABLE IF NOT EXISTS api_rate_limits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id),
    endpoint TEXT NOT NULL,
    request_count INTEGER DEFAULT 1,
    window_start TIMESTAMPTZ DEFAULT NOW(),
    window_end TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '1 hour'),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_user_endpoint_window UNIQUE (user_id, endpoint, window_start)
);

ALTER TABLE api_rate_limits ENABLE ROW LEVEL SECURITY;

-- Users can only see their own rate limits
CREATE POLICY "Users view own rate limits" ON api_rate_limits
    FOR SELECT
    USING (user_id = (SELECT auth.uid()));

-- ============================================
-- PART 5: CREATE SECURITY FUNCTIONS
-- ============================================

-- Function to check rate limits
CREATE OR REPLACE FUNCTION check_rate_limit(
    p_user_id UUID,
    p_endpoint TEXT,
    p_max_requests INTEGER DEFAULT 100
) RETURNS BOOLEAN
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_current_count INTEGER;
BEGIN
    -- Get current request count in window
    SELECT request_count INTO v_current_count
    FROM api_rate_limits
    WHERE user_id = p_user_id
    AND endpoint = p_endpoint
    AND window_end > NOW();
    
    IF v_current_count IS NULL THEN
        -- First request in window
        INSERT INTO api_rate_limits (user_id, endpoint, request_count)
        VALUES (p_user_id, p_endpoint, 1)
        ON CONFLICT (user_id, endpoint, window_start) 
        DO UPDATE SET 
            request_count = api_rate_limits.request_count + 1,
            updated_at = NOW();
        RETURN TRUE;
    ELSIF v_current_count < p_max_requests THEN
        -- Under limit, increment
        UPDATE api_rate_limits
        SET request_count = request_count + 1,
            updated_at = NOW()
        WHERE user_id = p_user_id
        AND endpoint = p_endpoint
        AND window_end > NOW();
        RETURN TRUE;
    ELSE
        -- Rate limit exceeded
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to log security events
CREATE OR REPLACE FUNCTION log_security_event(
    p_event_type TEXT,
    p_user_id UUID DEFAULT NULL,
    p_resource_type TEXT DEFAULT NULL,
    p_resource_id UUID DEFAULT NULL,
    p_action TEXT DEFAULT NULL,
    p_result TEXT DEFAULT 'success',
    p_metadata JSONB DEFAULT '{}'::JSONB
) RETURNS UUID
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_audit_id UUID;
BEGIN
    INSERT INTO security_audit_log (
        event_type,
        user_id,
        resource_type,
        resource_id,
        action,
        result,
        metadata
    ) VALUES (
        p_event_type,
        COALESCE(p_user_id, (SELECT auth.uid())),
        p_resource_type,
        p_resource_id,
        p_action,
        p_result,
        p_metadata
    ) RETURNING id INTO v_audit_id;
    
    RETURN v_audit_id;
END;
$$ LANGUAGE plpgsql;

-- Function to check for suspicious activity
CREATE OR REPLACE FUNCTION check_suspicious_activity(
    p_user_id UUID
) RETURNS BOOLEAN
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_failed_logins INTEGER;
    v_rapid_requests INTEGER;
BEGIN
    -- Check failed login attempts in last hour
    SELECT COUNT(*) INTO v_failed_logins
    FROM security_audit_log
    WHERE user_id = p_user_id
    AND event_type = 'login_failed'
    AND created_at > NOW() - INTERVAL '1 hour';
    
    -- Check for rapid API requests
    SELECT SUM(request_count) INTO v_rapid_requests
    FROM api_rate_limits
    WHERE user_id = p_user_id
    AND window_end > NOW();
    
    -- Flag as suspicious if too many failed logins or rapid requests
    RETURN (v_failed_logins > 5 OR v_rapid_requests > 500);
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- PART 6: CREATE SECURITY INDEXES
-- ============================================

-- Index for audit log queries
CREATE INDEX IF NOT EXISTS idx_security_audit_log_user_id 
    ON security_audit_log(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_security_audit_log_event_type 
    ON security_audit_log(event_type, created_at DESC);

-- Index for failed login attempts
CREATE INDEX IF NOT EXISTS idx_failed_login_attempts_email 
    ON failed_login_attempts(email, created_at DESC);

-- Index for rate limiting
CREATE INDEX IF NOT EXISTS idx_api_rate_limits_user_endpoint 
    ON api_rate_limits(user_id, endpoint, window_end);

-- ============================================
-- PART 7: CREATE AUDIT TRIGGER FOR BOOKINGS
-- ============================================

-- Trigger function to audit booking changes
CREATE OR REPLACE FUNCTION audit_booking_changes()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        PERFORM log_security_event(
            'booking_created',
            NEW.user_id,
            'booking',
            NEW.id,
            'create',
            'success',
            jsonb_build_object('class_schedule_id', NEW.class_schedule_id)
        );
    ELSIF TG_OP = 'UPDATE' AND OLD.status != NEW.status THEN
        PERFORM log_security_event(
            'booking_status_changed',
            NEW.user_id,
            'booking',
            NEW.id,
            'update',
            'success',
            jsonb_build_object(
                'old_status', OLD.status,
                'new_status', NEW.status
            )
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger (if bookings table exists)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'bookings') THEN
        DROP TRIGGER IF EXISTS trigger_audit_booking_changes ON bookings;
        CREATE TRIGGER trigger_audit_booking_changes
            AFTER INSERT OR UPDATE ON bookings
            FOR EACH ROW
            EXECUTE FUNCTION audit_booking_changes();
    END IF;
END $$;

-- ============================================
-- PART 8: GRANT PERMISSIONS
-- ============================================

-- Grant execute permissions on security functions
GRANT EXECUTE ON FUNCTION check_rate_limit TO authenticated;
GRANT EXECUTE ON FUNCTION log_security_event TO authenticated;

-- Grant read access to public tables with RLS
DO $$
DECLARE
    tbl TEXT;
BEGIN
    FOR tbl IN 
        SELECT tablename FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename IN ('classes', 'class_schedules', 'studios', 'instructors')
    LOOP
        EXECUTE format('GRANT SELECT ON %I TO anon, authenticated', tbl);
    END LOOP;
END $$;

-- ============================================
-- PART 9: VERIFICATION
-- ============================================

-- Final verification check
DO $$
DECLARE
    unprotected_count INTEGER;
    total_count INTEGER;
BEGIN
    -- Count unprotected tables
    SELECT 
        COUNT(*) FILTER (WHERE NOT COALESCE(rowsecurity, false)),
        COUNT(*)
    INTO unprotected_count, total_count
    FROM pg_tables t
    LEFT JOIN pg_class c ON c.relname = t.tablename
    WHERE t.schemaname = 'public'
    AND t.tablename NOT IN ('schema_migrations', 'supabase_migrations');
    
    IF unprotected_count = 0 THEN
        RAISE NOTICE '✅ SUCCESS: All % tables have RLS enabled!', total_count;
    ELSE
        RAISE WARNING '⚠️ WARNING: % of % tables are missing RLS protection!', unprotected_count, total_count;
    END IF;
    
    -- Check security tables exist
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'security_audit_log') THEN
        RAISE NOTICE '✅ Security audit log table created';
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'api_rate_limits') THEN
        RAISE NOTICE '✅ Rate limiting table created';
    END IF;
    
    -- Log migration completion
    PERFORM log_security_event(
        'migration_completed',
        NULL,
        'database',
        NULL,
        'migrate',
        'success',
        jsonb_build_object(
            'migration', 'comprehensive_security_enhancements',
            'timestamp', NOW()
        )
    );
    
    RAISE NOTICE '🔐 Security migration completed successfully!';
END $$;