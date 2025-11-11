-- Fix remaining function without search_path
-- The second overload of calculate_credits_needed needs search_path

-- Drop and recreate the function with search_path
CREATE OR REPLACE FUNCTION public.calculate_credits_needed(
  p_class_id uuid,
  p_schedule_time timestamp with time zone
)
RETURNS numeric
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
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
    SELECT COALESCE(MAX(credit_multiplier), 1.0) INTO v_multiplier
    FROM dynamic_pricing_rules
    WHERE is_active = true
    AND (
        (rule_type = 'time_based'
         AND start_time <= p_schedule_time::TIME
         AND end_time >= p_schedule_time::TIME
         AND EXTRACT(DOW FROM p_schedule_time) = ANY(days_of_week))
        OR
        (rule_type = 'seasonal'
         AND EXTRACT(MONTH FROM p_schedule_time) = ANY(months))
    )
    ORDER BY priority DESC
    LIMIT 1;

    v_final_credits := v_base_credits * v_multiplier;

    RETURN ROUND(v_final_credits, 1);
END;
$$;

-- Verify all functions now have search_path
DO $$
DECLARE
  missing_count INT;
BEGIN
  SELECT COUNT(*) INTO missing_count
  FROM pg_proc
  WHERE pronamespace = 'public'::regnamespace
    AND prosecdef = true
    AND NOT (proconfig::text LIKE '%search_path%');

  IF missing_count = 0 THEN
    RAISE NOTICE '✅ All SECURITY DEFINER functions now have search_path set';
  ELSE
    RAISE WARNING '⚠️  Still % functions without search_path', missing_count;
  END IF;
END $$;
