// Type definitions based on Airtable schema

export type EventStatus = 'pending' | 'active' | 'inactive';
export type WebflowStatus = 'draft' | 'published';
export type EventType = 'class' | 'workshop' | 'drop-in' | 'series' | 'event';
export type EventSource = 'instagram' | 'website' | 'google_sheets' | 'manual';
export type DayOfWeek = 'Monday' | 'Tuesday' | 'Wednesday' | 'Thursday' | 'Friday' | 'Saturday' | 'Sunday';
export type Category = 'pottery' | 'fitness' | 'art' | 'dance' | 'wellness' | 'food' | 'maker';
export type PartnershipTier = 'free' | 'featured' | 'premium';
export type QueueStatus = 'pending' | 'reviewing' | 'approved' | 'rejected';

/**
 * Event interface matching Airtable Events table
 */
export interface Event {
  id: string; // Airtable record ID

  // Core event information
  name: string;
  slug: string;
  description: string;
  event_type?: EventType;

  // Date and time
  event_date: string; // ISO 8601 date string
  meeting_time: string; // Human-readable time like "7:00 PM"
  meeting_day?: DayOfWeek;

  // Location
  location: string; // Studio name
  address: string;

  // Media
  image_url: string;

  // Pricing
  price: number;

  // Classification
  tags: Category[];

  // Metadata
  status: EventStatus;
  webflow_status?: WebflowStatus;
  sync_to_webflow: boolean;
  dynamic_label?: string; // "FINAL SPOTS", "TODAY", etc.

  // Availability
  spots_available?: number;

  // Instructor
  instructor_name?: string;

  // Links
  link_url?: string; // External booking URL
  instagram_post_url?: string;

  // SEO fields
  website_title?: string;
  website_h1?: string;

  // Studio relationship
  studio_id?: string[];

  // Content management
  original_caption?: string;
  ai_rewritten_description?: string;
  internal_notes?: string;

  // Scraper metadata
  source?: EventSource;
  scraper_data?: string;
  scraped_at?: string;
}

/**
 * Studio interface matching Airtable Studios table
 */
export interface Studio {
  id: string;

  // Basic information
  name: string;
  description: string;
  instagram_handle?: string;
  website_url?: string;

  // Location
  city: string;
  province: string;

  // Media
  logo_url?: string;

  // Contact
  email?: string;
  phone?: string;

  // Classification
  category: Category[];

  // Partnership
  partnership_tier: PartnershipTier;
  active_status: boolean;

  // Metadata
  last_scraped?: string;
}

/**
 * Content queue item for review workflow
 */
export interface ContentQueueItem {
  id: string;
  queue_id: number;
  event_id?: string[];
  queue_status: QueueStatus;
  priority: number;
  reviewer_notes?: string;
  auto_publish: boolean;
  publish_to_instagram: boolean;
  publish_to_webflow: boolean;
  webflow_sync_status?: string;
  created_at: string;
}

/**
 * Analytics data for events
 */
export interface EventAnalytics {
  id: string;
  analytics_id: number;
  event_id?: string[];
  directory_views: number;
  click_throughs: number;
  app_conversions: number;
  booking_conversions: number;
  date: string;
}

/**
 * Filter state for event browsing
 */
export interface FilterState {
  categories: Category[];
  dateRange?: {
    start?: string;
    end?: string;
  };
  priceRange?: {
    min: number;
    max: number;
  };
  locations?: string[];
  eventTypes?: EventType[];
  daysOfWeek?: DayOfWeek[];
  searchQuery?: string;
}

/**
 * Display-ready event card data
 * Computed fields for UI display
 */
export interface EventCardData extends Event {
  // Computed fields
  formattedDate: string; // "Thu, Dec 12"
  formattedTime: string; // "7:00 PM"
  formattedPrice: string; // "$75"
  isToday: boolean;
  isTomorrow: boolean;
  isSoldOut: boolean;
  urgencyBadge?: 'TODAY' | 'TOMORROW' | 'FINAL SPOTS' | 'SOLD OUT' | 'JUST ADDED';
  studioName?: string; // Populated from studio_id lookup
}

/**
 * Event detail page data
 * Includes related studio information
 */
export interface EventDetailData extends EventCardData {
  studio?: Studio;
  relatedEvents?: EventCardData[];
}

/**
 * API response wrapper
 */
export interface ApiResponse<T> {
  data: T;
  error?: string;
  offset?: string; // For pagination
}

/**
 * Pagination state
 */
export interface PaginationState {
  offset?: string;
  hasMore: boolean;
  isLoading: boolean;
}
