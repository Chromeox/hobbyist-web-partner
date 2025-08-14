// Shared TypeScript types for Supabase Edge Functions;

export interface User {
  id: string;
  email: string;
  role: 'student' | 'instructor' | 'admin';
  profile: UserProfile;
  created_at: string;
  updated_at: string;
};

export interface UserProfile {
  id: string;
  user_id: string;
  first_name: string;
  last_name: string;
  phone?: string;
  avatar_url?: string;
  bio?: string;
  date_of_birth?: string;
  emergency_contact?: EmergencyContact;
  preferences?: UserPreferences;
};

export interface EmergencyContact {
  name: string;
  phone: string;
  relationship: string;
};

export interface UserPreferences {
  notifications: NotificationPreferences;
  privacy: PrivacySettings;
  accessibility: AccessibilitySettings;
};

export interface NotificationPreferences {
  email: boolean;
  push: boolean;
  sms: boolean;
  class_reminders: boolean;
  promotional: boolean;
  instructor_updates: boolean;
};

export interface PrivacySettings {
  profile_visible: boolean;
  show_attendance: boolean;
  allow_invites: boolean;
};

export interface AccessibilitySettings {
  high_contrast: boolean;
  large_text: boolean;
  reduce_motion: boolean;
  haptic_feedback: boolean;
};

export interface Instructor {
  id: string;
  user_id: string;
  business_name?: string;
  stripe_account_id?: string;
  stripe_account_status: 'pending' | 'active' | 'restricted' | 'disabled';
  commission_rate: number;
  rating: number;
  total_reviews: number;
  total_students: number;
  verified: boolean;
  specialties: string[];
  certifications: Certification[];
  availability: AvailabilitySchedule;
  payout_settings?: PayoutSettings;
};

export interface Certification {
  name: string;
  issuer: string;
  date: string;
  verification_url?: string;
  document_url?: string;
};

export interface AvailabilitySchedule {
  monday: TimeSlot[];
  tuesday: TimeSlot[];
  wednesday: TimeSlot[];
  thursday: TimeSlot[];
  friday: TimeSlot[];
  saturday: TimeSlot[];
  sunday: TimeSlot[];
  exceptions: ScheduleException[];
};

export interface TimeSlot {
  start: string; // HH:MM format
  end: string; // HH:MM format
};

export interface ScheduleException {
  date: string;
  available: boolean;
  slots?: TimeSlot[];
  reason?: string;
};

export interface PayoutSettings {
  method: 'stripe' | 'bank_transfer' | 'paypal';
  frequency: 'daily' | 'weekly' | 'monthly';
  minimum_amount: number;
  account_details?: Record<string, any>;
};

export interface Class {
  id: string;
  instructor_id: string;
  category_id: string;
  title: string;
  description: string;
  price: number;
  duration_minutes: number;
  max_participants: number;
  current_participants: number;
  difficulty_level: 'beginner' | 'intermediate' | 'advanced' | 'all_levels';
  requirements?: string[];
  what_to_bring?: string[];
  tags: string[];
  images: ClassImage[];
  location: ClassLocation;
  schedule: ClassSchedule;
  status: 'draft' | 'published' | 'cancelled' | 'completed';
  cancellation_policy: CancellationPolicy;
  created_at: string;
  updated_at: string;
};

export interface ClassImage {
  url: string;
  alt_text?: string;
  is_primary: boolean;
  order: number;
};

export interface ClassLocation {;
  type: 'in_person' | 'online' | 'hybrid';
  address?: Address;
  online_link?: string;
  platform?: 'zoom' | 'teams' | 'google_meet' | 'custom';
  instructions?: string;
  geo_fence?: GeoFenceSettings;
};

export interface Address {
  street: string;
  city: string;
  state: string;
  zip: string;
  country: string;
  lat?: number;
  lng?: number;
};

export interface GeoFenceSettings {
  enabled: boolean;
  center_lat: number;
  center_lng: number;
  radius_meters: number;
  accuracy_threshold?: number; // Minimum GPS accuracy required (meters)
  check_in_window?: CheckInWindow;
  fallback_options?: GeoFenceFallbackOptions;
};

export interface CheckInWindow {
  opens_minutes_before: number; // Default: 10
  closes_minutes_after?: number; // Dynamic based on class duration if not specified
  dynamic_closing: boolean; // Use duration-based closing if true
};

export interface GeoFenceFallbackOptions {
  allow_manual_override: boolean;
  instructor_override_required: boolean;
  alternative_methods: ('qr_code' | 'class_code' | 'instructor_confirmation')[];
  emergency_bypass: boolean;
};

export interface ClassSchedule {;
  type: 'single' | 'recurring';
  start_date: string;
  end_date?: string;
  start_time: string;
  end_time: string;
  recurrence?: RecurrenceRule;
  exceptions?: ScheduleException[];
};

export interface RecurrenceRule {
  frequency: 'daily' | 'weekly' | 'monthly';
  interval: number;
  days_of_week?: number[]; // 0-6, Sunday-Saturday
  end_after_occurrences?: number;
  end_by_date?: string;
};

export interface CancellationPolicy {
  refund_percentage: number;
  hours_before_class: number;
  terms?: string;
};

export interface Booking {
  id: string;
  user_id: string;
  class_id: string;
  session_id?: string;
  status: 'pending' | 'confirmed' | 'cancelled' | 'completed' | 'no_show';
  payment_status: 'pending' | 'processing' | 'succeeded' | 'failed' | 'refunded';
  payment_intent_id?: string;
  amount: number;
  commission_amount: number;
  instructor_payout: number;
  booking_date: string;
  notes?: string;
  attendees: BookingAttendee[];
  created_at: string;
  updated_at: string;
};

export interface BookingAttendee {
  name: string;
  email?: string;
  phone?: string;
  emergency_contact?: EmergencyContact;
  dietary_restrictions?: string;
  medical_conditions?: string;
};

export interface Payment {
  id: string;
  booking_id: string;
  user_id: string;
  amount: number;
  currency: string;
  status: 'pending' | 'processing' | 'succeeded' | 'failed' | 'refunded';
  payment_method: 'card' | 'apple_pay' | 'google_pay' | 'bank_transfer';
  stripe_payment_intent_id?: string;
  stripe_charge_id?: string;
  stripe_refund_id?: string;
  metadata: Record<string, any>;
  created_at: string;
  updated_at: string;
};

export interface InstructorPayout {
  id: string;
  instructor_id: string;
  amount: number;
  currency: string;
  status: 'pending' | 'processing' | 'completed' | 'failed';
  stripe_transfer_id?: string;
  stripe_payout_id?: string;
  bookings: string[]; // Array of booking IDs
  period_start: string;
  period_end: string;
  processed_at?: string;
  created_at: string;
};

export interface Review {
  id: string;
  user_id: string;
  class_id: string;
  instructor_id: string;
  booking_id: string;
  rating: number; // 1-5
  title?: string;
  comment?: string;
  instructor_response?: string;
  helpful_count: number;
  images?: string[];
  verified_booking: boolean;
  created_at: string;
  updated_at: string;
};

export interface Category {
  id: string;
  name: string;
  slug: string;
  description?: string;
  icon?: string;
  image_url?: string;
  parent_id?: string;
  order: number;
  is_active: boolean;
};

export interface Notification {
  id: string;
  user_id: string;
  type: NotificationType;
  title: string;
  message: string;
  data?: Record<string, any>;
  read: boolean;
  read_at?: string;
  created_at: string;
};

export type NotificationType = 
  | 'booking_confirmation'
  | 'booking_reminder'
  | 'booking_cancelled'
  | 'class_update'
  | 'payment_received'
  | 'payout_processed'
  | 'review_received'
  | 'message_received'
  | 'system_announcement';

export interface ChatMessage {
  id: string;
  conversation_id: string;
  sender_id: string;
  content: string;
  attachments?: MessageAttachment[];
  read_by: string[];
  edited: boolean;
  edited_at?: string;
  created_at: string;
};

export interface MessageAttachment {;
  type: 'image' | 'file' | 'location';
  url: string;
  name?: string;
  size?: number;
  mime_type?: string;
};

export interface Conversation {
  id: string;
  participants: string[];
  type: 'direct' | 'group' | 'class_discussion';
  class_id?: string;
  last_message?: ChatMessage;
  unread_count: Record<string, number>;
  created_at: string;
  updated_at: string;
}

// API Response Types;
export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  error?: ApiError;
  meta?: ResponseMeta;
};

export interface ApiError {
  code: string;
  message: string;
  details?: Record<string, any>;
  timestamp: string;
};

export interface ResponseMeta {
  page?: number;
  per_page?: number;
  total?: number;
  total_pages?: number;
  has_more?: boolean;
  request_id?: string;
}

// Webhook Event Types;
export interface WebhookEvent {
  id: string;
  type: string;
  data: Record<string, any>;
  created_at: string;
  signature?: string;
};

export interface StripeWebhookEvent extends WebhookEvent {;
  type: 
    | 'payment_intent.succeeded'
    | 'payment_intent.failed'
    | 'charge.refunded'
    | 'account.updated'
    | 'payout.created'
    | 'payout.paid'
    | 'payout.failed';
  stripe_event_id: string;
}

// Real-time Subscription Types;
export interface RealtimeMessage {
  event: 'INSERT' | 'UPDATE' | 'DELETE';
  schema: string;
  table: string;
  old_record?: Record<string, any>;
  new_record?: Record<string, any>;
  timestamp: string;
};

// Check-in and Location Tracking Types;
export interface CheckInAttempt {
  id: string;
  booking_id: string;
  user_id: string;
  class_id: string;
  attempt_timestamp: string;
  success: boolean;
  location_data?: LocationData;
  check_in_method: 'geo_fence' | 'qr_code' | 'class_code' | 'manual_override' | 'instructor_confirmation';
  failure_reason?: string;
  distance_from_venue?: number;
  instructor_override?: InstructorOverride;
  device_info?: DeviceInfo;
};

export interface LocationData {
  latitude: number;
  longitude: number;
  accuracy: number; // GPS accuracy in meters
  altitude?: number;
  heading?: number;
  speed?: number;
  timestamp: string;
  source: 'gps' | 'network' | 'passive';
  privacy_rounded: boolean; // Whether coordinates were rounded for privacy
};

export interface InstructorOverride {
  instructor_id: string;
  reason: string;
  approved: boolean;
  timestamp: string;
  notes?: string;
};

export interface DeviceInfo {
  user_agent: string;
  platform: string;
  app_version?: string;
  location_services_enabled: boolean;
  location_permission: 'granted' | 'denied' | 'prompt' | 'unknown';
};

export interface GeoFenceValidation {
  within_fence: boolean;
  distance_meters: number;
  accuracy_sufficient: boolean;
  time_window_valid: boolean;
  check_in_allowed: boolean;
  reasons?: string[];
};

export interface CheckInSession {
  id: string;
  booking_id: string;
  user_id: string;
  class_id: string;
  status: 'pending' | 'successful' | 'failed' | 'manual_override';
  started_at: string;
  completed_at?: string;
  attempts: CheckInAttempt[];
  final_location?: LocationData;
  session_duration_seconds?: number;
}

// Credit-Based Pricing System Types
export interface CreditPack {
  id: string;
  name: string;
  description?: string;
  credit_amount: number;
  price_cents: number;
  bonus_credits: number;
  is_active: boolean;
  display_order: number;
  created_at: string;
  updated_at: string;
}

export interface UserCredits {
  id: string;
  user_id: string;
  credit_balance: number;
  total_earned: number;
  total_spent: number;
  last_activity_at: string;
  created_at: string;
  updated_at: string;
}

export interface CreditTransaction {
  id: string;
  user_id: string;
  transaction_type: 'purchase' | 'spend' | 'refund' | 'bonus' | 'admin_adjustment';
  credit_amount: number;
  balance_after: number;
  reference_type?: string;
  reference_id?: string;
  description?: string;
  metadata?: Record<string, any>;
  created_at: string;
}

export interface CreditPackPurchase {
  id: string;
  user_id: string;
  credit_pack_id: string;
  stripe_payment_intent_id?: string;
  amount_paid_cents: number;
  credits_received: number;
  bonus_credits: number;
  status: 'pending' | 'completed' | 'failed' | 'refunded';
  created_at: string;
  updated_at: string;
}

export interface StudioCommissionSettings {
  id: string;
  studio_id?: string;
  commission_rate: number; // 0.15 for 15%
  minimum_payout_cents: number;
  payout_frequency: 'daily' | 'weekly' | 'monthly';
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

// Enhanced Class interface for credit pricing
export interface ClassPricing {
  price_cents?: number; // Traditional pricing
  credit_cost: number; // Credits required
  allow_credit_payment: boolean;
}

// Enhanced Booking interface for credit payments
export interface CreditBooking extends Omit<Booking, 'payment_method'> {
  payment_method: 'card' | 'credits' | 'apple_pay' | 'google_pay';
  credits_used: number;
}

// Credit Pack Purchase Request
export interface CreditPackPurchaseRequest {
  credit_pack_id: string;
  payment_method_id?: string;
  save_payment_method?: boolean;
}

// Credit Booking Request
export interface CreditBookingRequest {
  class_id: string;
  attendees: BookingAttendee[];
  payment_method: 'card' | 'credits';
  payment_method_id?: string; // For card payments
  use_credits?: boolean; // For credit payments
  notes?: string;
}

// Studio Revenue Analytics
export interface StudioRevenueMetrics {
  total_revenue_cents: number;
  total_commission_cents: number;
  total_instructor_payouts_cents: number;
  total_bookings: number;
  credit_pack_sales: number;
  credit_bookings: number;
  card_bookings: number;
  period_start: string;
  period_end: string;
}

// Commission Calculation Result
export interface CommissionCalculation {
  commission_cents: number;
  instructor_payout_cents: number;
  commission_rate: number;
};