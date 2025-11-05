'use client';

import { supabase } from '../supabase';

const CACHE_TTL = 60_000;

type CacheEntry<T> = {
  data: T;
  timestamp: number;
};

class SimpleCache {
  private store = new Map<string, CacheEntry<any>>();

  get<T>(key: string): T | null {
    const entry = this.store.get(key);
    if (!entry) {
      return null;
    }

    if (Date.now() - entry.timestamp > CACHE_TTL) {
      this.store.delete(key);
      return null;
    }

    return entry.data as T;
  }

  set<T>(key: string, data: T): void {
    this.store.set(key, { data, timestamp: Date.now() });
  }

  clear(): void {
    this.store.clear();
  }

  stats() {
    return {
      size: this.store.size,
      keys: Array.from(this.store.keys())
    };
  }
}

type InstructorProfileRow = {
  id: string;
  display_name: string;
  average_rating: number | null;
  total_students: number | null;
  profile_image_url: string | null;
};

type ClassesRow = {
  id: string;
  instructor_id: string | null;
  name: string | null;
  description: string | null;
  price: number | null;
  duration: number | null;
  max_participants: number | null;
  category: string | null;
  difficulty_level: string | null;
  equipment_needed: string[] | null;
  is_active: boolean | null;
  created_at: string | null;
  updated_at: string | null;
};

type CreditTransactionRow = {
  amount: number;
};

const cache = new SimpleCache();

const splitName = (input: string | null) => {
  if (!input) {
    return { first: '', last: '' };
  }

  const parts = input.trim().split(/\s+/);
  const first = parts[0] ?? '';
  const last = parts.length > 1 ? parts.slice(1).join(' ') : '';
  return { first, last };
};

export class OptimizedDataService {
  private static cache = cache;

  static clearCache(): void {
    this.cache.clear();
  }

  static getCacheStats() {
    return this.cache.stats();
  }

  private static getCached<T>(key: string): T | null {
    return this.cache.get<T>(key);
  }

  private static setCached<T>(key: string, data: T): void {
    this.cache.set<T>(key, data);
  }

  static async getInstructors(limit = 50): Promise<any[]> {
    const cacheKey = `instructors:${limit}`;
    const cached = this.getCached<any[]>(cacheKey);
    if (cached) return cached;

    const client = supabase as any;

    const { data, error } = await client
      .from('instructor_profiles')
      .select('id, display_name, average_rating, total_students, profile_image_url')
      .order('average_rating', { ascending: false, nullsFirst: false })
      .limit(limit);

    if (error) {
      throw error;
    }

    const rows = (data ?? []) as InstructorProfileRow[];
    const normalized = rows.map(row => {
      const { first, last } = splitName(row.display_name);

      return {
        id: row.id,
        rating: row.average_rating ?? 0,
        total_students: row.total_students ?? 0,
        user_profiles: {
          first_name: first,
          last_name: last,
          avatar_url: row.profile_image_url
        }
      };
    });

    this.setCached(cacheKey, normalized);
    return normalized;
  }

  static async getClasses(instructorId?: string, limit = 50): Promise<any[]> {
    const cacheKey = `classes:${instructorId || 'all'}:${limit}`;
    const cached = this.getCached<any[]>(cacheKey);
    if (cached) return cached;

    const client = supabase as any;

    let query = client
      .from('classes')
      .select('id, instructor_id, name, description, price, duration, max_participants, category, difficulty_level, equipment_needed, is_active, created_at, updated_at')
      .order('created_at', { ascending: false, nullsFirst: false })
      .limit(limit);

    if (instructorId) {
      query = query.eq('instructor_id', instructorId);
    }

    const { data, error } = await query;
    if (error) {
      throw error;
    }

    const rows = (data ?? []) as ClassesRow[];
    const normalized = rows.map(row => ({
      id: row.id,
      instructor_id: row.instructor_id ?? '',
      title: row.name ?? '',
      description: row.description ?? '',
      price: row.price ?? 0,
      duration_minutes: row.duration ?? 0,
      max_participants: row.max_participants ?? 0,
      current_participants: 0,
      difficulty_level: row.difficulty_level ?? 'all_levels',
      tags: row.equipment_needed ?? [],
      status: row.is_active ? 'active' : 'inactive',
      created_at: row.created_at ?? '',
      updated_at: row.updated_at ?? '',
      categories: row.category ? { name: row.category } : null
    }));

    this.setCached(cacheKey, normalized);
    return normalized;
  }

  static async getDashboardStats() {
    const cacheKey = 'dashboard:stats';
    const cached = this.getCached<any>(cacheKey);
    if (cached) return cached;

    const client = supabase as any;

    const [
      bookingsResponse,
      instructorsResponse,
      classesResponse,
      profilesResponse,
      transactionsResponse
    ] = await Promise.all([
      client.from('bookings').select('id', { count: 'exact', head: true }),
      client.from('instructor_profiles').select('id', { count: 'exact', head: true }),
      client.from('classes').select('id', { count: 'exact', head: true }),
      client.from('user_profiles').select('id', { count: 'exact', head: true }),
      client.from('credit_transactions').select('amount')
    ]);

    const totalRevenue =
      (transactionsResponse.data as CreditTransactionRow[] | null)?.reduce((sum, tx) => {
        return tx.amount > 0 ? sum + tx.amount : sum;
      }, 0) ?? 0;

    const stats = {
      totalBookings: bookingsResponse.count ?? 0,
      totalInstructors: instructorsResponse.count ?? 0,
      totalClasses: classesResponse.count ?? 0,
      totalUsers: profilesResponse.count ?? 0,
      totalRevenue
    };

    this.setCached(cacheKey, stats);
    return stats;
  }

  static async prefetchDashboardData(): Promise<void> {
    await Promise.allSettled([
      this.getDashboardStats(),
      this.getInstructors(10),
      this.getClasses(undefined, 10)
    ]);
  }

  static subscribeToBookings(callback: (payload: any) => void) {
    return supabase
      .channel('optimized_bookings')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'bookings' }, callback)
      .subscribe();
  }
}

export const dataService = OptimizedDataService;
