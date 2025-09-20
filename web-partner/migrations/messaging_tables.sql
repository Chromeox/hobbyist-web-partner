-- Real-time Messaging Tables for Instructor ↔ Studio Communication
-- Created for HobbyistSwiftUI Partner Portal

-- Enable realtime for messaging
DROP PUBLICATION IF EXISTS supabase_realtime;
CREATE PUBLICATION supabase_realtime;

-- Conversations table
CREATE TABLE IF NOT EXISTS conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    studio_id UUID REFERENCES users(id), -- Studio user who manages the conversation
    instructor_id UUID NOT NULL REFERENCES instructors(id), -- Instructor involved in conversation
    type TEXT NOT NULL CHECK (type IN ('individual', 'group')) DEFAULT 'individual',
    name TEXT NOT NULL, -- Display name for conversation
    participants UUID[] NOT NULL DEFAULT '{}', -- Array of user IDs in conversation
    last_message TEXT, -- Preview of most recent message
    last_message_at TIMESTAMP WITH TIME ZONE, -- When last message was sent
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Messages table
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id), -- Who sent the message
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

CREATE TRIGGER update_conversations_updated_at
    BEFORE UPDATE ON conversations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

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

CREATE TRIGGER update_conversation_on_new_message
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_conversation_last_message();

-- Row Level Security (RLS)
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Conversations: Users can see conversations they participate in
CREATE POLICY "Users can view conversations they participate in" ON conversations
    FOR SELECT USING (
        auth.uid() = studio_id OR
        auth.uid() = instructor_id OR
        auth.uid() = ANY(participants)
    );

-- Conversations: Users can insert conversations if they're a participant
CREATE POLICY "Users can create conversations they participate in" ON conversations
    FOR INSERT WITH CHECK (
        auth.uid() = studio_id OR
        auth.uid() = instructor_id OR
        auth.uid() = ANY(participants)
    );

-- Conversations: Users can update conversations they participate in
CREATE POLICY "Users can update conversations they participate in" ON conversations
    FOR UPDATE USING (
        auth.uid() = studio_id OR
        auth.uid() = instructor_id OR
        auth.uid() = ANY(participants)
    );

-- Messages: Users can view messages in conversations they participate in
CREATE POLICY "Users can view messages in their conversations" ON messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM conversations
            WHERE conversations.id = messages.conversation_id
            AND (
                auth.uid() = conversations.studio_id OR
                auth.uid() = conversations.instructor_id OR
                auth.uid() = ANY(conversations.participants)
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
                auth.uid() = conversations.studio_id OR
                auth.uid() = conversations.instructor_id OR
                auth.uid() = ANY(conversations.participants)
            )
        )
    );

-- Messages: Users can update their own messages
CREATE POLICY "Users can update their own messages" ON messages
    FOR UPDATE USING (auth.uid() = sender_id);

-- Enable realtime for both tables
ALTER PUBLICATION supabase_realtime ADD TABLE conversations;
ALTER PUBLICATION supabase_realtime ADD TABLE messages;

-- Sample data for testing (remove in production)
-- This creates a conversation between a studio admin and instructor
INSERT INTO conversations (
    studio_id,
    instructor_id,
    type,
    name,
    participants
) VALUES (
    (SELECT id FROM users WHERE role = 'admin' LIMIT 1),
    (SELECT id FROM instructors LIMIT 1),
    'individual',
    'Instructor Communication',
    ARRAY[
        (SELECT id FROM users WHERE role = 'admin' LIMIT 1),
        (SELECT user_id FROM instructors LIMIT 1)
    ]
) ON CONFLICT DO NOTHING;

COMMENT ON TABLE conversations IS 'Conversations between studios and instructors for scheduling, payments, and coordination';
COMMENT ON TABLE messages IS 'Individual messages within conversations with real-time support';