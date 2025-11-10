import React from 'react';
import { useEvent } from '../hooks/useEvents';
import { EventCard } from './EventCard';
import type { EventDetailData, Studio } from '../types';

interface EventDetailProps {
  slug: string;
}

/**
 * EventDetail Component
 * Full event detail page with booking sidebar and related events
 */
export function EventDetail({ slug }: EventDetailProps) {
  const { event, isLoading, isError, error } = useEvent(slug);

  if (isLoading) {
    return <EventDetailSkeleton />;
  }

  if (isError || !event) {
    return <EventDetailError error={error || 'Event not found'} />;
  }

  return (
    <div className="event-detail">
      {/* Hero Image */}
      <div className="event-detail__hero">
        <img
          src={event.image_url}
          alt={event.name}
          className="event-detail__hero-image"
        />
        {event.urgencyBadge && (
          <span className={`event-detail__badge event-detail__badge--${event.urgencyBadge.toLowerCase().replace(' ', '-')}`}>
            {event.urgencyBadge}
          </span>
        )}
      </div>

      {/* Main Content Area */}
      <div className="event-detail__container">
        <div className="event-detail__main">
          {/* Event Header */}
          <header className="event-detail__header">
            <h1 className="event-detail__title">{event.name}</h1>
            {event.studio && (
              <p className="event-detail__studio-name">
                Hosted by <a href={`/studios/${event.studio.id}`}>{event.studio.name}</a>
              </p>
            )}
          </header>

          {/* Event Metadata */}
          <div className="event-detail__metadata">
            <div className="event-detail__meta-item">
              <span className="event-detail__meta-icon">📅</span>
              <div>
                <strong>Date & Time</strong>
                <p>{event.formattedDate} at {event.formattedTime}</p>
              </div>
            </div>

            <div className="event-detail__meta-item">
              <span className="event-detail__meta-icon">📍</span>
              <div>
                <strong>Location</strong>
                <p>{event.location}</p>
                <p className="event-detail__address">{event.address}</p>
              </div>
            </div>

            {event.instructor_name && (
              <div className="event-detail__meta-item">
                <span className="event-detail__meta-icon">👤</span>
                <div>
                  <strong>Instructor</strong>
                  <p>{event.instructor_name}</p>
                </div>
              </div>
            )}

            {event.event_type && (
              <div className="event-detail__meta-item">
                <span className="event-detail__meta-icon">🎯</span>
                <div>
                  <strong>Event Type</strong>
                  <p>{event.event_type}</p>
                </div>
              </div>
            )}
          </div>

          {/* Description */}
          <section className="event-detail__section">
            <h2 className="event-detail__section-title">About This Event</h2>
            <div className="event-detail__description">
              {event.ai_rewritten_description || event.description}
            </div>
          </section>

          {/* Studio Information */}
          {event.studio && (
            <section className="event-detail__section">
              <h2 className="event-detail__section-title">About {event.studio.name}</h2>
              <StudioCard studio={event.studio} />
            </section>
          )}

          {/* Related Events */}
          {event.relatedEvents && event.relatedEvents.length > 0 && (
            <section className="event-detail__section">
              <h2 className="event-detail__section-title">You Might Also Like</h2>
              <div className="event-detail__related-grid">
                {event.relatedEvents.map((relatedEvent) => (
                  <EventCard key={relatedEvent.id} event={relatedEvent} variant="compact" />
                ))}
              </div>
            </section>
          )}
        </div>

        {/* Booking Sidebar (Sticky) */}
        <aside className="event-detail__sidebar">
          <BookingSidebar event={event} />
        </aside>
      </div>
    </div>
  );
}

/**
 * BookingSidebar Component
 * Sticky booking widget with price and CTA
 */
function BookingSidebar({ event }: { event: EventDetailData }) {
  const handleBookClick = () => {
    if (event.link_url) {
      window.open(event.link_url, '_blank', 'noopener,noreferrer');
    }
  };

  return (
    <div className="booking-sidebar">
      <div className="booking-sidebar__price">
        <span className="booking-sidebar__price-label">Price</span>
        <span className="booking-sidebar__price-amount">{event.formattedPrice}</span>
      </div>

      {event.spots_available !== undefined && (
        <div className="booking-sidebar__availability">
          {event.isSoldOut ? (
            <span className="booking-sidebar__sold-out">Sold Out</span>
          ) : event.spots_available <= 5 ? (
            <span className="booking-sidebar__limited">
              Only {event.spots_available} spot{event.spots_available !== 1 ? 's' : ''} left!
            </span>
          ) : (
            <span className="booking-sidebar__available">
              {event.spots_available} spots available
            </span>
          )}
        </div>
      )}

      <button
        type="button"
        className={`booking-sidebar__cta ${event.isSoldOut ? 'booking-sidebar__cta--disabled' : ''}`}
        onClick={handleBookClick}
        disabled={event.isSoldOut}
      >
        {event.isSoldOut ? 'Sold Out' : 'Book Now'}
      </button>

      {event.link_url && !event.isSoldOut && (
        <p className="booking-sidebar__note">
          You'll be redirected to complete your booking
        </p>
      )}

      {/* Trust Signals */}
      <div className="booking-sidebar__trust">
        <div className="booking-sidebar__trust-item">
          <span className="booking-sidebar__trust-icon">✓</span>
          <span>Secure booking</span>
        </div>
        {event.studio?.website_url && (
          <div className="booking-sidebar__trust-item">
            <span className="booking-sidebar__trust-icon">✓</span>
            <span>Verified studio</span>
          </div>
        )}
      </div>

      {/* Category Tags */}
      {event.tags && event.tags.length > 0 && (
        <div className="booking-sidebar__tags">
          {event.tags.map((tag) => (
            <span key={tag} className={`booking-sidebar__tag booking-sidebar__tag--${tag}`}>
              {tag}
            </span>
          ))}
        </div>
      )}
    </div>
  );
}

/**
 * StudioCard Component
 * Displays studio information within event detail
 */
function StudioCard({ studio }: { studio: Studio }) {
  return (
    <div className="studio-card">
      {studio.logo_url && (
        <img
          src={studio.logo_url}
          alt={`${studio.name} logo`}
          className="studio-card__logo"
        />
      )}
      <div className="studio-card__content">
        <h3 className="studio-card__name">{studio.name}</h3>
        <p className="studio-card__description">{studio.description}</p>
        <div className="studio-card__links">
          {studio.website_url && (
            <a
              href={studio.website_url}
              target="_blank"
              rel="noopener noreferrer"
              className="studio-card__link"
            >
              Visit Website
            </a>
          )}
          {studio.instagram_handle && (
            <a
              href={`https://instagram.com/${studio.instagram_handle}`}
              target="_blank"
              rel="noopener noreferrer"
              className="studio-card__link"
            >
              @{studio.instagram_handle}
            </a>
          )}
        </div>
      </div>
    </div>
  );
}

/**
 * EventDetailSkeleton Component
 * Loading state for event detail page
 */
function EventDetailSkeleton() {
  return (
    <div className="event-detail event-detail--skeleton" aria-label="Loading event details">
      <div className="skeleton-box" style={{ width: '100%', height: '400px' }} />
      <div className="event-detail__container">
        <div className="event-detail__main">
          <div className="skeleton-box" style={{ width: '70%', height: '48px', marginBottom: '16px' }} />
          <div className="skeleton-box" style={{ width: '40%', height: '24px', marginBottom: '32px' }} />
          <div className="skeleton-box" style={{ width: '100%', height: '200px' }} />
        </div>
        <div className="event-detail__sidebar">
          <div className="skeleton-box" style={{ width: '100%', height: '300px' }} />
        </div>
      </div>
    </div>
  );
}

/**
 * EventDetailError Component
 * Error state for event detail page
 */
function EventDetailError({ error }: { error: string }) {
  return (
    <div className="event-detail event-detail--error">
      <div className="event-detail__error-content">
        <h1>Event Not Found</h1>
        <p>{error}</p>
        <a href="/events" className="event-detail__error-link">
          Browse All Events
        </a>
      </div>
    </div>
  );
}

export default EventDetail;
