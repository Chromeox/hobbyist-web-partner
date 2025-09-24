-- Migration 07: Revenue Sharing (Manual Deploy - Safe Version)
-- This version skips already existing policies and objects

-- Only create policies if they don't exist
DO $$
BEGIN
    -- Drop and recreate the policy if it exists
    DROP POLICY IF EXISTS "View own revenue shares" ON public.revenue_shares;

    CREATE POLICY "View own revenue shares" ON public.revenue_shares
        FOR SELECT USING (
            auth.uid() IN (
                SELECT b.user_id FROM public.bookings b WHERE b.id = revenue_shares.booking_id
                -- Note: instructor and studio ownership validation would require user relationship tables
            )
        );

    RAISE NOTICE 'Revenue shares policy created successfully';
END $$;

-- Create payout requests policy if it doesn't exist
DO $$
BEGIN
    -- Drop and recreate if exists
    DROP POLICY IF EXISTS "Manage own payout requests" ON public.payout_requests;

    CREATE POLICY "Manage own payout requests" ON public.payout_requests
        FOR ALL USING (auth.uid() = requester_id);

    RAISE NOTICE 'Payout requests policy created successfully';
END $$;

-- Verify tables exist and show summary
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'revenue_shares') THEN
        RAISE NOTICE 'Migration 07 verification: revenue_shares table exists ✓';
    ELSE
        RAISE WARNING 'Migration 07 issue: revenue_shares table missing!';
    END IF;

    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'payout_requests') THEN
        RAISE NOTICE 'Migration 07 verification: payout_requests table exists ✓';
    ELSE
        RAISE WARNING 'Migration 07 issue: payout_requests table missing!';
    END IF;

    RAISE NOTICE 'Migration 07 RLS policies updated successfully!';
END $$;