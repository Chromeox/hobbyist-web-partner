-- Student Features Migration (Fixed)
-- Uses auth.users for foreign key references

-- Student preferences table
CREATE TABLE IF NOT EXISTS public.student_preferences (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    preferred_categories text[] DEFAULT '{}',
    preferred_times jsonb DEFAULT '{"morning": false, "afternoon": true, "evening": true}'::jsonb,
    preferred_locations uuid[] DEFAULT '{}',
    max_distance_km integer DEFAULT 10,
    skill_levels jsonb DEFAULT '{}'::jsonb,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    UNIQUE(user_id)
);

-- Saved classes for bookmarking
CREATE TABLE IF NOT EXISTS public.saved_classes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    class_id uuid NOT NULL REFERENCES public.classes(id) ON DELETE CASCADE,
    notes text,
    created_at timestamptz DEFAULT now(),
    UNIQUE(user_id, class_id)
);

-- Class reminders
CREATE TABLE IF NOT EXISTS public.class_reminders (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    booking_id uuid NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
    reminder_time timestamptz NOT NULL,
    reminder_type text CHECK (reminder_type IN ('email', 'sms', 'push', 'calendar')),
    sent boolean DEFAULT false,
    created_at timestamptz DEFAULT now()
);

-- Instructor follows
CREATE TABLE IF NOT EXISTS public.instructor_follows (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    instructor_id uuid NOT NULL REFERENCES public.instructors(id) ON DELETE CASCADE,
    notify_new_classes boolean DEFAULT true,
    notify_schedule_changes boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    UNIQUE(user_id, instructor_id)
);

-- Class waitlists
CREATE TABLE IF NOT EXISTS public.class_waitlists (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    class_id uuid NOT NULL REFERENCES public.classes(id) ON DELETE CASCADE,
    position integer NOT NULL,
    auto_book boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    UNIQUE(user_id, class_id)
);

-- Class sessions for recurring classes
CREATE TABLE IF NOT EXISTS public.class_sessions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    class_id uuid NOT NULL REFERENCES public.classes(id) ON DELETE CASCADE,
    start_time timestamptz NOT NULL,
    end_time timestamptz NOT NULL,
    capacity integer NOT NULL,
    booked_count integer DEFAULT 0,
    status text DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled')),
    created_at timestamptz DEFAULT now()
);

-- Student activities for tracking
CREATE TABLE IF NOT EXISTS public.student_activities (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    activity_type text NOT NULL CHECK (activity_type IN ('view', 'search', 'bookmark', 'share', 'review')),
    target_type text CHECK (target_type IN ('class', 'instructor', 'studio')),
    target_id uuid,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamptz DEFAULT now()
);

-- Class recommendations
CREATE TABLE IF NOT EXISTS public.class_recommendations (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    class_id uuid NOT NULL REFERENCES public.classes(id) ON DELETE CASCADE,
    score numeric(3,2) DEFAULT 0.00,
    reason text,
    algorithm_type text DEFAULT 'collaborative' CHECK (algorithm_type IN ('collaborative', 'content', 'hybrid', 'trending')),
    dismissed boolean DEFAULT false,
    created_at timestamptz DEFAULT now(),
    UNIQUE(user_id, class_id)
);

-- Enable RLS on all tables
ALTER TABLE public.student_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.class_reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.instructor_follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.class_waitlists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.class_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.class_recommendations ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can manage own preferences" ON public.student_preferences
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own saved classes" ON public.saved_classes
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own reminders" ON public.class_reminders
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own follows" ON public.instructor_follows
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view waitlists" ON public.class_waitlists
    FOR SELECT USING (true);

CREATE POLICY "Users can manage own waitlist entries" ON public.class_waitlists
    FOR INSERT USING (auth.uid() = user_id);
    
CREATE POLICY "Users can update own waitlist entries" ON public.class_waitlists
    FOR UPDATE USING (auth.uid() = user_id);
    
CREATE POLICY "Users can delete own waitlist entries" ON public.class_waitlists
    FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Anyone can view class sessions" ON public.class_sessions
    FOR SELECT USING (true);

CREATE POLICY "Studios can manage their sessions" ON public.class_sessions
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.classes c
            JOIN public.studios s ON c.studio_id = s.id
            WHERE c.id = class_sessions.class_id
            AND s.owner_id = auth.uid()
        )
    );

CREATE POLICY "Users can view own activities" ON public.student_activities
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own activities" ON public.student_activities
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own recommendations" ON public.class_recommendations
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "System can manage recommendations" ON public.class_recommendations
    FOR ALL USING (auth.uid() = user_id OR auth.uid() IS NULL);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_student_preferences_user_id ON public.student_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_saved_classes_user_id ON public.saved_classes(user_id);
CREATE INDEX IF NOT EXISTS idx_saved_classes_class_id ON public.saved_classes(class_id);
CREATE INDEX IF NOT EXISTS idx_class_reminders_user_id ON public.class_reminders(user_id);
CREATE INDEX IF NOT EXISTS idx_class_reminders_booking_id ON public.class_reminders(booking_id);
CREATE INDEX IF NOT EXISTS idx_instructor_follows_user_id ON public.instructor_follows(user_id);
CREATE INDEX IF NOT EXISTS idx_instructor_follows_instructor_id ON public.instructor_follows(instructor_id);
CREATE INDEX IF NOT EXISTS idx_waitlists_class_id ON public.class_waitlists(class_id);
CREATE INDEX IF NOT EXISTS idx_waitlists_user_id ON public.class_waitlists(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_class_id ON public.class_sessions(class_id);
CREATE INDEX IF NOT EXISTS idx_sessions_start_time ON public.class_sessions(start_time);
CREATE INDEX IF NOT EXISTS idx_activities_user_id ON public.student_activities(user_id);
CREATE INDEX IF NOT EXISTS idx_activities_created_at ON public.student_activities(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_recommendations_user_id ON public.class_recommendations(user_id);
CREATE INDEX IF NOT EXISTS idx_recommendations_score ON public.class_recommendations(score DESC);

-- Trigger to update waitlist positions when someone leaves
CREATE OR REPLACE FUNCTION update_waitlist_positions()
RETURNS TRIGGER AS $$
BEGIN
    -- Update positions for all users after the deleted position
    UPDATE public.class_waitlists
    SET position = position - 1
    WHERE class_id = OLD.class_id
    AND position > OLD.position;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_waitlist_positions_trigger
    AFTER DELETE ON public.class_waitlists
    FOR EACH ROW
    EXECUTE FUNCTION update_waitlist_positions();

-- Function to auto-enroll from waitlist
CREATE OR REPLACE FUNCTION auto_enroll_from_waitlist()
RETURNS TRIGGER AS $$
DECLARE
    waitlist_user_id uuid;
    waitlist_id uuid;
BEGIN
    -- Check if this is a cancellation
    IF TG_OP = 'DELETE' OR (TG_OP = 'UPDATE' AND NEW.status = 'cancelled') THEN
        -- Get the first person on the waitlist who has auto_book enabled
        SELECT w.user_id, w.id INTO waitlist_user_id, waitlist_id
        FROM public.class_waitlists w
        WHERE w.class_id = OLD.class_id
        AND w.auto_book = true
        ORDER BY w.position ASC
        LIMIT 1;
        
        IF waitlist_user_id IS NOT NULL THEN
            -- Create booking for waitlist user
            INSERT INTO public.bookings (user_id, class_id, status, created_at)
            VALUES (waitlist_user_id, OLD.class_id, 'confirmed', now());
            
            -- Remove from waitlist
            DELETE FROM public.class_waitlists WHERE id = waitlist_id;
            
            -- TODO: Send notification to user about auto-enrollment
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER auto_enroll_trigger
    AFTER DELETE OR UPDATE ON public.bookings
    FOR EACH ROW
    EXECUTE FUNCTION auto_enroll_from_waitlist();

-- Grant permissions
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;