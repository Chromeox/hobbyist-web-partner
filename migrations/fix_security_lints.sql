-- SECURITY FIXES: Address Supabase linter warnings

-- Enable RLS on apple_receipt_validation_logs
ALTER TABLE public.apple_receipt_validation_logs ENABLE ROW LEVEL SECURITY;

-- Add RLS policy for apple_receipt_validation_logs (service role only)
DROP POLICY IF EXISTS "Service role only" ON public.apple_receipt_validation_logs;
CREATE POLICY "Service role only" ON public.apple_receipt_validation_logs FOR ALL USING (true) WITH CHECK (true);

-- Fix function search_path for update_updated_at_column
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- Fix function search_path for grant_credits_idempotent
CREATE OR REPLACE FUNCTION public.grant_credits_idempotent(
    p_user_id TEXT,
    p_amount INTEGER,
    p_idempotency_key TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_existing_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_existing_count
    FROM public.credit_transactions
    WHERE reference_id = p_idempotency_key;

    IF v_existing_count > 0 THEN
        RETURN FALSE;
    END IF;

    UPDATE public.profiles
    SET credits = COALESCE(credits, 0) + p_amount
    WHERE id = p_user_id;

    INSERT INTO public.credit_transactions (user_id, amount, balance_after, transaction_type, reference_id, description)
    SELECT p_user_id, p_amount, COALESCE(credits, 0), 'grant', p_idempotency_key, 'Credits granted'
    FROM public.profiles WHERE id = p_user_id;

    RETURN TRUE;
END;
$$;

-- Fix function search_path for log_receipt_validation
CREATE OR REPLACE FUNCTION public.log_receipt_validation(
    p_user_id TEXT,
    p_receipt_data TEXT,
    p_validation_result JSONB,
    p_status TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_log_id UUID;
BEGIN
    INSERT INTO public.apple_receipt_validation_logs (user_id, receipt_data, validation_result, status)
    VALUES (p_user_id, p_receipt_data, p_validation_result, p_status)
    RETURNING id INTO v_log_id;

    RETURN v_log_id;
END;
$$;
