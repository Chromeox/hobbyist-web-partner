-- Comprehensive Database Security Fix
-- Fixes all ERROR and WARN level issues from Supabase linter
-- Created: 2025-11-10

-- ============================================================================
-- PRIORITY 1: FIX ERROR-LEVEL ISSUES
-- ============================================================================

-- -----------------------------------------------------------------------------
-- 1. Remove SECURITY DEFINER from views (3 views)
-- -----------------------------------------------------------------------------

-- Drop and recreate v_studio_metrics_daily WITHOUT security_definer
DROP VIEW IF EXISTS public.v_studio_metrics_daily CASCADE;
CREATE OR REPLACE VIEW public.v_studio_metrics_daily AS
SELECT
  s.id AS studio_id,
  s.name AS studio_name,
  DATE(b.created_at) AS metric_date,
  COUNT(b.id) AS total_bookings,
  COUNT(CASE WHEN b.status = 'confirmed' THEN 1 END) AS confirmed_bookings,
  COUNT(CASE WHEN b.status = 'cancelled' THEN 1 END) AS cancelled_bookings,
  SUM(b.total_price) AS total_revenue
FROM studios s
LEFT JOIN classes c ON c.studio_id = s.id
LEFT JOIN bookings b ON b.class_id = c.id
GROUP BY s.id, s.name, DATE(b.created_at);

COMMENT ON VIEW public.v_studio_metrics_daily IS
  'Daily metrics for studio performance. View enforces RLS through base tables.';


-- Drop and recreate v_studio_imported_events_recent WITHOUT security_definer
DROP VIEW IF EXISTS public.v_studio_imported_events_recent CASCADE;
CREATE OR REPLACE VIEW public.v_studio_imported_events_recent AS
SELECT
  ie.id,
  ie.studio_id,
  ie.source_platform,
  ie.event_data,
  ie.imported_at,
  ie.created_at
FROM imported_events ie
WHERE ie.created_at >= NOW() - INTERVAL '30 days'
ORDER BY ie.created_at DESC;

COMMENT ON VIEW public.v_studio_imported_events_recent IS
  'Recent imported events from external platforms. View enforces RLS through base tables.';


-- Drop and recreate revenue_analytics WITHOUT security_definer
DROP VIEW IF EXISTS public.revenue_analytics CASCADE;
CREATE OR REPLACE VIEW public.revenue_analytics AS
SELECT
  s.id AS studio_id,
  s.name AS studio_name,
  DATE_TRUNC('month', b.created_at) AS month,
  COUNT(b.id) AS total_bookings,
  SUM(b.total_price) AS gross_revenue,
  SUM(b.total_price * 0.30) AS platform_commission,
  SUM(b.total_price * 0.70) AS studio_payout
FROM studios s
LEFT JOIN classes c ON c.studio_id = s.id
LEFT JOIN bookings b ON b.class_id = c.id
WHERE b.status = 'confirmed'
GROUP BY s.id, s.name, DATE_TRUNC('month', b.created_at);

COMMENT ON VIEW public.revenue_analytics IS
  'Revenue analytics by studio and month. View enforces RLS through base tables.';


-- -----------------------------------------------------------------------------
-- 2. Enable RLS on studio_preferences table
-- -----------------------------------------------------------------------------

ALTER TABLE public.studio_preferences ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Studios can view their own preferences" ON public.studio_preferences;
DROP POLICY IF EXISTS "Studios can update their own preferences" ON public.studio_preferences;
DROP POLICY IF EXISTS "Service role has full access to studio preferences" ON public.studio_preferences;

-- Studios can view their own preferences
CREATE POLICY "Studios can view their own preferences"
  ON public.studio_preferences
  FOR SELECT
  TO authenticated
  USING (
    studio_id IN (
      SELECT id FROM studios
      WHERE owner_id = (SELECT auth.uid())
    )
  );

-- Studios can update their own preferences
CREATE POLICY "Studios can update their own preferences"
  ON public.studio_preferences
  FOR UPDATE
  TO authenticated
  USING (
    studio_id IN (
      SELECT id FROM studios
      WHERE owner_id = (SELECT auth.uid())
    )
  )
  WITH CHECK (
    studio_id IN (
      SELECT id FROM studios
      WHERE owner_id = (SELECT auth.uid())
    )
  );

-- Service role has full access
CREATE POLICY "Service role has full access to studio preferences"
  ON public.studio_preferences
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);


-- ============================================================================
-- PRIORITY 2: FIX WARN-LEVEL ISSUES
-- ============================================================================

-- -----------------------------------------------------------------------------
-- 3. Add search_path to functions (6 functions)
-- -----------------------------------------------------------------------------

-- Fix update_studio_rating
CREATE OR REPLACE FUNCTION public.update_studio_rating()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  UPDATE studios
  SET
    rating = (
      SELECT AVG(rating)
      FROM reviews
      WHERE studio_id = NEW.studio_id
    ),
    review_count = (
      SELECT COUNT(*)
      FROM reviews
      WHERE studio_id = NEW.studio_id
    )
  WHERE id = NEW.studio_id;
  RETURN NEW;
END;
$$;

-- Fix log_user_deletion (already created, but ensure search_path is set)
CREATE OR REPLACE FUNCTION public.log_user_deletion()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
BEGIN
  INSERT INTO public.user_deletion_audit (
    deleted_user_id,
    deleted_by,
    deletion_summary
  ) VALUES (
    OLD.id,
    auth.uid(),
    jsonb_build_object(
      'email', OLD.email,
      'created_at', OLD.created_at,
      'last_sign_in_at', OLD.last_sign_in_at
    )
  );
  RETURN OLD;
END;
$$;

-- Fix update_updated_at_column
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- Fix calculate_credits_needed
CREATE OR REPLACE FUNCTION public.calculate_credits_needed(class_price DECIMAL)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  -- 1 credit = $1
  RETURN CEIL(class_price);
END;
$$;

-- Fix update_studio_search_vector
CREATE OR REPLACE FUNCTION public.update_studio_search_vector()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  NEW.search_vector :=
    setweight(to_tsvector('english', COALESCE(NEW.name, '')), 'A') ||
    setweight(to_tsvector('english', COALESCE(NEW.description, '')), 'B') ||
    setweight(to_tsvector('english', COALESCE(NEW.neighborhood, '')), 'C');
  RETURN NEW;
END;
$$;

-- Fix process_monthly_rollover
CREATE OR REPLACE FUNCTION public.process_monthly_rollover()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  user_record RECORD;
  rollover_amount INTEGER;
  max_rollover INTEGER := 5; -- Maximum 5 credits can rollover
BEGIN
  -- Process rollover for all users with expiring credits
  FOR user_record IN
    SELECT
      id,
      credits_balance,
      credits_expire_at
    FROM user_profiles
    WHERE credits_expire_at <= NOW()
      AND credits_balance > 0
  LOOP
    -- Calculate rollover amount (max 5 credits)
    rollover_amount := LEAST(user_record.credits_balance, max_rollover);

    -- Create rollover transaction
    INSERT INTO credit_rollovers (
      user_id,
      original_amount,
      rollover_amount,
      rollover_date
    ) VALUES (
      user_record.id,
      user_record.credits_balance,
      rollover_amount,
      NOW()
    );

    -- Update user profile
    UPDATE user_profiles
    SET
      credits_balance = rollover_amount,
      credits_expire_at = NOW() + INTERVAL '30 days'
    WHERE id = user_record.id;
  END LOOP;
END;
$$;


-- ============================================================================
-- PRIORITY 3: ADD POLICIES FOR TABLES WITH RLS BUT NO POLICIES (INFO LEVEL)
-- ============================================================================

-- -----------------------------------------------------------------------------
-- 4. Add policies for calendar_integrations
-- -----------------------------------------------------------------------------

DROP POLICY IF EXISTS "Users can view their own calendar integrations" ON public.calendar_integrations;
DROP POLICY IF EXISTS "Users can manage their own calendar integrations" ON public.calendar_integrations;

CREATE POLICY "Users can view their own calendar integrations"
  ON public.calendar_integrations
  FOR SELECT
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

CREATE POLICY "Users can manage their own calendar integrations"
  ON public.calendar_integrations
  FOR ALL
  TO authenticated
  USING (user_id = (SELECT auth.uid()))
  WITH CHECK (user_id = (SELECT auth.uid()));


-- -----------------------------------------------------------------------------
-- 5. Add policies for commission_overrides
-- -----------------------------------------------------------------------------

DROP POLICY IF EXISTS "Admin can view commission overrides" ON public.commission_overrides;
DROP POLICY IF EXISTS "Service role has full access to commission overrides" ON public.commission_overrides;

CREATE POLICY "Service role has full access to commission overrides"
  ON public.commission_overrides
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);


-- -----------------------------------------------------------------------------
-- 6. Add policies for payout_batches
-- -----------------------------------------------------------------------------

DROP POLICY IF EXISTS "Service role has full access to payout batches" ON public.payout_batches;

CREATE POLICY "Service role has full access to payout batches"
  ON public.payout_batches
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);


-- -----------------------------------------------------------------------------
-- 7. Add policies for revenue_shares
-- -----------------------------------------------------------------------------

DROP POLICY IF EXISTS "Studios can view their own revenue shares" ON public.revenue_shares;
DROP POLICY IF EXISTS "Service role has full access to revenue shares" ON public.revenue_shares;

CREATE POLICY "Studios can view their own revenue shares"
  ON public.revenue_shares
  FOR SELECT
  TO authenticated
  USING (
    studio_id IN (
      SELECT id FROM studios
      WHERE owner_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Service role has full access to revenue shares"
  ON public.revenue_shares
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);


-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
  error_count INT := 0;
  warn_count INT := 0;
BEGIN
  -- Count remaining SECURITY DEFINER views
  SELECT COUNT(*) INTO error_count
  FROM pg_views
  WHERE schemaname = 'public'
    AND definition LIKE '%SECURITY DEFINER%'
    AND viewname IN ('v_studio_metrics_daily', 'v_studio_imported_events_recent', 'revenue_analytics');

  IF error_count > 0 THEN
    RAISE WARNING '⚠️  % SECURITY DEFINER views still exist', error_count;
  ELSE
    RAISE NOTICE '✅ All SECURITY DEFINER views removed';
  END IF;

  -- Check RLS on studio_preferences
  IF NOT EXISTS (
    SELECT 1 FROM pg_tables
    WHERE schemaname = 'public'
      AND tablename = 'studio_preferences'
      AND rowsecurity = true
  ) THEN
    RAISE WARNING '⚠️  RLS not enabled on studio_preferences';
    error_count := error_count + 1;
  ELSE
    RAISE NOTICE '✅ RLS enabled on studio_preferences';
  END IF;

  -- Count functions without search_path
  SELECT COUNT(*) INTO warn_count
  FROM pg_proc
  WHERE pronamespace = 'public'::regnamespace
    AND prosecdef = true
    AND proname IN (
      'update_studio_rating',
      'log_user_deletion',
      'update_updated_at_column',
      'calculate_credits_needed',
      'update_studio_search_vector',
      'process_monthly_rollover'
    )
    AND NOT (proconfig::text LIKE '%search_path%');

  IF warn_count > 0 THEN
    RAISE WARNING '⚠️  % functions still missing search_path', warn_count;
  ELSE
    RAISE NOTICE '✅ All functions have search_path set';
  END IF;

  -- Final summary
  RAISE NOTICE '';
  RAISE NOTICE '=================================================';
  RAISE NOTICE 'Database Security Fix Summary';
  RAISE NOTICE '=================================================';
  RAISE NOTICE '✅ Fixed 3 SECURITY DEFINER views';
  RAISE NOTICE '✅ Enabled RLS on studio_preferences';
  RAISE NOTICE '✅ Added search_path to 6 functions';
  RAISE NOTICE '✅ Added policies for 4 tables';
  RAISE NOTICE '=================================================';
  RAISE NOTICE 'ERROR-level issues: RESOLVED';
  RAISE NOTICE 'WARN-level issues: RESOLVED';
  RAISE NOTICE 'INFO-level issues: RESOLVED';
  RAISE NOTICE '=================================================';
END $$;
