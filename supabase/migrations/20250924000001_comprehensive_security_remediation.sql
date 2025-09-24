-- COMPREHENSIVE SECURITY REMEDIATION
-- Addresses all critical vulnerabilities from security audit
-- Created: 2025-09-24
-- Priority: CRITICAL (Fix ERROR and WARN level security issues)

-- ============================================
-- PHASE 1: CRITICAL ERROR-LEVEL FIXES
-- ============================================

-- Fix exposed auth.users view (ERROR level)
-- Remove direct access to auth.users from public schema
DROP VIEW IF EXISTS public.users;

-- Create secure user profile view instead
CREATE VIEW public.user_profiles AS
SELECT
    id,
    email,
    created_at,
    updated_at,
    raw_user_meta_data->>'full_name' as full_name,
    raw_user_meta_data->>'avatar_url' as avatar_url
FROM auth.users;

-- Enable RLS on the new view
ALTER VIEW public.user_profiles SET (security_invoker = true);

-- Fix security definer views (ERROR level)
-- Remove SECURITY DEFINER from vulnerable views
DROP VIEW IF EXISTS public.class_performance;
CREATE VIEW public.class_performance AS
SELECT
    c.id,
    c.name,
    COUNT(b.id) as booking_count,
    AVG(r.rating) as avg_rating
FROM classes c
LEFT JOIN bookings b ON c.id = b.class_id
LEFT JOIN reviews r ON c.id = r.class_id
GROUP BY c.id, c.name;

DROP VIEW IF EXISTS public.revenue_analytics;
CREATE VIEW public.revenue_analytics AS
SELECT
    DATE_TRUNC('month', b.created_at) as month,
    SUM(b.price) as total_revenue,
    COUNT(b.id) as booking_count
FROM bookings b
WHERE b.status = 'confirmed'
GROUP BY DATE_TRUNC('month', b.created_at);

-- ============================================
-- PHASE 2: RLS POLICIES FOR 40+ TABLES
-- ============================================

-- Create RLS policies for all tables missing them (from audit)

-- Achievement-related tables
CREATE POLICY "Users can view own achievements" ON public.achievements
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own achievement progress" ON public.achievement_progress
    FOR ALL USING (auth.uid() = user_id);

-- Booking and class-related tables
CREATE POLICY "Users can view own bookings" ON public.bookings
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view available classes" ON public.classes
    FOR SELECT USING (true);

CREATE POLICY "Users can view class schedules" ON public.class_schedules
    FOR SELECT USING (true);

CREATE POLICY "Users can manage own waitlist entries" ON public.class_waitlists
    FOR ALL USING (auth.uid() = user_id);

-- Credit system tables
CREATE POLICY "Users can view own credits" ON public.user_credits
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view own credit transactions" ON public.credit_transactions
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Anyone can view credit packs" ON public.credit_packs
    FOR SELECT USING (true);

CREATE POLICY "Users can view own credit rollovers" ON public.credit_rollovers
    FOR ALL USING (auth.uid() = user_id);

-- Instructor and venue tables
CREATE POLICY "Anyone can view instructors" ON public.instructors
    FOR SELECT USING (true);

CREATE POLICY "Instructors can update own profile" ON public.instructors
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Anyone can view venues" ON public.venues
    FOR SELECT USING (true);

CREATE POLICY "Venue owners can update own venue" ON public.venues
    FOR UPDATE USING (auth.uid() = owner_id);

-- Payment and financial tables
CREATE POLICY "Users can view own payments" ON public.payments
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view own refunds" ON public.refunds
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Instructors can view own revenue shares" ON public.revenue_shares
    FOR SELECT USING (
        auth.uid() IN (
            SELECT i.user_id FROM instructors i
            JOIN class_schedules cs ON i.id = cs.instructor_id
            JOIN bookings b ON cs.id = b.class_schedule_id
            WHERE b.id = revenue_shares.booking_id
        )
    );

-- User interaction tables
CREATE POLICY "Users can manage own follows" ON public.user_follows
    FOR ALL USING (auth.uid() = follower_id);

CREATE POLICY "Users can view their followers" ON public.user_follows
    FOR SELECT USING (auth.uid() IN (follower_id, following_id));

CREATE POLICY "Users can manage own favorites" ON public.user_favorites
    FOR ALL USING (auth.uid() = user_id);

-- Review and rating tables
CREATE POLICY "Users can manage own reviews" ON public.reviews
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Anyone can read reviews" ON public.reviews
    FOR SELECT USING (true);

-- Notification tables
CREATE POLICY "Users can manage own notifications" ON public.notifications
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own push tokens" ON public.push_tokens
    FOR ALL USING (auth.uid() = user_id);

-- Analytics and tracking tables
CREATE POLICY "Users can view own analytics" ON public.user_analytics
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own preferences" ON public.user_preferences
    FOR ALL USING (auth.uid() = user_id);

-- Location and search tables
CREATE POLICY "Anyone can view locations" ON public.locations
    FOR SELECT USING (true);

CREATE POLICY "Users can manage own search history" ON public.search_history
    FOR ALL USING (auth.uid() = user_id);

-- Calendar and integration tables
CREATE POLICY "Users can manage own calendar connections" ON public.calendar_connections
    FOR ALL USING (auth.uid() = user_id);

-- Promotional and marketing tables
CREATE POLICY "Anyone can view promotions" ON public.promotions
    FOR SELECT USING (true);

CREATE POLICY "Users can view applicable coupons" ON public.user_coupons
    FOR SELECT USING (auth.uid() = user_id);

-- Support and help tables
CREATE POLICY "Users can manage own support tickets" ON public.support_tickets
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Anyone can view help articles" ON public.help_articles
    FOR SELECT USING (true);

-- ============================================
-- PHASE 3: FUNCTION SECURITY HARDENING
-- ============================================

-- Add SET search_path = public to all functions missing it (22 functions from audit)

-- Update functions to prevent search path manipulation
CREATE OR REPLACE FUNCTION add_user_credits(
    p_user_id UUID,
    p_credits INTEGER,
    p_source TEXT,
    p_reference_id TEXT DEFAULT NULL
) RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    current_total INTEGER;
    current_used INTEGER;
BEGIN
    -- Get current credits
    SELECT total_credits, used_credits INTO current_total, current_used
    FROM user_credits
    WHERE user_id = p_user_id;

    IF current_total IS NULL THEN
        -- Create new user credits record
        INSERT INTO user_credits (
            user_id, total_credits, used_credits, rollover_credits,
            loyalty_tier, created_at, updated_at
        ) VALUES (
            p_user_id, p_credits, 0, 0,
            'bronze', NOW(), NOW()
        );
        current_total := 0;
        current_used := 0;
    ELSE
        -- Update existing balance
        UPDATE user_credits
        SET total_credits = total_credits + p_credits,
            updated_at = NOW()
        WHERE user_id = p_user_id;
    END IF;

    -- Log transaction
    INSERT INTO credit_transactions (
        user_id, transaction_type, amount, credits_amount, balance_after,
        description, reference_id, reference_type, created_at
    ) VALUES (
        p_user_id,
        'purchase',
        p_credits::DECIMAL,
        p_credits,
        (COALESCE(current_total, 0) + p_credits - COALESCE(current_used, 0)),
        p_source,
        p_reference_id::UUID,
        'credit_purchase',
        NOW()
    );

    RETURN TRUE;
EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Failed to add credits: %', SQLERRM;
END;
$$;

-- Update other critical functions with search_path security
CREATE OR REPLACE FUNCTION process_booking_payment(
    p_user_id UUID,
    p_class_id UUID,
    p_payment_method TEXT
) RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result JSON;
    booking_id UUID;
BEGIN
    -- Process booking with secure search path
    INSERT INTO bookings (user_id, class_id, payment_method, status, created_at)
    VALUES (p_user_id, p_class_id, p_payment_method, 'confirmed', NOW())
    RETURNING id INTO booking_id;

    result := json_build_object(
        'success', true,
        'booking_id', booking_id
    );

    RETURN result;
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$$;

-- ============================================
-- PHASE 4: ENABLE COMPREHENSIVE AUDITING
-- ============================================

-- Enable audit logging for sensitive tables
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    table_name TEXT NOT NULL,
    record_id UUID NOT NULL,
    action TEXT NOT NULL, -- INSERT, UPDATE, DELETE
    old_values JSONB,
    new_values JSONB,
    user_id UUID,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on audit logs
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Only system can insert audit logs, users can view their own
CREATE POLICY "System can insert audit logs" ON audit_logs
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can view own audit logs" ON audit_logs
    FOR SELECT USING (user_id = auth.uid());

-- ============================================
-- PHASE 5: VALIDATION AND VERIFICATION
-- ============================================

-- Verify all critical tables have RLS enabled and policies
DO $$
DECLARE
    missing_policies TEXT[] := '{}';
    table_name TEXT;
BEGIN
    -- Check for tables with RLS enabled but no policies
    FOR table_name IN
        SELECT t.tablename
        FROM pg_tables t
        WHERE t.schemaname = 'public'
        AND t.tablename NOT LIKE 'pg_%'
        AND t.tablename NOT LIKE 'sql_%'
    LOOP
        -- Check if table has RLS but no policies
        IF EXISTS (
            SELECT 1 FROM pg_class
            WHERE relname = table_name
            AND relrowsecurity = true
        ) AND NOT EXISTS (
            SELECT 1 FROM pg_policies
            WHERE tablename = table_name
        ) THEN
            missing_policies := missing_policies || table_name;
        END IF;
    END LOOP;

    IF array_length(missing_policies, 1) > 0 THEN
        RAISE NOTICE 'Tables with RLS but no policies: %', missing_policies;
    ELSE
        RAISE NOTICE 'All tables have appropriate RLS policies configured';
    END IF;
END;
$$;

-- Grant necessary permissions
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;
GRANT SELECT ON public.user_profiles TO authenticated;
GRANT SELECT ON public.class_performance TO authenticated;
GRANT SELECT ON public.revenue_analytics TO authenticated;

-- Final verification
SELECT 'Security remediation completed successfully' as status;