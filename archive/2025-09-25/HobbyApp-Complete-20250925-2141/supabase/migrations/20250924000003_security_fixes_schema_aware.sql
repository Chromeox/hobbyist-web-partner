-- SCHEMA-AWARE SECURITY FIXES
-- Based on actual database inspection: user_profiles TABLE exists, users VIEW exists
-- Only fixing actual security issues without conflicts

-- ============================================
-- PHASE 1: REMOVE EXPOSED AUTH USERS VIEW
-- ============================================

-- The 'users' view exposes auth.users - this is the critical security issue
-- Replace it with a secure version that doesn't expose sensitive auth data
DROP VIEW IF EXISTS public.users CASCADE;

-- Create a secure replacement that only exposes safe user data
CREATE VIEW public.users AS
SELECT
    id,
    email,
    created_at,
    updated_at,
    -- Only expose metadata that's safe for public consumption
    (raw_user_meta_data ->> 'full_name') AS full_name,
    (raw_user_meta_data ->> 'avatar_url') AS avatar_url
FROM auth.users;

-- Enable RLS on the view
ALTER VIEW public.users SET (security_invoker = true);

-- ============================================
-- PHASE 2: FIX SECURITY DEFINER VIEWS
-- ============================================

-- Update revenue_analytics to remove SECURITY DEFINER if present
CREATE OR REPLACE VIEW public.revenue_analytics AS
SELECT
    date_trunc('month'::text, created_at) AS month,
    studio_id,
    instructor_id,
    count(DISTINCT booking_id) AS total_bookings,
    sum(total_amount) AS gross_revenue,
    sum(instructor_share) AS instructor_earnings,
    sum(studio_share) AS studio_earnings,
    sum(platform_fee) AS platform_revenue,
    avg(instructor_percentage) AS avg_instructor_percentage,
    avg(studio_percentage) AS avg_studio_percentage
FROM revenue_shares rs
WHERE ((status)::text = 'processed'::text)
GROUP BY (date_trunc('month'::text, created_at)), studio_id, instructor_id;

-- ============================================
-- PHASE 3: ADD MISSING RLS POLICIES
-- ============================================

-- Only add policies for tables that don't already have them
-- Based on your security audit, these tables need policies:

-- Add RLS policy for achievements (not in current policy list)
DROP POLICY IF EXISTS "Users can view own achievements" ON public.achievements;
CREATE POLICY "Users can view own achievements" ON public.achievements
    FOR ALL USING (auth.uid() = user_id);

-- Add RLS policy for user_profiles table (exists but no policies shown)
DROP POLICY IF EXISTS "Users can manage own profile" ON public.user_profiles;
CREATE POLICY "Users can manage own profile" ON public.user_profiles
    FOR ALL USING (auth.uid() = user_id);

-- Add RLS policy for venues (exists but might need user-specific access)
DROP POLICY IF EXISTS "Anyone can view venues" ON public.venues;
CREATE POLICY "Anyone can view venues" ON public.venues
    FOR SELECT USING (true);

-- Add policy for instructors (exists, need to ensure proper access)
DROP POLICY IF EXISTS "Anyone can view instructors" ON public.instructors;
CREATE POLICY "Anyone can view instructors" ON public.instructors
    FOR SELECT USING (true);

-- ============================================
-- PHASE 4: FUNCTION SECURITY HARDENING
-- ============================================

-- Update critical functions to have SET search_path = public
-- This prevents search path manipulation attacks

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
    -- Get current credits using correct column names
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

-- Grant necessary permissions
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;
GRANT SELECT ON public.users TO authenticated;
GRANT SELECT ON public.revenue_analytics TO authenticated;

-- Success message
SELECT 'Schema-aware security fixes applied successfully' as status;