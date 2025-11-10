import React, { useState, useMemo } from 'react';
import { EventCard, EventCardSkeleton, EventCardError } from './EventCard';
import { useEvents } from '../hooks/useEvents';
import type { FilterState, EventCardData } from '../types';

interface EventGridProps {
  initialFilters?: FilterState;
  layout?: 'grid' | 'list';
  showFilters?: boolean;
  maxItems?: number;
}

/**
 * EventGrid Component
 * Displays a grid/list of event cards with filtering capabilities
 */
export function EventGrid({
  initialFilters,
  layout = 'grid',
  showFilters = false,
  maxItems,
}: EventGridProps) {
  const [filters, setFilters] = useState<FilterState>(initialFilters || {});
  const { events, isLoading, isError, error } = useEvents(filters);

  // Apply max items limit if specified
  const displayEvents = useMemo(() => {
    if (maxItems) {
      return events.slice(0, maxItems);
    }
    return events;
  }, [events, maxItems]);

  // Handle filter changes
  const handleFilterChange = (newFilters: Partial<FilterState>) => {
    setFilters((prev) => ({ ...prev, ...newFilters }));
  };

  // Handle event click
  const handleEventClick = (event: EventCardData) => {
    // Navigate to event detail page
    window.location.href = `/events/${event.slug}`;
  };

  return (
    <div className="event-grid-container">
      {/* Results Summary */}
      {!isLoading && (
        <div className="event-grid__summary">
          <p className="event-grid__count">
            {displayEvents.length} {displayEvents.length === 1 ? 'event' : 'events'} found
          </p>
        </div>
      )}

      {/* Loading State */}
      {isLoading && (
        <div className={`event-grid event-grid--${layout}`} role="status" aria-label="Loading events">
          {Array.from({ length: 6 }).map((_, index) => (
            <EventCardSkeleton key={index} />
          ))}
        </div>
      )}

      {/* Error State */}
      {isError && !isLoading && (
        <div className="event-grid__error">
          <EventCardError error={error || 'Failed to load events'} />
        </div>
      )}

      {/* Empty State */}
      {!isLoading && !isError && displayEvents.length === 0 && (
        <div className="event-grid__empty">
          <div className="event-grid__empty-content">
            <span className="event-grid__empty-icon">🔍</span>
            <h3>No events found</h3>
            <p>Try adjusting your filters or check back later for new events.</p>
          </div>
        </div>
      )}

      {/* Events Grid */}
      {!isLoading && !isError && displayEvents.length > 0 && (
        <div
          className={`event-grid event-grid--${layout}`}
          role="region"
          aria-label="Event listings"
        >
          {displayEvents.map((event) => (
            <EventCard
              key={event.id}
              event={event}
              onClick={handleEventClick}
            />
          ))}
        </div>
      )}

      {/* Load More / Pagination (future enhancement) */}
      {maxItems && events.length > maxItems && (
        <div className="event-grid__load-more">
          <button
            type="button"
            className="event-grid__load-more-button"
            onClick={() => {
              // Navigate to full events page
              window.location.href = '/events';
            }}
          >
            View All Events ({events.length})
          </button>
        </div>
      )}
    </div>
  );
}

/**
 * FeaturedEventsGrid Component
 * Specialized grid for featured/upcoming events on homepage
 */
export function FeaturedEventsGrid({ limit = 6 }: { limit?: number }) {
  return (
    <EventGrid
      layout="grid"
      showFilters={false}
      maxItems={limit}
    />
  );
}

/**
 * CategoryEventsGrid Component
 * Grid filtered by specific category
 */
export function CategoryEventsGrid({ category }: { category: string }) {
  return (
    <EventGrid
      initialFilters={{ categories: [category as any] }}
      layout="grid"
      showFilters={false}
    />
  );
}

export default EventGrid;
