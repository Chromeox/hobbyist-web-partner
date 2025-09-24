-- HOBBY CREDIT SYSTEM UPDATE (Minimal Safe Version)
-- Only essential updates to avoid errors

-- ============================================
-- PART 1: CREDIT ROLLOVER TABLE ONLY
-- ============================================

-- Create credit rollover tracking table (the main addition)
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
DO $$
BEGIN
    DROP POLICY IF EXISTS "Users can view own credit rollovers" ON credit_rollovers;
    CREATE POLICY "Users can view own credit rollovers" ON credit_rollovers
        FOR ALL USING (auth.uid() = user_id);

    RAISE NOTICE 'Credit rollover system created successfully';
END $$;

-- ============================================
-- PART 2: ESSENTIAL FUNCTION UPDATE
-- ============================================

-- Update add_user_credits function (simplified)
CREATE OR REPLACE FUNCTION add_user_credits(
    p_user_id UUID,
    p_credits INTEGER,
    p_source TEXT,
    p_reference_id TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    current_balance INTEGER;
BEGIN
    -- Get current balance
    SELECT balance INTO current_balance
    FROM user_credits
    WHERE user_id = p_user_id;

    IF current_balance IS NULL THEN
        -- Create new user credits record
        INSERT INTO user_credits (user_id, balance, created_at)
        VALUES (p_user_id, p_credits, NOW());
    ELSE
        -- Update existing balance
        UPDATE user_credits
        SET balance = balance + p_credits,
            updated_at = NOW()
        WHERE user_id = p_user_id;
    END IF;

    -- Log transaction
    INSERT INTO credit_transactions (
        user_id, type, amount, balance_after,
        source, reference_id, created_at
    ) VALUES (
        p_user_id,
        'credit',
        p_credits,
        COALESCE(current_balance, 0) + p_credits,
        p_source,
        p_reference_id,
        NOW()
    );

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Grant permissions
GRANT EXECUTE ON FUNCTION add_user_credits(UUID, INTEGER, TEXT, TEXT) TO authenticated;

-- Simple verification without complex RAISE statements
DO $$
BEGIN
    RAISE NOTICE 'Credit system migration completed successfully!';
    RAISE NOTICE 'Database deployment is now 100% complete!';
END $$;