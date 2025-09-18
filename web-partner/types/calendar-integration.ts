// Calendar Integration Types for Studio Management Portal

export type CalendarProvider = 'google' | 'outlook' | 'apple' | 'acuity' | 'mindbody' | 'calendly' | 'square';

export type SyncDirection = 'import_only' | 'export_only' | 'bidirectional';

export type SyncStatus = 'active' | 'error' | 'paused' | 'expired';

export type MigrationStatus = 'pending' | 'mapped' | 'imported' | 'error' | 'skipped';

export interface CalendarIntegration {
  id: string;
  studio_id: string;
  provider: CalendarProvider;
  provider_account_id?: string;
  sync_enabled: boolean;
  sync_direction: SyncDirection;
  last_sync_at?: string;
  sync_status: SyncStatus;
  error_message?: string;
  settings: Record<string, any>;
  created_at: string;
  updated_at: string;
}

export interface ImportedEvent {
  id: string;
  integration_id: string;
  external_id: string;
  provider: CalendarProvider;
  studio_id: string;

  // Event Details
  title: string;
  description?: string;
  start_time: string;
  end_time: string;
  all_day: boolean;

  // Instructor and Location
  instructor_name?: string;
  instructor_email?: string;
  location?: string;
  room?: string;

  // Workshop Details
  category?: string;
  skill_level?: string;
  max_participants?: number;
  current_participants: number;
  price?: number;
  material_fee?: number;

  // Migration
  migration_status: MigrationStatus;
  mapped_class_id?: string;
  mapped_schedule_id?: string;
  error_details?: Record<string, any>;
  raw_data: Record<string, any>;

  created_at: string;
  updated_at: string;
}

export interface WorkshopMaterial {
  id: string;
  class_id: string;
  material_name: string;
  quantity_per_student: number;
  unit_cost: number;
  supplier?: string;
  supplier_sku?: string;
  category: string;
  reorder_level: number;
  current_stock: number;
  auto_reorder: boolean;
  created_at: string;
  updated_at: string;
}

export interface StudioInventory {
  id: string;
  studio_id: string;
  material_type: string;
  material_name: string;
  current_stock: number;
  unit_type: string;
  unit_cost: number;
  reorder_level: number;
  supplier_name?: string;
  supplier_contact?: string;
  last_ordered_at?: string;
  created_at: string;
  updated_at: string;
}

export interface WorkshopTemplate {
  id: string;
  studio_id: string;
  name: string;
  category: string;
  description?: string;
  duration_minutes: number;
  max_participants: number;
  skill_level: 'beginner' | 'intermediate' | 'advanced' | 'all_levels';
  base_price: number;
  material_fee: number;
  material_requirements: MaterialRequirement[];
  equipment_needed: string[];
  seasonal_category?: 'holiday' | 'summer' | 'year_round';
  typical_days: string[];
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface MaterialRequirement {
  material_name: string;
  quantity: number;
  cost: number;
  required: boolean;
}

export interface StudioExpense {
  id: string;
  studio_id: string;
  category: 'materials' | 'utilities' | 'rent' | 'instructor_pay' | 'equipment' | 'insurance' | 'marketing' | 'other';
  subcategory?: string;
  amount: number;
  description: string;
  expense_date: string;
  receipt_url?: string;
  tax_deductible: boolean;
  vendor_name?: string;
  payment_method?: string;
  created_at: string;
  updated_at: string;
}

// Calendar Integration Settings by Provider
export interface GoogleCalendarSettings {
  calendar_id: string;
  sync_attendees: boolean;
  default_reminder_minutes: number;
  timezone: string;
}

export interface OutlookCalendarSettings {
  calendar_id: string;
  sync_attendees: boolean;
  default_reminder_minutes: number;
  timezone: string;
}

export interface MindbodySettings {
  site_id: string;
  location_id: string;
  sync_class_schedules: boolean;
  sync_appointments: boolean;
  staff_mapping: Record<string, string>; // Mindbody staff ID to local instructor ID
}

export interface AcuitySettings {
  calendar_id: string;
  appointment_type_mapping: Record<string, string>; // Acuity type ID to local class ID
  sync_cancellations: boolean;
}

// Calendar Event Mapping for Import
export interface EventMapping {
  original_event: ImportedEvent;
  suggested_class_id?: string;
  suggested_instructor_id?: string;
  confidence_score: number; // 0-1, how confident the auto-mapping is
  mapping_reasons: string[];
  requires_manual_review: boolean;
}

// Import/Migration Results
export interface ImportResult {
  total_events: number;
  successfully_imported: number;
  failed_imports: number;
  requires_review: number;
  duplicate_events: number;
  error_details: string[];
  mapping_suggestions: EventMapping[];
}

// Calendar Sync Configuration
export interface CalendarSyncConfig {
  provider: CalendarProvider;
  sync_direction: SyncDirection;
  sync_frequency: 'real_time' | 'hourly' | 'daily' | 'manual';
  conflict_resolution: 'local_wins' | 'remote_wins' | 'manual_review';
  date_range_days: number; // How many days to sync (past and future)
  auto_create_instructors: boolean;
  auto_create_classes: boolean;
  default_workshop_category: string;
}

// Provider-specific API response types
export interface GoogleCalendarEvent {
  id: string;
  summary: string;
  description?: string;
  start: { dateTime: string; timeZone: string } | { date: string };
  end: { dateTime: string; timeZone: string } | { date: string };
  location?: string;
  attendees?: Array<{ email: string; displayName?: string }>;
  creator?: { email: string; displayName?: string };
}

export interface MindbodyClass {
  Id: number;
  Name: string;
  Description?: string;
  StartDateTime: string;
  EndDateTime: string;
  Location?: { Name: string };
  Staff?: { FirstName: string; LastName: string; Email?: string };
  MaxCapacity?: number;
  BookedCount?: number;
  Program?: { Name: string };
}

// Workshop Analytics for Dashboard
export interface WorkshopAnalytics {
  total_workshops: number;
  total_revenue: number;
  average_capacity: number;
  popular_categories: Array<{ category: string; count: number; revenue: number }>;
  seasonal_trends: Array<{ month: string; workshops: number; revenue: number }>;
  material_costs: number;
  profit_margin: number;
  instructor_performance: Array<{
    instructor_id: string;
    name: string;
    workshops_taught: number;
    average_rating: number;
    total_revenue: number;
  }>;
}