-- Migration 09: Calendar Integration (Manual Deploy - Safe Version)
-- This version handles existing objects gracefully

-- Calendar integration tables and policies
DO $$
BEGIN
    -- Calendar connections policies
    DROP POLICY IF EXISTS "Users can manage their own calendar connections" ON public.calendar_connections;
    CREATE POLICY "Users can manage their own calendar connections" ON public.calendar_connections
        FOR ALL USING (auth.uid() = user_id);

    -- Calendar events policies
    DROP POLICY IF EXISTS "Users can view their calendar events" ON public.calendar_events;
    CREATE POLICY "Users can view their calendar events" ON public.calendar_events
        FOR SELECT USING (
            auth.uid() IN (
                SELECT cc.user_id FROM public.calendar_connections cc
                WHERE cc.id = calendar_events.connection_id
            )
        );

    DROP POLICY IF EXISTS "Users can manage their calendar events" ON public.calendar_events;
    CREATE POLICY "Users can manage their calendar events" ON public.calendar_events
        FOR ALL USING (
            auth.uid() IN (
                SELECT cc.user_id FROM public.calendar_connections cc
                WHERE cc.id = calendar_events.connection_id
            )
        );

    -- Calendar sync logs policies
    DROP POLICY IF EXISTS "Users can view their sync logs" ON public.calendar_sync_logs;
    CREATE POLICY "Users can view their sync logs" ON public.calendar_sync_logs
        FOR SELECT USING (
            auth.uid() IN (
                SELECT cc.user_id FROM public.calendar_connections cc
                WHERE cc.id = calendar_sync_logs.connection_id
            )
        );

    -- Notification preferences policies
    DROP POLICY IF EXISTS "Users can manage their notification preferences" ON public.notification_preferences;
    CREATE POLICY "Users can manage their notification preferences" ON public.notification_preferences
        FOR ALL USING (auth.uid() = user_id);

    RAISE NOTICE 'Migration 09: All calendar integration policies updated successfully!';
END $$;

-- Verify key tables exist
DO $$
DECLARE
    table_names TEXT[] := ARRAY['calendar_connections', 'calendar_events', 'calendar_sync_logs', 'notification_preferences'];
    table_name TEXT;
BEGIN
    FOREACH table_name IN ARRAY table_names
    LOOP
        IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = table_name) THEN
            RAISE NOTICE 'Migration 09 verification: % table exists ✓', table_name;
        ELSE
            RAISE WARNING 'Migration 09 issue: % table missing!', table_name;
        END IF;
    END LOOP;
END $$;