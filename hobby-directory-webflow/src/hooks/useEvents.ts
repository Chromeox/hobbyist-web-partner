import useSWR from 'swr';
import type { EventCardData, EventDetailData, FilterState, Studio } from '../types';
import {
  fetchActiveEvents,
  fetchEventBySlug,
  fetchFeaturedEvents,
  fetchStudios,
  fetchCategories,
  searchEvents,
} from '../lib/airtable';

/**
 * Hook to fetch all active events with optional filtering
 */
export function useEvents(filters?: FilterState) {
  const { data, error, isLoading, mutate } = useSWR(
    filters ? ['events', JSON.stringify(filters)] : 'events',
    () => fetchActiveEvents(filters),
    {
      revalidateOnFocus: false,
      revalidateOnReconnect: false,
      refreshInterval: 300000, // Refresh every 5 minutes
      dedupingInterval: 60000, // Dedupe requests within 1 minute
    }
  );

  return {
    events: data?.data || [],
    isLoading,
    isError: !!error || !!data?.error,
    error: error || data?.error,
    mutate,
  };
}

/**
 * Hook to fetch a single event by slug
 */
export function useEvent(slug: string | null) {
  const { data, error, isLoading, mutate } = useSWR(
    slug ? ['event', slug] : null,
    () => (slug ? fetchEventBySlug(slug) : null),
    {
      revalidateOnFocus: false,
      revalidateOnReconnect: false,
      refreshInterval: 300000, // Refresh every 5 minutes
    }
  );

  return {
    event: data?.data || null,
    isLoading,
    isError: !!error || !!data?.error,
    error: error || data?.error,
    mutate,
  };
}

/**
 * Hook to fetch featured/upcoming events for homepage
 */
export function useFeaturedEvents(limit = 6) {
  const { data, error, isLoading, mutate } = useSWR(
    ['featured-events', limit],
    () => fetchFeaturedEvents(limit),
    {
      revalidateOnFocus: false,
      revalidateOnReconnect: false,
      refreshInterval: 300000, // Refresh every 5 minutes
      dedupingInterval: 60000,
    }
  );

  return {
    events: data?.data || [],
    isLoading,
    isError: !!error || !!data?.error,
    error: error || data?.error,
    mutate,
  };
}

/**
 * Hook to fetch all studios
 */
export function useStudios() {
  const { data, error, isLoading, mutate } = useSWR(
    'studios',
    fetchStudios,
    {
      revalidateOnFocus: false,
      revalidateOnReconnect: false,
      refreshInterval: 600000, // Refresh every 10 minutes (studios change less frequently)
      dedupingInterval: 300000, // Dedupe for 5 minutes
    }
  );

  return {
    studios: data?.data || [],
    isLoading,
    isError: !!error || !!data?.error,
    error: error || data?.error,
    mutate,
  };
}

/**
 * Hook to fetch available categories
 */
export function useCategories() {
  const { data, error, isLoading, mutate } = useSWR(
    'categories',
    fetchCategories,
    {
      revalidateOnFocus: false,
      revalidateOnReconnect: false,
      refreshInterval: 600000, // Refresh every 10 minutes
      dedupingInterval: 300000,
    }
  );

  return {
    categories: data?.data || [],
    isLoading,
    isError: !!error || !!data?.error,
    error: error || data?.error,
    mutate,
  };
}

/**
 * Hook for event search with debouncing
 */
export function useEventSearch(query: string, debounceMs = 300) {
  // Only fetch if query is at least 2 characters
  const shouldFetch = query.length >= 2;

  const { data, error, isLoading, mutate } = useSWR(
    shouldFetch ? ['search', query] : null,
    () => (shouldFetch ? searchEvents(query) : null),
    {
      revalidateOnFocus: false,
      revalidateOnReconnect: false,
      dedupingInterval: debounceMs,
    }
  );

  return {
    results: data?.data || [],
    isSearching: isLoading,
    isError: !!error || !!data?.error,
    error: error || data?.error,
    mutate,
  };
}
