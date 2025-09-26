-- HOBBY CREDIT SYSTEM UPDATE (Clean Version - No RAISE Statements)
-- Fixed all column name typos and removed problematic RAISE statements

-- ============================================
-- PART 1: CREDIT ROLLOVER TABLE ONLY
-- ============================================

-- Create credit rollover tracking table
CREATE TABLE IF NOT EXISTS credit_rollovers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    original_credits INTEGER NOT NULL,
    rolled_over_credits INTEGER NOT NULL,
    rollover_date DATE NOT NULL,
    expires_at DATE NOT NULL,
    rollover_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_credit_rollovers_user_id ON credit_rollovers(user_id);
CREATE INDEX IF NOT EXISTS idx_credit_rollovers_expires ON credit_rollovers(expires_at);

-- Enable RLS
ALTER TABLE credit_rollovers ENABLE ROW LEVEL SECURITY;

-- Create RLS Policy safely
DROP POLICY IF EXISTS "Users can view own credit rollovers" ON credit_rollovers;
CREATE POLICY "Users can view own credit rollovers" ON credit_rollovers
    FOR ALL USING (auth.uid() = user_id);

-- ============================================
-- PART 2: CORRECTED FUNCTION
-- ============================================

-- Update add_user_credits function with correct column names
CREATE OR REPLACE FUNCTION add_user_credits(
    p_user_id UUID,
    p_credits INTEGER,
    p_source TEXT,
    p_reference_id TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    current_total INTEGER;
    current_used INTEGER;
BEGIN
    -- Get current credits using actual column names
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

    -- Log transaction using correct column names
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
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Grant permissions
GRANT EXECUTE ON FUNCTION add_user_credits(UUID, INTEGER, TEXT, TEXT) TO authenticated;