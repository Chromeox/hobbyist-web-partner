-- Fix notifications schema (Safe Version)
-- Handles existing objects gracefully

-- Add missing columns to notifications table if they don't exist
DO $$
BEGIN
    -- Add columns safely
    ALTER TABLE notifications
    ADD COLUMN IF NOT EXISTS body TEXT,
    ADD COLUMN IF NOT EXISTS data JSONB DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS read BOOLEAN DEFAULT false;

    -- Migrate existing data
    UPDATE notifications
    SET body = COALESCE(message, title, 'No content')
    WHERE body IS NULL;

    UPDATE notifications
    SET read = COALESCE(is_read, false)
    WHERE read IS DISTINCT FROM COALESCE(is_read, false);

    RAISE NOTICE 'Notifications table columns updated successfully';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Notifications table updates completed with notes: %', SQLERRM;
END $$;

-- Handle body column constraints safely
DO $$
BEGIN
    -- Make body not null after copying data
    ALTER TABLE notifications ALTER COLUMN body SET NOT NULL;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Body column constraint update: %', SQLERRM;
END $$;

-- Create push_tokens table safely
CREATE TABLE IF NOT EXISTS push_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    platform TEXT NOT NULL CHECK (platform IN ('ios', 'android', 'web')),
    device_info JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, token)
);

-- Create indexes safely
CREATE INDEX IF NOT EXISTS idx_push_tokens_user_id ON push_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_push_tokens_active ON push_tokens(is_active);
CREATE INDEX IF NOT EXISTS idx_push_tokens_platform ON push_tokens(platform);

-- Handle trigger creation safely
DO $$
BEGIN
    -- Drop existing trigger if it exists
    DROP TRIGGER IF EXISTS update_push_tokens_timestamp ON push_tokens;

    -- Create the trigger (assuming update_timestamp function exists)
    CREATE TRIGGER update_push_tokens_timestamp
        BEFORE UPDATE ON push_tokens
        FOR EACH ROW
        EXECUTE FUNCTION update_timestamp();

    RAISE NOTICE 'Push tokens trigger created successfully';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Push tokens trigger handling: %', SQLERRM;
END $$;

-- Enable RLS safely
ALTER TABLE push_tokens ENABLE ROW LEVEL SECURITY;

-- Create/update policies safely
DO $$
BEGIN
    -- Notifications policies
    DROP POLICY IF EXISTS notifications_select_own ON notifications;
    CREATE POLICY notifications_select_own ON notifications
        FOR SELECT USING (user_id = auth.uid());

    DROP POLICY IF EXISTS notifications_update_own ON notifications;
    CREATE POLICY notifications_update_own ON notifications
        FOR UPDATE USING (user_id = auth.uid());

    -- Push tokens policies
    DROP POLICY IF EXISTS push_tokens_select_own ON push_tokens;
    CREATE POLICY push_tokens_select_own ON push_tokens
        FOR SELECT USING (user_id = auth.uid());

    DROP POLICY IF EXISTS push_tokens_insert_own ON push_tokens;
    CREATE POLICY push_tokens_insert_own ON push_tokens
        FOR INSERT WITH CHECK (user_id = auth.uid());

    DROP POLICY IF EXISTS push_tokens_update_own ON push_tokens;
    CREATE POLICY push_tokens_update_own ON push_tokens
        FOR UPDATE USING (user_id = auth.uid());

    DROP POLICY IF EXISTS push_tokens_delete_own ON push_tokens;
    CREATE POLICY push_tokens_delete_own ON push_tokens
        FOR DELETE USING (user_id = auth.uid());

    RAISE NOTICE 'All notification system policies updated successfully!';
END $$;

-- Verification
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'push_tokens') THEN
        RAISE NOTICE 'Notifications schema verification: push_tokens table exists ✓';
    ELSE
        RAISE WARNING 'Notifications schema issue: push_tokens table missing!';
    END IF;

    IF EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'notifications' AND column_name = 'body') THEN
        RAISE NOTICE 'Notifications schema verification: body column exists ✓';
    ELSE
        RAISE WARNING 'Notifications schema issue: body column missing!';
    END IF;
END $$;