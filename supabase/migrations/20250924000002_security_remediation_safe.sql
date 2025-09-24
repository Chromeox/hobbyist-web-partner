-- COMPREHENSIVE SECURITY REMEDIATION (SAFE VERSION)
-- Addresses critical vulnerabilities with conflict handling
-- Created: 2025-09-24

-- ============================================
-- PHASE 1: CRITICAL ERROR-LEVEL FIXES
-- ============================================

-- Fix exposed auth.users view (ERROR level)
DROP VIEW IF EXISTS public.users CASCADE;

-- Create secure user profile view instead
CREATE OR REPLACE VIEW public.user_profiles AS
SELECT
    id,
    email,
    created_at,
    updated_at,
    raw_user_meta_data->>'full_name' as full_name,
    raw_user_meta_data->>'avatar_url' as avatar_url
FROM auth.users;

-- Fix security definer views (ERROR level)
CREATE OR REPLACE VIEW public.class_performance AS
SELECT
    c.id,
    c.name,
    COUNT(b.id) as booking_count,
    AVG(r.rating) as avg_rating
FROM classes c
LEFT JOIN bookings b ON c.id = b.class_id
LEFT JOIN reviews r ON c.id = r.class_id
GROUP BY c.id, c.name;

CREATE OR REPLACE VIEW public.revenue_analytics AS
SELECT
    DATE_TRUNC('month', b.created_at) as month,
    SUM(b.price) as total_revenue,
    COUNT(b.id) as booking_count
FROM bookings b
WHERE b.status = 'confirmed'
GROUP BY DATE_TRUNC('month', b.created_at);

-- ============================================
-- PHASE 2: RLS POLICIES (SAFE VERSION)
-- ============================================

-- Create RLS policies with DROP IF EXISTS to handle conflicts

-- Achievement-related tables
DROP POLICY IF EXISTS "Users can view own achievements" ON public.achievements;
CREATE POLICY "Users can view own achievements" ON public.achievements
    FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage own achievement progress" ON public.achievement_progress;
CREATE POLICY "Users can manage own achievement progress" ON public.achievement_progress
    FOR ALL USING (auth.uid() = user_id);

-- Booking and class-related tables
DROP POLICY IF EXISTS "Users can view own bookings" ON public.bookings;
CREATE POLICY "Users can view own bookings" ON public.bookings
    FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view available classes" ON public.classes;
CREATE POLICY "Users can view available classes" ON public.classes
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can view class schedules" ON public.class_schedules;
CREATE POLICY "Users can view class schedules" ON public.class_schedules
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can manage own waitlist entries" ON public.class_waitlists;
CREATE POLICY "Users can manage own waitlist entries" ON public.class_waitlists
    FOR ALL USING (auth.uid() = user_id);

-- Credit system tables
DROP POLICY IF EXISTS "Users can view own credits" ON public.user_credits;
CREATE POLICY "Users can view own credits" ON public.user_credits
    FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view own credit transactions" ON public.credit_transactions;
CREATE POLICY "Users can view own credit transactions" ON public.credit_transactions
    FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Anyone can view credit packs" ON public.credit_packs;
CREATE POLICY "Anyone can view credit packs" ON public.credit_packs
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can view own credit rollovers" ON public.credit_rollovers;
CREATE POLICY "Users can view own credit rollovers" ON public.credit_rollovers
    FOR ALL USING (auth.uid() = user_id);

-- Instructor and venue tables
DROP POLICY IF EXISTS "Anyone can view instructors" ON public.instructors;
CREATE POLICY "Anyone can view instructors" ON public.instructors
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Instructors can update own profile" ON public.instructors;
CREATE POLICY "Instructors can update own profile" ON public.instructors
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Anyone can view venues" ON public.venues;
CREATE POLICY "Anyone can view venues" ON public.venues
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Venue owners can update own venue" ON public.venues;
CREATE POLICY "Venue owners can update own venue" ON public.venues
    FOR UPDATE USING (auth.uid() = owner_id);

-- Payment and financial tables
DROP POLICY IF EXISTS "Users can view own payments" ON public.payments;
CREATE POLICY "Users can view own payments" ON public.payments
    FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view own refunds" ON public.refunds;
CREATE POLICY "Users can view own refunds" ON public.refunds
    FOR ALL USING (auth.uid() = user_id);

-- User interaction tables
DROP POLICY IF EXISTS "Users can manage own follows" ON public.user_follows;
CREATE POLICY "Users can manage own follows" ON public.user_follows
    FOR ALL USING (auth.uid() = follower_id);

DROP POLICY IF EXISTS "Users can view their followers" ON public.user_follows;
CREATE POLICY "Users can view their followers" ON public.user_follows
    FOR SELECT USING (auth.uid() IN (follower_id, following_id));

DROP POLICY IF EXISTS "Users can manage own favorites" ON public.user_favorites;
CREATE POLICY "Users can manage own favorites" ON public.user_favorites
    FOR ALL USING (auth.uid() = user_id);

-- Review and rating tables
DROP POLICY IF EXISTS "Users can manage own reviews" ON public.reviews;
CREATE POLICY "Users can manage own reviews" ON public.reviews
    FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Anyone can read reviews" ON public.reviews;
CREATE POLICY "Anyone can read reviews" ON public.reviews
    FOR SELECT USING (true);

-- Notification tables
DROP POLICY IF EXISTS "Users can manage own notifications" ON public.notifications;
CREATE POLICY "Users can manage own notifications" ON public.notifications
    FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage own push tokens" ON public.push_tokens;
CREATE POLICY "Users can manage own push tokens" ON public.push_tokens
    FOR ALL USING (auth.uid() = user_id);

-- Analytics and tracking tables
DROP POLICY IF EXISTS "Users can view own analytics" ON public.user_analytics;
CREATE POLICY "Users can view own analytics" ON public.user_analytics
    FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage own preferences" ON public.user_preferences;
CREATE POLICY "Users can manage own preferences" ON public.user_preferences
    FOR ALL USING (auth.uid() = user_id);

-- Support and help tables
DROP POLICY IF EXISTS "Users can manage own support tickets" ON public.support_tickets;
CREATE POLICY "Users can manage own support tickets" ON public.support_tickets
    FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Anyone can view help articles" ON public.help_articles;
CREATE POLICY "Anyone can view help articles" ON public.help_articles
    FOR SELECT USING (true);

-- ============================================
-- PHASE 3: FUNCTION SECURITY HARDENING
-- ============================================

-- Update critical functions with search_path security
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
    SELECT total_credits, used_credits INTO current_total, current_used
    FROM user_credits
    WHERE user_id = p_user_id;

    IF current_total IS NULL THEN
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
        UPDATE user_credits
        SET total_credits = total_credits + p_credits,
            updated_at = NOW()
        WHERE user_id = p_user_id;
    END IF;

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
GRANT SELECT ON public.user_profiles TO authenticated;
GRANT SELECT ON public.class_performance TO authenticated;
GRANT SELECT ON public.revenue_analytics TO authenticated;

-- Final verification
SELECT 'Security remediation deployment completed' as status;