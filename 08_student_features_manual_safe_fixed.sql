-- Migration 08: Student Features (Manual Deploy - Safe Version FIXED)
-- Fixed variable scoping issue

-- Student features tables are likely already created, so we'll focus on policies
DO $$
BEGIN
    -- Drop existing policies if they exist and recreate them

    -- Student preferences policies
    DROP POLICY IF EXISTS "Users can view own preferences" ON public.student_preferences;
    CREATE POLICY "Users can view own preferences" ON public.student_preferences
        FOR ALL USING (auth.uid() = user_id);

    -- Saved classes policies
    DROP POLICY IF EXISTS "Users can manage own saved classes" ON public.saved_classes;
    CREATE POLICY "Users can manage own saved classes" ON public.saved_classes
        FOR ALL USING (auth.uid() = user_id);

    -- Class reminders policies
    DROP POLICY IF EXISTS "Users can manage own reminders" ON public.class_reminders;
    CREATE POLICY "Users can manage own reminders" ON public.class_reminders
        FOR ALL USING (auth.uid() = user_id);

    -- Instructor follows policies
    DROP POLICY IF EXISTS "Users can manage own follows" ON public.instructor_follows;
    CREATE POLICY "Users can manage own follows" ON public.instructor_follows
        FOR ALL USING (auth.uid() = user_id);

    -- Class waitlists policies
    DROP POLICY IF EXISTS "Users can view waitlists" ON public.class_waitlists;
    CREATE POLICY "Users can view waitlists" ON public.class_waitlists
        FOR SELECT USING (true);

    DROP POLICY IF EXISTS "Users can manage own waitlist entries" ON public.class_waitlists;
    CREATE POLICY "Users can manage own waitlist entries" ON public.class_waitlists
        FOR INSERT WITH CHECK (auth.uid() = user_id);

    DROP POLICY IF EXISTS "Users can update own waitlist entries" ON public.class_waitlists;
    CREATE POLICY "Users can update own waitlist entries" ON public.class_waitlists
        FOR UPDATE USING (auth.uid() = user_id);

    DROP POLICY IF EXISTS "Users can delete own waitlist entries" ON public.class_waitlists;
    CREATE POLICY "Users can delete own waitlist entries" ON public.class_waitlists
        FOR DELETE USING (auth.uid() = user_id);

    -- Student activities policies
    DROP POLICY IF EXISTS "Users can view all activities" ON public.student_activities;
    CREATE POLICY "Users can view all activities" ON public.student_activities
        FOR SELECT USING (true);

    DROP POLICY IF EXISTS "System can create activities" ON public.student_activities;
    CREATE POLICY "System can create activities" ON public.student_activities
        FOR INSERT WITH CHECK (true);

    -- Class recommendations policies
    DROP POLICY IF EXISTS "Users can view recommendations" ON public.class_recommendations;
    CREATE POLICY "Users can view recommendations" ON public.class_recommendations
        FOR SELECT USING (auth.uid() = user_id);

    RAISE NOTICE 'Migration 08: All student feature policies updated successfully!';
END $$;

-- Verify key tables exist (FIXED variable scoping)
DO $$
DECLARE
    table_names TEXT[] := ARRAY['student_preferences', 'saved_classes', 'class_reminders', 'instructor_follows', 'class_waitlists'];
    tbl_name TEXT;
BEGIN
    FOREACH tbl_name IN ARRAY table_names
    LOOP
        IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = tbl_name) THEN
            RAISE NOTICE 'Migration 08 verification: % table exists ✓', tbl_name;
        ELSE
            RAISE WARNING 'Migration 08 issue: % table missing!', tbl_name;
        END IF;
    END LOOP;
END $$;