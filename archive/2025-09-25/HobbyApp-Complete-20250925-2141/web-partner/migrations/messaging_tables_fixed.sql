-- Real-time Messaging Tables for Instructor ↔ Studio Communication
-- Compatible with Supabase auth.users system
-- Created for HobbyistSwiftUI Partner Portal

-- Enable realtime for messaging (safe to re-run)
DROP PUBLICATION IF EXISTS supabase_realtime;
CREATE PUBLICATION supabase_realtime;

-- Conversations table
CREATE TABLE IF NOT EXISTS conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    studio_id UUID, -- References auth.users(id) for studio user
    instructor_id TEXT NOT NULL, -- Can be UUID or string, flexible reference
    type TEXT NOT NULL CHECK (type IN ('individual', 'group')) DEFAULT 'individual',
    name TEXT NOT NULL, -- Display name for conversation
    participants TEXT[] NOT NULL DEFAULT '{}', -- Array of user IDs (flexible string format)
    last_message TEXT, -- Preview of most recent message
    last_message_at TIMESTAMP WITH TIME ZONE, -- When last message was sent
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Messages table
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id UUID, -- References auth.users(id) for message sender
    content TEXT NOT NULL, -- Message content
    attachments JSONB DEFAULT '[]', -- File attachments as JSON array
    read_at TIMESTAMP WITH TIME ZONE, -- When message was read (null = unread)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS conversations_instructor_id_idx ON conversations(instructor_id);
CREATE INDEX IF NOT EXISTS conversations_studio_id_idx ON conversations(studio_id);
CREATE INDEX IF NOT EXISTS conversations_last_message_at_idx ON conversations(last_message_at DESC);
CREATE INDEX IF NOT EXISTS messages_conversation_id_idx ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS messages_created_at_idx ON messages(created_at DESC);
CREATE INDEX IF NOT EXISTS messages_sender_id_idx ON messages(sender_id);

-- Updated at triggers
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_conversations_updated_at ON conversations;
CREATE TRIGGER update_conversations_updated_at
    BEFORE UPDATE ON conversations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_messages_updated_at ON messages;
CREATE TRIGGER update_messages_updated_at
    BEFORE UPDATE ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Function to update conversation last_message when new message is added
CREATE OR REPLACE FUNCTION update_conversation_last_message()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE conversations
    SET
        last_message = NEW.content,
        last_message_at = NEW.created_at,
        updated_at = NOW()
    WHERE id = NEW.conversation_id;
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_conversation_on_new_message ON messages;
CREATE TRIGGER update_conversation_on_new_message
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_conversation_last_message();

-- Row Level Security (RLS)
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Users can view conversations they participate in" ON conversations;
DROP POLICY IF EXISTS "Users can create conversations they participate in" ON conversations;
DROP POLICY IF EXISTS "Users can update conversations they participate in" ON conversations;
DROP POLICY IF EXISTS "Users can view messages in their conversations" ON messages;
DROP POLICY IF EXISTS "Users can send messages in their conversations" ON messages;
DROP POLICY IF EXISTS "Users can update their own messages" ON messages;

-- RLS Policies

-- Conversations: Users can see conversations they participate in
CREATE POLICY "Users can view conversations they participate in" ON conversations
    FOR SELECT USING (
        auth.uid()::text = studio_id::text OR
        auth.uid()::text = instructor_id OR
        auth.uid()::text = ANY(participants)
    );

-- Conversations: Users can insert conversations if they're a participant
CREATE POLICY "Users can create conversations they participate in" ON conversations
    FOR INSERT WITH CHECK (
        auth.uid()::text = studio_id::text OR
        auth.uid()::text = instructor_id OR
        auth.uid()::text = ANY(participants)
    );

-- Conversations: Users can update conversations they participate in
CREATE POLICY "Users can update conversations they participate in" ON conversations
    FOR UPDATE USING (
        auth.uid()::text = studio_id::text OR
        auth.uid()::text = instructor_id OR
        auth.uid()::text = ANY(participants)
    );

-- Messages: Users can view messages in conversations they participate in
CREATE POLICY "Users can view messages in their conversations" ON messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM conversations
            WHERE conversations.id = messages.conversation_id
            AND (
                auth.uid()::text = conversations.studio_id::text OR
                auth.uid()::text = conversations.instructor_id OR
                auth.uid()::text = ANY(conversations.participants)
            )
        )
    );

-- Messages: Users can insert messages in conversations they participate in
CREATE POLICY "Users can send messages in their conversations" ON messages
    FOR INSERT WITH CHECK (
        auth.uid() = sender_id AND
        EXISTS (
            SELECT 1 FROM conversations
            WHERE conversations.id = messages.conversation_id
            AND (
                auth.uid()::text = conversations.studio_id::text OR
                auth.uid()::text = conversations.instructor_id OR
                auth.uid()::text = ANY(conversations.participants)
            )
        )
    );

-- Messages: Users can update their own messages
CREATE POLICY "Users can update their own messages" ON messages
    FOR UPDATE USING (auth.uid() = sender_id);

-- Enable realtime for both tables
ALTER PUBLICATION supabase_realtime ADD TABLE conversations;
ALTER PUBLICATION supabase_realtime ADD TABLE messages;

-- Create a test conversation (safe - will only create if no conversations exist)
DO $$
BEGIN
    -- Only create test data if no conversations exist
    IF NOT EXISTS (SELECT 1 FROM conversations LIMIT 1) THEN
        -- Create a sample conversation for testing
        INSERT INTO conversations (
            studio_id,
            instructor_id,
            type,
            name,
            participants
        ) VALUES (
            (SELECT auth.uid()), -- Current authenticated user as studio
            'instructor-test-id', -- Placeholder instructor ID
            'individual',
            'Test Conversation - Welcome to Messaging!',
            ARRAY[auth.uid()::text, 'instructor-test-id']
        );

        -- Add a welcome message
        INSERT INTO messages (
            conversation_id,
            sender_id,
            content
        ) VALUES (
            (SELECT id FROM conversations WHERE name LIKE 'Test Conversation%' LIMIT 1),
            auth.uid(),
            'Welcome to the messaging system! This is a test conversation to verify everything is working correctly. You can safely delete this once you create your first real conversation with an instructor.'
        );
    END IF;
END $$;

-- Comments for documentation
COMMENT ON TABLE conversations IS 'Conversations between studios and instructors for scheduling, payments, and coordination';
COMMENT ON TABLE messages IS 'Individual messages within conversations with real-time support';

-- Success message
DO $$
BEGIN
    RAISE NOTICE '🎉 Messaging tables created successfully!';
    RAISE NOTICE '✅ Conversations table ready';
    RAISE NOTICE '✅ Messages table ready';
    RAISE NOTICE '✅ RLS policies enabled';
    RAISE NOTICE '✅ Real-time subscriptions active';
    RAISE NOTICE '🔗 Visit your dashboard to test: /dashboard/messages';
END $$;