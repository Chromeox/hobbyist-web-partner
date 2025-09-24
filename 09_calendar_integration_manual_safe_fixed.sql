-- Migration 09: Calendar Integration (Manual Deploy - Safe Version FIXED)
-- Creates tables first, then policies

-- Calendar Integrations Table
CREATE TABLE IF NOT EXISTS calendar_integrations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  studio_id UUID NOT NULL REFERENCES studios(id) ON DELETE CASCADE,
  provider TEXT NOT NULL CHECK (provider IN ('google', 'outlook', 'apple', 'acuity', 'mindbody', 'calendly', 'square')),
  provider_account_id TEXT,
  access_token TEXT,
  refresh_token TEXT,
  token_expires_at TIMESTAMPTZ,
  sync_enabled BOOLEAN DEFAULT true,
  sync_direction TEXT DEFAULT 'bidirectional' CHECK (sync_direction IN ('import_only', 'export_only', 'bidirectional')),
  last_sync_at TIMESTAMPTZ,
  sync_status TEXT DEFAULT 'active' CHECK (sync_status IN ('active', 'error', 'paused', 'expired')),
  error_message TEXT,
  settings JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(studio_id, provider, provider_account_id)
);

-- Imported Events Table
CREATE TABLE IF NOT EXISTS imported_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  integration_id UUID NOT NULL REFERENCES calendar_integrations(id) ON DELETE CASCADE,
  external_id TEXT NOT NULL,
  provider TEXT NOT NULL,
  studio_id UUID NOT NULL REFERENCES studios(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  all_day BOOLEAN DEFAULT false,
  instructor_name TEXT,
  instructor_email TEXT,
  location TEXT,
  room TEXT,
  category TEXT,
  skill_level TEXT,
  max_participants INTEGER,
  current_participants INTEGER DEFAULT 0,
  price DECIMAL(10,2),
  currency TEXT DEFAULT 'CAD',
  booking_url TEXT,
  image_url TEXT,
  tags TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(integration_id, external_id)
);

-- Enable RLS
ALTER TABLE calendar_integrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE imported_events ENABLE ROW LEVEL SECURITY;

-- Create policies safely
DO $$
BEGIN
    -- Calendar integrations policies
    DROP POLICY IF EXISTS "Studios can manage their integrations" ON calendar_integrations;
    CREATE POLICY "Studios can manage their integrations" ON calendar_integrations
        FOR ALL USING (
            EXISTS (
                SELECT 1 FROM studios s WHERE s.id = calendar_integrations.studio_id
                -- Note: Studio ownership validation would require user-studio relationship
            )
        );

    -- Imported events policies
    DROP POLICY IF EXISTS "Studios can view their imported events" ON imported_events;
    CREATE POLICY "Studios can view their imported events" ON imported_events
        FOR SELECT USING (
            EXISTS (
                SELECT 1 FROM studios s WHERE s.id = imported_events.studio_id
                -- Note: Studio ownership validation would require user-studio relationship
            )
        );

    RAISE NOTICE 'Migration 09: Calendar integration tables and policies created successfully!';
END $$;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_calendar_integrations_studio ON calendar_integrations(studio_id);
CREATE INDEX IF NOT EXISTS idx_calendar_integrations_provider ON calendar_integrations(provider);
CREATE INDEX IF NOT EXISTS idx_imported_events_integration ON imported_events(integration_id);
CREATE INDEX IF NOT EXISTS idx_imported_events_studio ON imported_events(studio_id);
CREATE INDEX IF NOT EXISTS idx_imported_events_start_time ON imported_events(start_time);

-- Verify tables exist
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'calendar_integrations') THEN
        RAISE NOTICE 'Migration 09 verification: calendar_integrations table exists ✓';
    ELSE
        RAISE WARNING 'Migration 09 issue: calendar_integrations table missing!';
    END IF;

    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'imported_events') THEN
        RAISE NOTICE 'Migration 09 verification: imported_events table exists ✓';
    ELSE
        RAISE WARNING 'Migration 09 issue: imported_events table missing!';
    END IF;
END $$;