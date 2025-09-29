-- Calendar Integration Schema for Studio Management
-- Supports Google Calendar, Outlook, Mindbody, Acuity, and other booking systems

-- Calendar Integrations Table
CREATE TABLE calendar_integrations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  studio_id UUID NOT NULL REFERENCES studios(id) ON DELETE CASCADE,
  provider TEXT NOT NULL CHECK (provider IN ('google', 'outlook', 'apple', 'acuity', 'mindbody', 'calendly', 'square')),
  provider_account_id TEXT, -- External account identifier
  access_token TEXT, -- Encrypted in application layer
  refresh_token TEXT, -- Encrypted in application layer
  token_expires_at TIMESTAMPTZ,
  sync_enabled BOOLEAN DEFAULT true,
  sync_direction TEXT DEFAULT 'bidirectional' CHECK (sync_direction IN ('import_only', 'export_only', 'bidirectional')),
  last_sync_at TIMESTAMPTZ,
  sync_status TEXT DEFAULT 'active' CHECK (sync_status IN ('active', 'error', 'paused', 'expired')),
  error_message TEXT,
  settings JSONB DEFAULT '{}', -- Provider-specific settings
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(studio_id, provider, provider_account_id)
);

-- Imported Events Table (temporary staging for migration)
CREATE TABLE imported_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  integration_id UUID NOT NULL REFERENCES calendar_integrations(id) ON DELETE CASCADE,
  external_id TEXT NOT NULL, -- Original event ID from external system
  provider TEXT NOT NULL,
  studio_id UUID NOT NULL REFERENCES studios(id) ON DELETE CASCADE,

  -- Workshop/Event Details
  title TEXT NOT NULL,
  description TEXT,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  all_day BOOLEAN DEFAULT false,

  -- Instructor and Location
  instructor_name TEXT,
  instructor_email TEXT,
  location TEXT,
  room TEXT,

  -- Workshop-specific data
  category TEXT, -- pottery, painting, etc.
  skill_level TEXT,
  max_participants INTEGER,
  current_participants INTEGER DEFAULT 0,
  price DECIMAL(10,2),
  material_fee DECIMAL(10,2),

  -- Migration Status
  migration_status TEXT DEFAULT 'pending' CHECK (migration_status IN ('pending', 'mapped', 'imported', 'error', 'skipped')),
  mapped_class_id UUID REFERENCES classes(id),
  mapped_schedule_id UUID REFERENCES class_schedules(id),
  error_details JSONB,

  -- Metadata
  raw_data JSONB, -- Original event data for debugging
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(integration_id, external_id)
);

-- Workshop Material Requirements (extended from existing schema)
CREATE TABLE IF NOT EXISTS workshop_materials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  material_name TEXT NOT NULL,
  quantity_per_student DECIMAL(10,2) NOT NULL,
  unit_cost DECIMAL(10,2) NOT NULL,
  supplier TEXT,
  supplier_sku TEXT,
  category TEXT, -- clay, glazes, tools, canvas, etc.
  reorder_level INTEGER DEFAULT 10,
  current_stock INTEGER DEFAULT 0,
  auto_reorder BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Studio Inventory Tracking
CREATE TABLE IF NOT EXISTS studio_inventory (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  studio_id UUID NOT NULL REFERENCES studios(id) ON DELETE CASCADE,
  material_type TEXT NOT NULL, -- clay, glazes, brushes, canvas, wood, tools
  material_name TEXT NOT NULL, -- Porcelain Clay, Acrylic Paint - Red, etc.
  current_stock INTEGER NOT NULL DEFAULT 0,
  unit_type TEXT NOT NULL DEFAULT 'pieces', -- pieces, pounds, liters, feet
  unit_cost DECIMAL(10,2) NOT NULL,
  reorder_level INTEGER DEFAULT 10,
  supplier_name TEXT,
  supplier_contact TEXT,
  last_ordered_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(studio_id, material_type, material_name)
);

-- Workshop Templates for Easy Scheduling
CREATE TABLE IF NOT EXISTS workshop_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  studio_id UUID NOT NULL REFERENCES studios(id) ON DELETE CASCADE,
  name TEXT NOT NULL, -- "Beginner Pottery", "Holiday Ornament Making"
  category TEXT NOT NULL, -- pottery, painting, woodworking, etc.
  description TEXT,
  duration_minutes INTEGER NOT NULL,
  max_participants INTEGER DEFAULT 8,
  skill_level TEXT DEFAULT 'beginner' CHECK (skill_level IN ('beginner', 'intermediate', 'advanced', 'all_levels')),
  base_price DECIMAL(10,2) NOT NULL,
  material_fee DECIMAL(10,2) DEFAULT 0,

  -- Material Requirements
  material_requirements JSONB DEFAULT '[]', -- Array of {material_name, quantity, cost}
  equipment_needed TEXT[], -- kiln, pottery_wheel, easels, etc.

  -- Scheduling
  seasonal_category TEXT, -- "holiday", "summer", "year_round"
  typical_days TEXT[], -- ["tuesday", "thursday", "saturday"]

  -- Template Settings
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Studio Business Expenses
CREATE TABLE IF NOT EXISTS studio_expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  studio_id UUID NOT NULL REFERENCES studios(id) ON DELETE CASCADE,
  category TEXT NOT NULL CHECK (category IN ('materials', 'utilities', 'rent', 'instructor_pay', 'equipment', 'insurance', 'marketing', 'other')),
  subcategory TEXT, -- More specific categorization
  amount DECIMAL(10,2) NOT NULL,
  description TEXT NOT NULL,
  expense_date DATE NOT NULL,
  receipt_url TEXT, -- Link to receipt image
  tax_deductible BOOLEAN DEFAULT true,
  vendor_name TEXT,
  payment_method TEXT, -- cash, card, check, bank_transfer
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_calendar_integrations_studio_provider ON calendar_integrations(studio_id, provider);
CREATE INDEX idx_imported_events_integration_status ON imported_events(integration_id, migration_status);
CREATE INDEX idx_imported_events_studio_time ON imported_events(studio_id, start_time);
CREATE INDEX idx_workshop_materials_class ON workshop_materials(class_id);
CREATE INDEX idx_studio_inventory_studio_type ON studio_inventory(studio_id, material_type);
CREATE INDEX idx_workshop_templates_studio_category ON workshop_templates(studio_id, category);
CREATE INDEX idx_studio_expenses_studio_date ON studio_expenses(studio_id, expense_date);

-- Enable RLS
ALTER TABLE calendar_integrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE imported_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE workshop_materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE workshop_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_expenses ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Studios can manage their calendar integrations" ON calendar_integrations
  FOR ALL USING (
    studio_id IN (
      SELECT id FROM studios
      WHERE auth.uid() IN (
        SELECT user_id FROM studio_staff WHERE studio_id = studios.id AND role IN ('owner', 'admin')
      )
    )
  );

CREATE POLICY "Studios can manage their imported events" ON imported_events
  FOR ALL USING (
    studio_id IN (
      SELECT id FROM studios
      WHERE auth.uid() IN (
        SELECT user_id FROM studio_staff WHERE studio_id = studios.id AND role IN ('owner', 'admin', 'manager')
      )
    )
  );

CREATE POLICY "Studios can manage their materials" ON workshop_materials
  FOR ALL USING (
    class_id IN (
      SELECT id FROM classes
      WHERE studio_id IN (
        SELECT id FROM studios
        WHERE auth.uid() IN (
          SELECT user_id FROM studio_staff WHERE studio_id = studios.id
        )
      )
    )
  );

CREATE POLICY "Studios can manage their inventory" ON studio_inventory
  FOR ALL USING (
    studio_id IN (
      SELECT id FROM studios
      WHERE auth.uid() IN (
        SELECT user_id FROM studio_staff WHERE studio_id = studios.id
      )
    )
  );

CREATE POLICY "Studios can manage their templates" ON workshop_templates
  FOR ALL USING (
    studio_id IN (
      SELECT id FROM studios
      WHERE auth.uid() IN (
        SELECT user_id FROM studio_staff WHERE studio_id = studios.id
      )
    )
  );

CREATE POLICY "Studios can manage their expenses" ON studio_expenses
  FOR ALL USING (
    studio_id IN (
      SELECT id FROM studios
      WHERE auth.uid() IN (
        SELECT user_id FROM studio_staff WHERE studio_id = studios.id AND role IN ('owner', 'admin', 'manager')
      )
    )
  );

-- Functions for calendar sync status updates
CREATE OR REPLACE FUNCTION update_calendar_sync_status(
  integration_id UUID,
  status TEXT,
  error_msg TEXT DEFAULT NULL
) RETURNS void AS $$
BEGIN
  UPDATE calendar_integrations
  SET
    sync_status = status,
    error_message = error_msg,
    last_sync_at = CASE WHEN status = 'active' THEN NOW() ELSE last_sync_at END,
    updated_at = NOW()
  WHERE id = integration_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to calculate material costs for workshops
CREATE OR REPLACE FUNCTION calculate_workshop_material_cost(
  template_id UUID
) RETURNS DECIMAL AS $$
DECLARE
  total_cost DECIMAL(10,2) := 0;
  material_req JSONB;
BEGIN
  SELECT material_requirements INTO material_req
  FROM workshop_templates
  WHERE id = template_id;

  -- Calculate total material cost based on requirements
  SELECT COALESCE(
    SUM((material->>'quantity')::DECIMAL * (material->>'cost')::DECIMAL),
    0
  ) INTO total_cost
  FROM jsonb_array_elements(material_req) AS material;

  RETURN total_cost;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;