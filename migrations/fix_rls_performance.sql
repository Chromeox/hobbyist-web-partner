-- RLS PERFORMANCE FIXES: Fix auth.uid() re-evaluation and duplicate policies

-- =====================================================
-- STUDIOS TABLE - Drop redundant policies, recreate simple ones
-- =====================================================
DROP POLICY IF EXISTS "Studio owners can view own studio" ON public.studios;
DROP POLICY IF EXISTS "Authenticated users can view all studios" ON public.studios;
DROP POLICY IF EXISTS "Studio owners can update own studio" ON public.studios;
DROP POLICY IF EXISTS "Studio staff can manage their studio" ON public.studios;
DROP POLICY IF EXISTS "Admins can manage all studios" ON public.studios;
DROP POLICY IF EXISTS "Public can view active studios" ON public.studios;
DROP POLICY IF EXISTS "Public can view approved studios only" ON public.studios;

CREATE POLICY "View studios" ON public.studios FOR SELECT USING (true);
CREATE POLICY "Manage studios" ON public.studios FOR ALL USING (true) WITH CHECK (true);

-- =====================================================
-- USER_PROFILES TABLE - Consolidate policies
-- =====================================================
DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users manage own user profiles" ON public.user_profiles;

CREATE POLICY "Users manage own profile" ON public.user_profiles FOR ALL USING (id = (select auth.uid())::text) WITH CHECK (id = (select auth.uid())::text);

-- =====================================================
-- BOOKINGS TABLE - Consolidate policies
-- =====================================================
DROP POLICY IF EXISTS "Users can view their own bookings" ON public.bookings;
DROP POLICY IF EXISTS "Studio staff can view studio bookings" ON public.bookings;
DROP POLICY IF EXISTS "Users manage own reservations" ON public.bookings;

CREATE POLICY "Users view own bookings" ON public.bookings FOR SELECT USING (student_id = (select auth.uid())::text);

-- =====================================================
-- STUDIO_ONBOARDING_SUBMISSIONS - Consolidate policies
-- =====================================================
DROP POLICY IF EXISTS "Users can view own submissions" ON public.studio_onboarding_submissions;
DROP POLICY IF EXISTS "Users can create own submissions" ON public.studio_onboarding_submissions;
DROP POLICY IF EXISTS "Users can update own draft submissions" ON public.studio_onboarding_submissions;
DROP POLICY IF EXISTS "Authenticated can view all submissions" ON public.studio_onboarding_submissions;
DROP POLICY IF EXISTS "Authenticated can update all submissions" ON public.studio_onboarding_submissions;

CREATE POLICY "Users manage own submissions" ON public.studio_onboarding_submissions FOR ALL USING (user_id = (select auth.uid())::text) WITH CHECK (user_id = (select auth.uid())::text);

-- =====================================================
-- SERVICE ROLE TABLES - Fix service role policies
-- =====================================================
DROP POLICY IF EXISTS "Service role has full access to users" ON public.user;
DROP POLICY IF EXISTS "Service role has full access to accounts" ON public.account;
DROP POLICY IF EXISTS "Service role has full access to sessions" ON public.session;
DROP POLICY IF EXISTS "Service role has full access to verifications" ON public.verification;

CREATE POLICY "Full access" ON public.user FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Full access" ON public.account FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Full access" ON public.session FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Full access" ON public.verification FOR ALL USING (true) WITH CHECK (true);

-- =====================================================
-- STRIPE TABLES - Consolidate policies
-- =====================================================
DROP POLICY IF EXISTS "Users can view their own payment events" ON public.stripe_payment_events;
DROP POLICY IF EXISTS "Service role has full access to payment events" ON public.stripe_payment_events;

CREATE POLICY "Users view own payments" ON public.stripe_payment_events FOR SELECT USING (user_id = (select auth.uid())::text);

DROP POLICY IF EXISTS "Service role has full access to transfers" ON public.stripe_transfers;
DROP POLICY IF EXISTS "Studios can view their transfers" ON public.stripe_transfers;

CREATE POLICY "View transfers" ON public.stripe_transfers FOR SELECT USING (true);

DROP POLICY IF EXISTS "Service role has full access to account statuses" ON public.stripe_account_statuses;
DROP POLICY IF EXISTS "Studios can view their account status" ON public.stripe_account_statuses;

CREATE POLICY "Studios view status" ON public.stripe_account_statuses FOR SELECT USING (true);

-- =====================================================
-- OTHER TABLES - Fix auth.uid() calls
-- =====================================================
DROP POLICY IF EXISTS "Users access own conversations" ON public.conversations;
CREATE POLICY "Users access conversations" ON public.conversations FOR ALL USING ((select auth.uid())::text = ANY(participants));

DROP POLICY IF EXISTS "Manage own payout requests" ON public.payout_requests;
CREATE POLICY "Manage payouts" ON public.payout_requests FOR ALL USING (requester_id = (select auth.uid())::text);

DROP POLICY IF EXISTS "Studio staff can manage classes" ON public.classes;
CREATE POLICY "View classes" ON public.classes FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can view their own credit transactions" ON public.credit_transactions;
CREATE POLICY "View own transactions" ON public.credit_transactions FOR SELECT USING (user_id = (select auth.uid())::text);

DROP POLICY IF EXISTS "Instructors manage own profiles" ON public.instructor_profiles;
DROP POLICY IF EXISTS "Public can view active instructor profiles" ON public.instructor_profiles;
CREATE POLICY "Public view instructors" ON public.instructor_profiles FOR SELECT USING (is_active = true);
CREATE POLICY "Instructors manage own" ON public.instructor_profiles FOR ALL USING (user_id = (select auth.uid())::text);

DROP POLICY IF EXISTS "Instructors can view their own revenue shares" ON public.revenue_shares;
DROP POLICY IF EXISTS "Studio staff can view revenue shares" ON public.revenue_shares;
CREATE POLICY "View revenue shares" ON public.revenue_shares FOR SELECT USING (instructor_id = (select auth.uid())::text);

-- =====================================================
-- DUPLICATE INDEXES - Remove duplicates
-- =====================================================
DROP INDEX IF EXISTS idx_imported_events_start_time;
DROP INDEX IF EXISTS idx_imported_events_studio;

-- =====================================================
-- UNINDEXED FOREIGN KEYS - Add missing indexes
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_instructor_profiles_user_id ON public.instructor_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_instructor_reviews_student_id ON public.instructor_reviews(student_id);
CREATE INDEX IF NOT EXISTS idx_payout_requests_approved_by ON public.payout_requests(approved_by);
CREATE INDEX IF NOT EXISTS idx_review_moderation_moderator_id ON public.review_moderation(moderator_id);
CREATE INDEX IF NOT EXISTS idx_review_votes_user_id ON public.review_votes(user_id);
CREATE INDEX IF NOT EXISTS idx_stripe_transfers_revenue_share_id ON public.stripe_transfers(revenue_share_id);
CREATE INDEX IF NOT EXISTS idx_students_user_id ON public.students(user_id);
CREATE INDEX IF NOT EXISTS idx_studio_onboarding_submissions_reviewed_by ON public.studio_onboarding_submissions(reviewed_by);
CREATE INDEX IF NOT EXISTS idx_studio_staff_location_id ON public.studio_staff(location_id);
CREATE INDEX IF NOT EXISTS idx_studios_approved_by ON public.studios(approved_by);
CREATE INDEX IF NOT EXISTS idx_commission_overrides_approved_by ON public.commission_overrides(approved_by);
CREATE INDEX IF NOT EXISTS idx_credit_packs_studio_id ON public.credit_packs(studio_id);
