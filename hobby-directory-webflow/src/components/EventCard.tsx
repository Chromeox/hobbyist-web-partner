import React from 'react';
import type { EventCardData, Category } from '../types';

interface EventCardProps {
  event: EventCardData;
  variant?: 'compact' | 'standard' | 'featured';
  showStudio?: boolean;
  onClick?: (event: EventCardData) => void;
}

/**
 * EventCard Component
 * Displays event information in a card format
 * Matches The Running Directory design pattern
 */
export function EventCard({
  event,
  variant = 'standard',
  showStudio = true,
  onClick,
}: EventCardProps) {
  const handleClick = () => {
    if (onClick) {
      onClick(event);
    } else {
      // Default behavior: navigate to event detail page
      window.location.href = `/events/${event.slug}`;
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      handleClick();
    }
  };

  return (
    <article
      className={`event-card event-card--${variant}`}
      onClick={handleClick}
      onKeyDown={handleKeyDown}
      role="button"
      tabIndex={0}
      aria-label={`View details for ${event.name}`}
    >
      {/* Event Image */}
      <div className="event-card__image-container">
        <img
          src={event.image_url}
          alt={event.name}
          className="event-card__image"
          loading="lazy"
          onError={(e) => {
            // Fallback if image fails to load
            const target = e.target as HTMLImageElement;
            target.src = 'https://via.placeholder.com/800x450?text=Image+Loading';
          }}
        />

        {/* Urgency Badge */}
        {event.urgencyBadge && (
          <span className={`event-card__badge event-card__badge--${event.urgencyBadge.toLowerCase().replace(' ', '-')}`}>
            {event.urgencyBadge}
          </span>
        )}

        {/* Sold Out Overlay */}
        {event.isSoldOut && (
          <div className="event-card__sold-out-overlay">
            <span>Sold Out</span>
          </div>
        )}
      </div>

      {/* Event Content */}
      <div className="event-card__content">
        {/* Date & Time */}
        <div className="event-card__meta">
          <span className="event-card__date">
            📅 {event.formattedDate}
            {event.formattedTime && `, ${event.formattedTime}`}
          </span>
        </div>

        {/* Event Title */}
        <h3 className="event-card__title">{event.name}</h3>

        {/* Location */}
        {showStudio && (
          <p className="event-card__location">
            📍 {event.location}
          </p>
        )}

        {/* Price & Event Type */}
        <div className="event-card__details">
          <span className="event-card__price">
            💰 {event.formattedPrice}
          </span>
          {event.event_type && (
            <span className="event-card__type">
              🎯 {event.event_type}
            </span>
          )}
        </div>

        {/* Category Tags */}
        {event.tags && event.tags.length > 0 && (
          <div className="event-card__tags">
            {event.tags.map((tag) => (
              <span
                key={tag}
                className={`event-card__tag event-card__tag--${tag}`}
              >
                {tag}
              </span>
            ))}
          </div>
        )}

        {/* Spots Available Indicator */}
        {event.spots_available !== undefined && event.spots_available > 0 && event.spots_available <= 5 && (
          <p className="event-card__spots-warning">
            Only {event.spots_available} spot{event.spots_available !== 1 ? 's' : ''} left!
          </p>
        )}
      </div>
    </article>
  );
}

/**
 * EventCardSkeleton Component
 * Loading placeholder for EventCard
 */
export function EventCardSkeleton() {
  return (
    <div className="event-card event-card--skeleton" aria-label="Loading event">
      <div className="event-card__image-container skeleton-shimmer">
        <div className="skeleton-box" style={{ aspectRatio: '16/9' }} />
      </div>
      <div className="event-card__content">
        <div className="skeleton-box" style={{ width: '60%', height: '16px', marginBottom: '8px' }} />
        <div className="skeleton-box" style={{ width: '100%', height: '24px', marginBottom: '8px' }} />
        <div className="skeleton-box" style={{ width: '80%', height: '16px', marginBottom: '12px' }} />
        <div className="skeleton-box" style={{ width: '40%', height: '16px' }} />
      </div>
    </div>
  );
}

/**
 * EventCardError Component
 * Error state for EventCard
 */
export function EventCardError({ error }: { error: string }) {
  return (
    <div className="event-card event-card--error">
      <div className="event-card__content">
        <p className="event-card__error-message">
          ⚠️ Unable to load event: {error}
        </p>
      </div>
    </div>
  );
}

export default EventCard;
