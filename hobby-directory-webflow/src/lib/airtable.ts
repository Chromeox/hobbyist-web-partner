import Airtable from 'airtable';
import { format, parseISO, isToday, isTomorrow, isPast } from 'date-fns';
import type {
  Event,
  Studio,
  EventCardData,
  EventDetailData,
  FilterState,
  ApiResponse,
} from '../types';

// Initialize Airtable
const AIRTABLE_API_KEY = process.env.AIRTABLE_API_KEY || '';
const AIRTABLE_BASE_ID = process.env.AIRTABLE_BASE_ID || '';

if (!AIRTABLE_API_KEY || !AIRTABLE_BASE_ID) {
  console.warn('Airtable credentials not configured. Set AIRTABLE_API_KEY and AIRTABLE_BASE_ID.');
}

const base = new Airtable({ apiKey: AIRTABLE_API_KEY }).base(AIRTABLE_BASE_ID);

/**
 * Tables in Airtable
 */
export const Tables = {
  EVENTS: 'Events',
  STUDIOS: 'Studios',
  CONTENT_QUEUE: 'ContentQueue',
  ANALYTICS: 'Analytics',
} as const;

/**
 * Transform Airtable record to Event interface
 */
function transformEventRecord(record: any): Event {
  const fields = record.fields;
  return {
    id: record.id,
    name: fields.name || '',
    slug: fields.slug || '',
    description: fields.description || '',
    event_type: fields.event_type,
    event_date: fields.event_date || '',
    meeting_time: fields.meeting_time || '',
    meeting_day: fields.meeting_day,
    location: fields.location || '',
    address: fields.address || '',
    image_url: fields.image_url || '',
    price: fields.price || 0,
    tags: fields.tags || [],
    status: fields.status || 'pending',
    webflow_status: fields.webflow_status,
    sync_to_webflow: fields.sync_to_webflow || false,
    dynamic_label: fields.dynamic_label,
    spots_available: fields.spots_available,
    instructor_name: fields.instructor_name,
    link_url: fields.link_url,
    instagram_post_url: fields.instagram_post_url,
    website_title: fields.website_title,
    website_h1: fields.website_h1,
    studio_id: fields.studio_id,
    original_caption: fields.original_caption,
    ai_rewritten_description: fields.ai_rewritten_description,
    internal_notes: fields.internal_notes,
    source: fields.source,
    scraper_data: fields.scraper_data,
    scraped_at: fields.scraped_at,
  };
}

/**
 * Transform Airtable record to Studio interface
 */
function transformStudioRecord(record: any): Studio {
  const fields = record.fields;
  return {
    id: record.id,
    name: fields.name || '',
    description: fields.description || '',
    instagram_handle: fields.instagram_handle,
    website_url: fields.website_url,
    city: fields.city || '',
    province: fields.province || '',
    logo_url: fields.logo_url,
    email: fields.email,
    phone: fields.phone,
    category: fields.category || [],
    partnership_tier: fields.partnership_tier || 'free',
    active_status: fields.active_status || false,
    last_scraped: fields.last_scraped,
  };
}

/**
 * Add computed fields for UI display
 */
function enhanceEventForCard(event: Event): EventCardData {
  const eventDate = event.event_date ? parseISO(event.event_date) : new Date();

  // Calculate urgency badge
  let urgencyBadge: EventCardData['urgencyBadge'];
  if (event.dynamic_label) {
    urgencyBadge = event.dynamic_label as any;
  } else if (event.spots_available !== undefined && event.spots_available === 0) {
    urgencyBadge = 'SOLD OUT';
  } else if (event.spots_available !== undefined && event.spots_available <= 3) {
    urgencyBadge = 'FINAL SPOTS';
  } else if (isToday(eventDate)) {
    urgencyBadge = 'TODAY';
  } else if (isTomorrow(eventDate)) {
    urgencyBadge = 'TOMORROW';
  }

  return {
    ...event,
    formattedDate: format(eventDate, 'EEE, MMM d'),
    formattedTime: event.meeting_time,
    formattedPrice: `$${event.price.toFixed(0)}`,
    isToday: isToday(eventDate),
    isTomorrow: isTomorrow(eventDate),
    isSoldOut: event.spots_available === 0,
    urgencyBadge,
  };
}

/**
 * Fetch all active events
 * @param filters - Optional filter criteria
 */
export async function fetchActiveEvents(
  filters?: FilterState
): Promise<ApiResponse<EventCardData[]>> {
  try {
    // Build filter formula
    let filterFormula = `AND(
      {status} = 'active',
      {sync_to_webflow} = TRUE(),
      IS_AFTER({event_date}, TODAY())
    )`;

    // Add category filter
    if (filters?.categories && filters.categories.length > 0) {
      const categoryConditions = filters.categories
        .map((cat) => `FIND("${cat}", {tags})`)
        .join(', ');
      filterFormula = `AND(${filterFormula}, OR(${categoryConditions}))`;
    }

    // Add date range filter
    if (filters?.dateRange?.start) {
      filterFormula = `AND(${filterFormula}, IS_AFTER({event_date}, '${filters.dateRange.start}'))`;
    }
    if (filters?.dateRange?.end) {
      filterFormula = `AND(${filterFormula}, IS_BEFORE({event_date}, '${filters.dateRange.end}'))`;
    }

    // Add price range filter
    if (filters?.priceRange) {
      if (filters.priceRange.min !== undefined) {
        filterFormula = `AND(${filterFormula}, {price} >= ${filters.priceRange.min})`;
      }
      if (filters.priceRange.max !== undefined) {
        filterFormula = `AND(${filterFormula}, {price} <= ${filters.priceRange.max})`;
      }
    }

    // Fetch records from Airtable
    const records = await base(Tables.EVENTS)
      .select({
        filterByFormula: filterFormula,
        sort: [
          { field: 'event_date', direction: 'asc' },
          { field: 'meeting_time', direction: 'asc' },
        ],
        maxRecords: 100, // Limit for performance
      })
      .all();

    // Transform and enhance records
    const events = records.map((record) => {
      const event = transformEventRecord(record);
      return enhanceEventForCard(event);
    });

    // Apply client-side filters if needed
    let filteredEvents = events;

    // Search query filter
    if (filters?.searchQuery) {
      const query = filters.searchQuery.toLowerCase();
      filteredEvents = filteredEvents.filter(
        (event) =>
          event.name.toLowerCase().includes(query) ||
          event.location.toLowerCase().includes(query) ||
          event.description.toLowerCase().includes(query)
      );
    }

    // Location filter
    if (filters?.locations && filters.locations.length > 0) {
      filteredEvents = filteredEvents.filter((event) =>
        filters.locations!.some((loc) =>
          event.address.toLowerCase().includes(loc.toLowerCase())
        )
      );
    }

    // Day of week filter
    if (filters?.daysOfWeek && filters.daysOfWeek.length > 0) {
      filteredEvents = filteredEvents.filter((event) =>
        filters.daysOfWeek!.includes(event.meeting_day as any)
      );
    }

    return {
      data: filteredEvents,
    };
  } catch (error) {
    console.error('Error fetching events:', error);
    return {
      data: [],
      error: error instanceof Error ? error.message : 'Failed to fetch events',
    };
  }
}

/**
 * Fetch a single event by slug
 */
export async function fetchEventBySlug(
  slug: string
): Promise<ApiResponse<EventDetailData | null>> {
  try {
    const records = await base(Tables.EVENTS)
      .select({
        filterByFormula: `{slug} = '${slug}'`,
        maxRecords: 1,
      })
      .all();

    if (records.length === 0) {
      return {
        data: null,
        error: 'Event not found',
      };
    }

    const event = transformEventRecord(records[0]);
    const eventCard = enhanceEventForCard(event);

    // Fetch studio information if available
    let studio: Studio | undefined;
    if (event.studio_id && event.studio_id.length > 0) {
      const studioRecord = await base(Tables.STUDIOS).find(event.studio_id[0]);
      studio = transformStudioRecord(studioRecord);
    }

    // Fetch related events (same category or same studio)
    const relatedRecords = await base(Tables.EVENTS)
      .select({
        filterByFormula: `AND(
          {status} = 'active',
          {sync_to_webflow} = TRUE(),
          IS_AFTER({event_date}, TODAY()),
          {slug} != '${slug}'
        )`,
        maxRecords: 6,
        sort: [{ field: 'event_date', direction: 'asc' }],
      })
      .all();

    const relatedEvents = relatedRecords.map((record) => {
      const relEvent = transformEventRecord(record);
      return enhanceEventForCard(relEvent);
    });

    const eventDetail: EventDetailData = {
      ...eventCard,
      studio,
      relatedEvents,
      studioName: studio?.name,
    };

    return {
      data: eventDetail,
    };
  } catch (error) {
    console.error('Error fetching event:', error);
    return {
      data: null,
      error: error instanceof Error ? error.message : 'Failed to fetch event',
    };
  }
}

/**
 * Fetch featured/upcoming events for homepage
 */
export async function fetchFeaturedEvents(limit = 6): Promise<ApiResponse<EventCardData[]>> {
  try {
    const records = await base(Tables.EVENTS)
      .select({
        filterByFormula: `AND(
          {status} = 'active',
          {sync_to_webflow} = TRUE(),
          IS_AFTER({event_date}, TODAY())
        )`,
        sort: [
          { field: 'event_date', direction: 'asc' },
          { field: 'meeting_time', direction: 'asc' },
        ],
        maxRecords: limit,
      })
      .all();

    const events = records.map((record) => {
      const event = transformEventRecord(record);
      return enhanceEventForCard(event);
    });

    return {
      data: events,
    };
  } catch (error) {
    console.error('Error fetching featured events:', error);
    return {
      data: [],
      error: error instanceof Error ? error.message : 'Failed to fetch featured events',
    };
  }
}

/**
 * Fetch all studios
 */
export async function fetchStudios(): Promise<ApiResponse<Studio[]>> {
  try {
    const records = await base(Tables.STUDIOS)
      .select({
        filterByFormula: '{active_status} = TRUE()',
        sort: [{ field: 'name', direction: 'asc' }],
      })
      .all();

    const studios = records.map((record) => transformStudioRecord(record));

    return {
      data: studios,
    };
  } catch (error) {
    console.error('Error fetching studios:', error);
    return {
      data: [],
      error: error instanceof Error ? error.message : 'Failed to fetch studios',
    };
  }
}

/**
 * Get unique categories from active events
 */
export async function fetchCategories(): Promise<ApiResponse<string[]>> {
  try {
    const records = await base(Tables.EVENTS)
      .select({
        filterByFormula: `AND(
          {status} = 'active',
          {sync_to_webflow} = TRUE()
        )`,
        fields: ['tags'],
      })
      .all();

    const categoriesSet = new Set<string>();
    records.forEach((record) => {
      const tags = record.fields.tags as string[] | undefined;
      if (tags) {
        tags.forEach((tag) => categoriesSet.add(tag));
      }
    });

    return {
      data: Array.from(categoriesSet).sort(),
    };
  } catch (error) {
    console.error('Error fetching categories:', error);
    return {
      data: [],
      error: error instanceof Error ? error.message : 'Failed to fetch categories',
    };
  }
}

/**
 * Search events by query string
 */
export async function searchEvents(query: string): Promise<ApiResponse<EventCardData[]>> {
  return fetchActiveEvents({ searchQuery: query });
}
