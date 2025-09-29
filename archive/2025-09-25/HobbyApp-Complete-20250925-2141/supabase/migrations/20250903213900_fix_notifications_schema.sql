-- Fix notifications table schema for send-notification edge function
-- This migration ensures the notifications table has all required columns
-- and creates the missing push_tokens table

-- Add missing columns to notifications table if they don't exist
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

-- Make body not null after copying data
ALTER TABLE notifications ALTER COLUMN body SET NOT NULL;

-- Make message column nullable (legacy column)
ALTER TABLE notifications ALTER COLUMN message DROP NOT NULL;
ALTER TABLE notifications ALTER COLUMN message SET DEFAULT '';

-- Ensure user_id is not null
ALTER TABLE notifications ALTER COLUMN user_id SET NOT NULL;

-- Create push_tokens table for device registration
CREATE TABLE IF NOT EXISTS push_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    platform TEXT NOT NULL CHECK (platform IN ('ios', 'android', 'web')),
    device_info JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, token)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_push_tokens_user_id ON push_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_push_tokens_active ON push_tokens(is_active);
CREATE INDEX IF NOT EXISTS idx_push_tokens_platform ON push_tokens(platform);

-- Add timestamp trigger for push_tokens
CREATE TRIGGER update_push_tokens_timestamp 
    BEFORE UPDATE ON push_tokens 
    FOR EACH ROW 
    EXECUTE FUNCTION update_timestamp();

-- Enable RLS on push_tokens
ALTER TABLE push_tokens ENABLE ROW LEVEL SECURITY;

-- RLS policies for notifications
DROP POLICY IF EXISTS notifications_select_own ON notifications;
CREATE POLICY notifications_select_own ON notifications
    FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS notifications_update_own ON notifications;
CREATE POLICY notifications_update_own ON notifications
    FOR UPDATE USING (user_id = auth.uid());

-- RLS policies for push_tokens
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

-- Comment on the changes
COMMENT ON TABLE push_tokens IS 'Stores push notification tokens for user devices';
COMMENT ON COLUMN notifications.body IS 'Notification body text - replaces legacy message column';
COMMENT ON COLUMN notifications.data IS 'Additional data payload for notifications';
COMMENT ON COLUMN notifications.read IS 'Read status - replaces legacy is_read column';