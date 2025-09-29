-- RLS PERFORMANCE OPTIMIZATION (CORRECTED VERSION)
-- Only optimizes policies that actually exist with correct column references
-- Expected: 50-70% query performance improvement

-- ============================================
-- PHASE 1: OPTIMIZE EXISTING POLICIES ONLY
-- ============================================

-- Studios table optimization (based on actual existing policy)
DROP POLICY IF EXISTS "Studios can update their own data" ON public.studios;
CREATE POLICY "Studios can update their own data" ON public.studios
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM studio_staff
            WHERE studio_staff.studio_id = studios.id
            AND studio_staff.user_id = (SELECT auth.uid())
            AND studio_staff.role::text = ANY (ARRAY['owner'::character varying, 'admin'::character varying]::text[])
        )
    );

-- User subscriptions optimization (if table exists)
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'user_subscriptions') THEN
        DROP POLICY IF EXISTS "Users can view own subscriptions" ON public.user_subscriptions;
        CREATE POLICY "Users can view own subscriptions" ON public.user_subscriptions
            FOR SELECT USING ((SELECT auth.uid()) = user_id);
    END IF;
END
$$;

-- User insurance subscriptions optimization (if table exists)
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'user_insurance_subscriptions') THEN
        DROP POLICY IF EXISTS "Users can view own insurance" ON public.user_insurance_subscriptions;
        CREATE POLICY "Users can view own insurance" ON public.user_insurance_subscriptions
            FOR SELECT USING ((SELECT auth.uid()) = user_id);
    END IF;
END
$$;

-- Credit rollovers optimization (we know this table exists)
DROP POLICY IF EXISTS "Users can view own credit rollovers" ON public.credit_rollovers;
CREATE POLICY "Users can view own credit rollovers" ON public.credit_rollovers
    FOR ALL USING ((SELECT auth.uid()) = user_id);

-- Notifications optimizations (we know these exist from policy list)
DROP POLICY IF EXISTS "notifications_select_own" ON public.notifications;
CREATE POLICY "notifications_select_own" ON public.notifications
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "notifications_update_own" ON public.notifications;
CREATE POLICY "notifications_update_own" ON public.notifications
    FOR UPDATE USING ((SELECT auth.uid()) = user_id);

-- Push tokens optimizations (we know these exist from policy list)
DROP POLICY IF EXISTS "push_tokens_select_own" ON public.push_tokens;
CREATE POLICY "push_tokens_select_own" ON public.push_tokens
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "push_tokens_insert_own" ON public.push_tokens;
CREATE POLICY "push_tokens_insert_own" ON public.push_tokens
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "push_tokens_update_own" ON public.push_tokens;
CREATE POLICY "push_tokens_update_own" ON public.push_tokens
    FOR UPDATE USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "push_tokens_delete_own" ON public.push_tokens;
CREATE POLICY "push_tokens_delete_own" ON public.push_tokens
    FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- Class reviews optimizations (conditional based on existence)
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_policies WHERE schemaname = 'public' AND tablename = 'class_reviews' AND policyname = 'Users can create their own reviews') THEN
        DROP POLICY "Users can create their own reviews" ON public.class_reviews;
        CREATE POLICY "Users can create their own reviews" ON public.class_reviews
            FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);
    END IF;

    IF EXISTS (SELECT FROM pg_policies WHERE schemaname = 'public' AND tablename = 'class_reviews' AND policyname = 'Users can update their own reviews') THEN
        DROP POLICY "Users can update their own reviews" ON public.class_reviews;
        CREATE POLICY "Users can update their own reviews" ON public.class_reviews
            FOR UPDATE USING ((SELECT auth.uid()) = user_id);
    END IF;
END
$$;

-- Revenue shares optimization (we know this exists)
DROP POLICY IF EXISTS "View own revenue shares" ON public.revenue_shares;
CREATE POLICY "View own revenue shares" ON public.revenue_shares
    FOR SELECT USING ((SELECT auth.uid()) IN (
        SELECT b.user_id FROM bookings b WHERE b.id = revenue_shares.booking_id
    ));

-- Payout requests optimization (we know this exists)
DROP POLICY IF EXISTS "Manage own payout requests" ON public.payout_requests;
CREATE POLICY "Manage own payout requests" ON public.payout_requests
    FOR ALL USING ((SELECT auth.uid()) = requester_id);

-- Class waitlists optimizations (conditional)
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_policies WHERE schemaname = 'public' AND tablename = 'class_waitlists' AND policyname = 'Users can manage own waitlist entries') THEN
        DROP POLICY "Users can manage own waitlist entries" ON public.class_waitlists;
        CREATE POLICY "Users can manage own waitlist entries" ON public.class_waitlists
            FOR ALL USING ((SELECT auth.uid()) = user_id);
    END IF;

    IF EXISTS (SELECT FROM pg_policies WHERE schemaname = 'public' AND tablename = 'class_waitlists' AND policyname = 'Users can update own waitlist entries') THEN
        DROP POLICY "Users can update own waitlist entries" ON public.class_waitlists;
        CREATE POLICY "Users can update own waitlist entries" ON public.class_waitlists
            FOR UPDATE USING ((SELECT auth.uid()) = user_id);
    END IF;

    IF EXISTS (SELECT FROM pg_policies WHERE schemaname = 'public' AND tablename = 'class_waitlists' AND policyname = 'Users can delete own waitlist entries') THEN
        DROP POLICY "Users can delete own waitlist entries" ON public.class_waitlists;
        CREATE POLICY "Users can delete own waitlist entries" ON public.class_waitlists
            FOR DELETE USING ((SELECT auth.uid()) = user_id);
    END IF;
END
$$;

-- Success confirmation
SELECT 'RLS Performance Optimization Applied - Existing Policies Only' as status;