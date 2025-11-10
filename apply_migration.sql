-- Check if approval_status column already exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'studios' AND column_name = 'approval_status'
    ) THEN
        -- Run the migration
        \i supabase/migrations/20251110145828_studio_approval_workflow.sql
    ELSE
        RAISE NOTICE 'approval_status column already exists - skipping migration';
    END IF;
END $$;
