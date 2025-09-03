-- ============================================
-- COMPREHENSIVE SECURITY ENHANCEMENTS
-- Generated: 2025-09-01
-- Purpose: Apply all security fixes and optimizations
-- ============================================

-- ============================================
-- PART 1: RLS VERIFICATION AND FIXES
-- ============================================

-- Ensure RLS is enabled on ALL tables (some may have been missed)
DO $$
DECLARE
    r RECORD;
BEGIN
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
-- PART 2: OPTIMIZE RLS POLICIES WITH INITPLAN
-- ============================================

-- Drop and recreate user_credits policies with optimization
DROP POLICY IF EXISTS "Users can view own credits" ON user_credits;
CREATE POLICY "Users can view own credits" ON user_credits
    FOR ALL 
    USING (user_id = (SELECT auth.uid()))
    WITH CHECK (user_id = (SELECT auth.uid()));

-- Optimize bookings policies
DROP POLICY IF EXISTS "Users can view own bookings" ON bookings;
DROP POLICY IF EXISTS "Users can create own bookings" ON bookings;
DROP POLICY IF EXISTS "Users can update own bookings" ON bookings;

CREATE POLICY "Users manage own bookings" ON bookings
    FOR ALL 
    USING (user_id = (SELECT auth.uid()))
    WITH CHECK (user_id = (SELECT auth.uid()));

-- Optimize credit_transactions policies
DROP POLICY IF EXISTS "Users can view own transactions" ON credit_transactions;
CREATE POLICY "Users can view own transactions" ON credit_transactions
    FOR SELECT 
    USING (user_id = (SELECT auth.uid()));

-- System can insert transactions (for automated processes)
CREATE POLICY "System can create transactions" ON credit_transactions
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM bookings 
            WHERE bookings.user_id = credit_transactions.user_id
            AND bookings.id = credit_transactions.reference_id
        )
    );

-- ============================================
-- PART 3: FIX FUNCTIONS WITH SET SEARCH_PATH
-- ============================================

-- Fix calculate_credits_needed function
CREATE OR REPLACE FUNCTION calculate_credits_needed(
    p_class_id UUID,
    p_schedule_time TIMESTAMPTZ
) RETURNS DECIMAL 
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_base_credits DECIMAL;
    v_multiplier DECIMAL := 1.0;
    v_final_credits DECIMAL;
BEGIN
    -- Get base credits from class tier
    SELECT ct.credit_required INTO v_base_credits
    FROM classes c
    JOIN class_tiers ct ON c.tier_id = ct.id
    WHERE c.id = p_class_id;
    
    -- Apply dynamic pricing rules
    SELECT COALESCE(MAX(dpr.credit_multiplier), 1.0) INTO v_multiplier
    FROM dynamic_pricing_rules dpr
    WHERE dpr.is_active = true
    AND (
        (dpr.rule_type = 'time_based' 
         AND p_schedule_time::time BETWEEN dpr.start_time AND dpr.end_time
         AND EXTRACT(DOW FROM p_schedule_time) = ANY(dpr.days_of_week))
        OR
        (dpr.rule_type = 'seasonal' 
         AND EXTRACT(MONTH FROM p_schedule_time) = ANY(dpr.months))
    )
    ORDER BY dpr.priority DESC
    LIMIT 1;
    
    v_final_credits := v_base_credits * v_multiplier;
    
    RETURN ROUND(v_final_credits, 1);
END;
$$ LANGUAGE plpgsql;

-- Fix process_booking function
CREATE OR REPLACE FUNCTION process_booking(
    p_user_id UUID,
    p_class_schedule_id UUID
) RETURNS UUID 
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_booking_id UUID;
    v_credits_needed DECIMAL;
    v_user_credits INTEGER;
    v_class_id UUID;
    v_schedule_time TIMESTAMPTZ;
BEGIN
    -- Get class details
    SELECT cs.class_id, cs.start_time INTO v_class_id, v_schedule_time
    FROM class_schedules cs
    WHERE cs.id = p_class_schedule_id;
    
    -- Calculate credits needed
    v_credits_needed := calculate_credits_needed(v_class_id, v_schedule_time);
    
    -- Check user has enough credits
    SELECT (total_credits - used_credits) INTO v_user_credits
    FROM user_credits
    WHERE user_id = p_user_id;
    
    IF v_user_credits < v_credits_needed THEN
        RAISE EXCEPTION 'Insufficient credits. Need %, have %', v_credits_needed, v_user_credits;
    END IF;
    
    -- Create booking
    INSERT INTO bookings (
        user_id, 
        class_schedule_id, 
        credits_used, 
        payment_method, 
        status
    ) VALUES (
        p_user_id,
        p_class_schedule_id,
        v_credits_needed,
        'credits',
        'confirmed'
    ) RETURNING id INTO v_booking_id;
    
    -- Update user credits
    UPDATE user_credits
    SET used_credits = used_credits + v_credits_needed,
        updated_at = NOW()
    WHERE user_id = p_user_id;
    
    -- Update class schedule spots
    UPDATE class_schedules
    SET spots_available = spots_available - 1,
        updated_at = NOW()
    WHERE id = p_class_schedule_id;
    
    -- Record transaction
    INSERT INTO credit_transactions (
        user_id,
        transaction_type,
        amount,
        balance_after,
        reference_id,
        reference_type,
        description
    ) VALUES (
        p_user_id,
        'debit',
        v_credits_needed,
        v_user_credits - v_credits_needed,
        v_booking_id,
        'booking',
        'Class booking'
    );
    
    RETURN v_booking_id;
END;
$$ LANGUAGE plpgsql;

-- Fix cancel_booking function
CREATE OR REPLACE FUNCTION cancel_booking(
    p_booking_id UUID,
    p_user_id UUID,
    p_reason TEXT DEFAULT NULL
) RETURNS BOOLEAN 
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_credits_to_refund DECIMAL;
    v_class_schedule_id UUID;
    v_start_time TIMESTAMPTZ;
    v_cancellation_window INTERVAL := INTERVAL '24 hours';
BEGIN
    -- Verify ownership and get booking details
    SELECT b.credits_used, b.class_schedule_id, cs.start_time 
    INTO v_credits_to_refund, v_class_schedule_id, v_start_time
    FROM bookings b
    JOIN class_schedules cs ON b.class_schedule_id = cs.id
    WHERE b.id = p_booking_id 
    AND b.user_id = p_user_id 
    AND b.status = 'confirmed';
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Check cancellation window
    IF v_start_time - NOW() < v_cancellation_window THEN
        -- Late cancellation - 50% credit refund
        v_credits_to_refund := v_credits_to_refund * 0.5;
    END IF;
    
    -- Update booking status
    UPDATE bookings
    SET status = 'cancelled',
        cancelled_at = NOW(),
        cancellation_reason = p_reason,
        updated_at = NOW()
    WHERE id = p_booking_id;
    
    -- Refund credits
    UPDATE user_credits
    SET used_credits = used_credits - v_credits_to_refund,
        updated_at = NOW()
    WHERE user_id = p_user_id;
    
    -- Update class schedule spots
    UPDATE class_schedules
    SET spots_available = spots_available + 1,
        updated_at = NOW()
    WHERE id = v_class_schedule_id;
    
    -- Record refund transaction
    INSERT INTO credit_transactions (
        user_id,
        transaction_type,
        amount,
        reference_id,
        reference_type,
        description
    ) VALUES (
        p_user_id,
        'credit',
        v_credits_to_refund,
        p_booking_id,
        'refund',
        'Booking cancellation refund'
    );
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- PART 4: ADD SECURITY AUDIT TABLES
-- ============================================

-- Create security audit log table
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
CREATE POLICY "Admins can view audit logs" ON security_audit_log
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = (SELECT auth.uid())
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
    );

-- Create failed login attempts table
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

-- Enable RLS
ALTER TABLE failed_login_attempts ENABLE ROW LEVEL SECURITY;

-- No direct access to failed login attempts
CREATE POLICY "System only access" ON failed_login_attempts
    FOR ALL
    USING (FALSE);

-- ============================================
-- PART 5: ADD RATE LIMITING SUPPORT
-- ============================================

-- Create rate limit tracking table
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

-- Enable RLS
ALTER TABLE api_rate_limits ENABLE ROW LEVEL SECURITY;

-- Users can only see their own rate limits
CREATE POLICY "Users view own rate limits" ON api_rate_limits
    FOR SELECT
    USING (user_id = (SELECT auth.uid()));

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

-- ============================================
-- PART 6: ADD DATA ENCRYPTION HELPERS
-- ============================================

-- Create encryption key storage (keys should be in vault, this is metadata)
CREATE TABLE IF NOT EXISTS encryption_keys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key_name TEXT UNIQUE NOT NULL,
    key_version INTEGER DEFAULT 1,
    algorithm TEXT DEFAULT 'AES-256-GCM',
    is_active BOOLEAN DEFAULT true,
    rotated_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE encryption_keys ENABLE ROW LEVEL SECURITY;

-- No direct access to encryption keys
CREATE POLICY "No direct access" ON encryption_keys
    FOR ALL
    USING (FALSE);

-- ============================================
-- PART 7: CREATE SECURITY INDEXES
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
-- PART 8: ADD SECURITY FUNCTIONS
-- ============================================

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
-- PART 9: ADD SECURITY TRIGGERS
-- ============================================

-- Trigger to auto-log booking changes
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

CREATE TRIGGER trigger_audit_booking_changes
    AFTER INSERT OR UPDATE ON bookings
    FOR EACH ROW
    EXECUTE FUNCTION audit_booking_changes();

-- ============================================
-- PART 10: GRANT NECESSARY PERMISSIONS
-- ============================================

-- Grant execute permissions on security functions
GRANT EXECUTE ON FUNCTION check_rate_limit TO authenticated;
GRANT EXECUTE ON FUNCTION log_security_event TO authenticated;
GRANT EXECUTE ON FUNCTION process_booking TO authenticated;
GRANT EXECUTE ON FUNCTION cancel_booking TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_credits_needed TO authenticated;

-- Grant read access to public tables with proper RLS
GRANT SELECT ON classes TO anon, authenticated;
GRANT SELECT ON class_schedules TO anon, authenticated;
GRANT SELECT ON class_tiers TO anon, authenticated;
GRANT SELECT ON studios TO anon, authenticated;
GRANT SELECT ON instructors TO anon, authenticated;
GRANT SELECT ON credit_packs TO anon, authenticated;
GRANT SELECT ON subscription_plans TO anon, authenticated;

-- Grant full access to user-specific tables (RLS will control)
GRANT ALL ON bookings TO authenticated;
GRANT ALL ON user_credits TO authenticated;
GRANT ALL ON credit_transactions TO authenticated;
GRANT ALL ON user_subscriptions TO authenticated;

-- ============================================
-- VERIFICATION
-- ============================================

-- Verify all tables have RLS enabled
DO $$
DECLARE
    r RECORD;
    v_count INTEGER := 0;
BEGIN
    FOR r IN 
        SELECT schemaname, tablename, rowsecurity 
        FROM pg_tables 
        LEFT JOIN pg_class ON pg_class.relname = tablename
        WHERE schemaname = 'public' 
        AND tablename NOT LIKE 'pg_%'
        AND tablename NOT IN ('schema_migrations', 'supabase_migrations')
    LOOP
        IF NOT COALESCE(r.rowsecurity, false) THEN
            RAISE WARNING 'Table %.% does not have RLS enabled!', r.schemaname, r.tablename;
            v_count := v_count + 1;
        END IF;
    END LOOP;
    
    IF v_count = 0 THEN
        RAISE NOTICE '✅ All tables have RLS enabled';
    ELSE
        RAISE WARNING '⚠️ % tables missing RLS', v_count;
    END IF;
END $$;

-- Log migration completion
SELECT log_security_event(
    'migration_completed',
    NULL,
    'database',
    NULL,
    'migrate',
    'success',
    jsonb_build_object(
        'migration', '02_comprehensive_security_enhancements',
        'timestamp', NOW()
    )
);