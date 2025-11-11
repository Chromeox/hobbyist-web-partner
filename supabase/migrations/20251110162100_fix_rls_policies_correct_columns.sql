-- Fix RLS Policies with Correct Column Names
-- Created: 2025-11-10

-- ============================================================================
-- 1. Fix studio_preferences policies (no owner_id, use studio_id directly)
-- ============================================================================

DROP POLICY IF EXISTS "Studios can view their own preferences" ON public.studio_preferences;
DROP POLICY IF EXISTS "Studios can update their own preferences" ON public.studio_preferences;

-- Studios table doesn't have owner_id, so use studio_staff or instructor_profiles
-- For now, allow service_role only until we clarify ownership model
CREATE POLICY "Service role full access to studio preferences"
  ON public.studio_preferences
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);


-- ============================================================================
-- 2. Fix calendar_integrations policies (use studio_id, not user_id)
-- ============================================================================

DROP POLICY IF EXISTS "Users can view their own calendar integrations" ON public.calendar_integrations;
DROP POLICY IF EXISTS "Users can manage their own calendar integrations" ON public.calendar_integrations;

CREATE POLICY "Studio staff can manage calendar integrations"
  ON public.calendar_integrations
  FOR ALL
  TO authenticated
  USING (
    studio_id IN (
      SELECT studio_id FROM studio_staff
      WHERE user_id = (SELECT auth.uid())
    )
  )
  WITH CHECK (
    studio_id IN (
      SELECT studio_id FROM studio_staff
      WHERE user_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Service role full access to calendar integrations"
  ON public.calendar_integrations
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);


-- ============================================================================
-- 3. Fix revenue_shares policies (correct column usage)
-- ============================================================================

DROP POLICY IF EXISTS "Studios can view their own revenue shares" ON public.revenue_shares;

CREATE POLICY "Studio staff can view revenue shares"
  ON public.revenue_shares
  FOR SELECT
  TO authenticated
  USING (
    studio_id IN (
      SELECT studio_id FROM studio_staff
      WHERE user_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Instructors can view their own revenue shares"
  ON public.revenue_shares
  FOR SELECT
  TO authenticated
  USING (
    instructor_id IN (
      SELECT id FROM instructor_profiles
      WHERE user_id = (SELECT auth.uid())
    )
  );


-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
  policy_count INT;
BEGIN
  -- Count policies for studio_preferences
  SELECT COUNT(*) INTO policy_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename = 'studio_preferences';

  IF policy_count = 0 THEN
    RAISE WARNING '⚠️  No policies found for studio_preferences';
  ELSE
    RAISE NOTICE '✅ studio_preferences has % policies', policy_count;
  END IF;

  -- Count policies for calendar_integrations
  SELECT COUNT(*) INTO policy_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename = 'calendar_integrations';

  IF policy_count = 0 THEN
    RAISE WARNING '⚠️  No policies found for calendar_integrations';
  ELSE
    RAISE NOTICE '✅ calendar_integrations has % policies', policy_count;
  END IF;

  -- Count policies for revenue_shares
  SELECT COUNT(*) INTO policy_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename = 'revenue_shares';

  IF policy_count = 0 THEN
    RAISE WARNING '⚠️  No policies found for revenue_shares';
  ELSE
    RAISE NOTICE '✅ revenue_shares has % policies', policy_count;
  END IF;

  RAISE NOTICE '';
  RAISE NOTICE '=================================================';
  RAISE NOTICE 'RLS Policy Fix Complete';
  RAISE NOTICE '=================================================';
END $$;
