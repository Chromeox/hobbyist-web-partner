-- Student Features Migration
-- Adds tables and columns needed for enhanced student functionality

-- Student preferences for personalized recommendations
CREATE TABLE student_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    preferred_categories TEXT[] DEFAULT '{}',
    preferred_difficulty_levels TEXT[] DEFAULT '{}',
    preferred_price_range JSONB DEFAULT '{"min": 0, "max": 1000}'::JSONB,
    preferred_times TEXT[] DEFAULT '{}', -- morning, afternoon, evening, weekend
    preferred_locations TEXT[] DEFAULT '{}',
    max_travel_distance INTEGER DEFAULT 50, -- in km
    notifications_enabled BOOLEAN DEFAULT true,
    email_reminders BOOLEAN DEFAULT true,
    sms_reminders BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Saved/bookmarked classes for later viewing
CREATE TABLE saved_classes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    saved_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notes TEXT,
    UNIQUE(user_id, class_id)
);

-- Class reminders and calendar sync
CREATE TABLE class_reminders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    reminder_type VARCHAR(50) NOT NULL CHECK (reminder_type IN ('email', 'sms', 'push', 'calendar')),
    reminder_time TIMESTAMP WITH TIME ZONE NOT NULL,
    sent BOOLEAN DEFAULT false,
    sent_at TIMESTAMP WITH TIME ZONE,
    message_id TEXT, -- for tracking external notifications
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Instructor following system
CREATE TABLE instructor_follows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    instructor_id UUID NOT NULL REFERENCES instructors(id) ON DELETE CASCADE,
    followed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notifications_enabled BOOLEAN DEFAULT true,
    UNIQUE(student_id, instructor_id)
);

-- Waitlist entries for fully booked classes
CREATE TABLE class_waitlists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    session_id UUID, -- for specific session waitlist
    position INTEGER NOT NULL,
    auto_book BOOLEAN DEFAULT false,
    max_price DECIMAL(10,2), -- maximum willing to pay if price changes
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notified_at TIMESTAMP WITH TIME ZONE,
    expired_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(user_id, class_id, session_id)
);

-- Class sessions for recurring/scheduled classes
CREATE TABLE class_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    max_participants INTEGER NOT NULL,
    current_participants INTEGER DEFAULT 0,
    price_override DECIMAL(10,2), -- override class base price for this session
    location_override TEXT, -- override class location
    notes TEXT,
    status VARCHAR(50) DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'cancelled', 'completed', 'in_progress')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Student activity/engagement tracking
CREATE TABLE student_activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    activity_type VARCHAR(50) NOT NULL CHECK (activity_type IN ('view_class', 'save_class', 'book_class', 'cancel_booking', 'leave_review', 'follow_instructor', 'search', 'share_class')),
    target_id UUID, -- class_id, instructor_id, etc.
    target_type VARCHAR(50), -- 'class', 'instructor', 'search', etc.
    metadata JSONB DEFAULT '{}'::JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Recommendation engine data
CREATE TABLE class_recommendations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    recommendation_type VARCHAR(50) NOT NULL CHECK (recommendation_type IN ('similar_classes', 'followed_instructors', 'popular_in_category', 'location_based', 'price_based', 'trending')),
    score DECIMAL(5,4) NOT NULL DEFAULT 0.0,
    reason TEXT,
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    clicked BOOLEAN DEFAULT false,
    clicked_at TIMESTAMP WITH TIME ZONE,
    booked BOOLEAN DEFAULT false,
    booked_at TIMESTAMP WITH TIME ZONE
);

-- Add indexes for performance
CREATE INDEX idx_student_preferences_user_id ON student_preferences(user_id);
CREATE INDEX idx_saved_classes_user_id ON saved_classes(user_id);
CREATE INDEX idx_saved_classes_class_id ON saved_classes(class_id);
CREATE INDEX idx_class_reminders_user_id ON class_reminders(user_id);
CREATE INDEX idx_class_reminders_booking_id ON class_reminders(booking_id);
CREATE INDEX idx_class_reminders_reminder_time ON class_reminders(reminder_time) WHERE NOT sent;
CREATE INDEX idx_instructor_follows_student_id ON instructor_follows(student_id);
CREATE INDEX idx_instructor_follows_instructor_id ON instructor_follows(instructor_id);
CREATE INDEX idx_class_waitlists_user_id ON class_waitlists(user_id);
CREATE INDEX idx_class_waitlists_class_id ON class_waitlists(class_id);
CREATE INDEX idx_class_waitlists_position ON class_waitlists(position);
CREATE INDEX idx_class_sessions_class_id ON class_sessions(class_id);
CREATE INDEX idx_class_sessions_start_time ON class_sessions(start_time);
CREATE INDEX idx_student_activities_user_id ON student_activities(user_id);
CREATE INDEX idx_student_activities_created_at ON student_activities(created_at);
CREATE INDEX idx_class_recommendations_user_id ON class_recommendations(user_id);
CREATE INDEX idx_class_recommendations_score ON class_recommendations(score DESC);

-- Update triggers for timestamp fields
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_student_preferences_updated_at BEFORE UPDATE ON student_preferences FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_class_sessions_updated_at BEFORE UPDATE ON class_sessions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to update waitlist positions when someone leaves
CREATE OR REPLACE FUNCTION update_waitlist_positions()
RETURNS TRIGGER AS $$
BEGIN
    -- When someone is removed from waitlist, update positions
    IF TG_OP = 'DELETE' THEN
        UPDATE class_waitlists 
        SET position = position - 1 
        WHERE class_id = OLD.class_id 
        AND session_id = OLD.session_id 
        AND position > OLD.position;
        RETURN OLD;
    END IF;
    
    -- When someone is added to waitlist, set their position
    IF TG_OP = 'INSERT' THEN
        NEW.position := COALESCE(
            (SELECT MAX(position) + 1 FROM class_waitlists 
             WHERE class_id = NEW.class_id AND session_id = NEW.session_id), 
            1
        );
        RETURN NEW;
    END IF;
    
    RETURN NULL;
END;
$$ language 'plpgsql';

CREATE TRIGGER manage_waitlist_positions
    BEFORE INSERT OR DELETE ON class_waitlists
    FOR EACH ROW EXECUTE FUNCTION update_waitlist_positions();

-- Add some sample data for development
INSERT INTO student_preferences (user_id, preferred_categories, preferred_difficulty_levels, preferred_times) 
VALUES 
    ((SELECT id FROM users WHERE email = 'demo@hobbyist.com' LIMIT 1), 
     ARRAY['pottery', 'painting'], 
     ARRAY['beginner', 'intermediate'], 
     ARRAY['evening', 'weekend']);

-- Grant permissions
GRANT ALL ON student_preferences TO authenticated;
GRANT ALL ON saved_classes TO authenticated;
GRANT ALL ON class_reminders TO authenticated;
GRANT ALL ON instructor_follows TO authenticated;
GRANT ALL ON class_waitlists TO authenticated;
GRANT ALL ON class_sessions TO authenticated;
GRANT ALL ON student_activities TO authenticated;
GRANT ALL ON class_recommendations TO authenticated;

-- Row Level Security (RLS) policies
ALTER TABLE student_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE saved_classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE instructor_follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_waitlists ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_recommendations ENABLE ROW LEVEL SECURITY;

-- Users can only access their own data
CREATE POLICY "Users can manage their own preferences" ON student_preferences FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage their own saved classes" ON saved_classes FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage their own reminders" ON class_reminders FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage their own follows" ON instructor_follows FOR ALL USING (auth.uid() = student_id);
CREATE POLICY "Users can manage their own waitlist entries" ON class_waitlists FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can view class sessions" ON class_sessions FOR SELECT USING (true);
CREATE POLICY "Instructors can manage their class sessions" ON class_sessions FOR ALL USING (
    EXISTS (
        SELECT 1 FROM classes c 
        JOIN instructors i ON c.instructor_id = i.id 
        WHERE c.id = class_sessions.class_id 
        AND i.user_id = auth.uid()
    )
);
CREATE POLICY "Users can manage their own activities" ON student_activities FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can view their own recommendations" ON class_recommendations FOR SELECT USING (auth.uid() = user_id);