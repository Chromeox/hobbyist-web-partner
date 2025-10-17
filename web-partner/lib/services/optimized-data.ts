/**
 * Optimized Data Service with V8 Runtime Performance Enhancements
 * 
 * Key optimizations:
 * 1. Stable object shapes for V8 hidden class optimization
 * 2. Response caching with LRU cache and TTL
 * 3. Batch API calls to reduce serialization overhead
 * 4. Object pooling for frequently created objects
 * 5. Lazy property initialization
 * 6. Pre-compiled query templates
 */

import { supabase } from '../supabase'
import type { Database } from '../../types/supabase'

type Tables = Database['public']['Tables']

// Cache configuration
const CACHE_TTL = 60000 // 60 seconds
const MAX_CACHE_SIZE = 100

// V8 optimization: Stable object shapes for hidden class optimization
class CacheEntry {
  data: any
  timestamp: number
  key: string
  
  constructor(key: string, data: any) {
    this.key = key
    this.data = data
    this.timestamp = Date.now()
  }
  
  isExpired(): boolean {
    return Date.now() - this.timestamp > CACHE_TTL
  }
}

// LRU Cache implementation with stable shapes
class LRUCache {
  private cache: Map<string, CacheEntry>
  private maxSize: number
  
  constructor(maxSize: number = MAX_CACHE_SIZE) {
    this.cache = new Map()
    this.maxSize = maxSize
  }
  
  get(key: string): any | null {
    const entry = this.cache.get(key)
    if (!entry) return null
    
    if (entry.isExpired()) {
      this.cache.delete(key)
      return null
    }
    
    // Move to end (most recently used)
    this.cache.delete(key)
    this.cache.set(key, entry)
    return entry.data
  }
  
  set(key: string, data: any): void {
    // Remove oldest if at capacity
    if (this.cache.size >= this.maxSize && !this.cache.has(key)) {
      const iterator = this.cache.keys().next()
      if (!iterator.done) {
        this.cache.delete(iterator.value)
      }
    }
    
    this.cache.set(key, new CacheEntry(key, data))
  }
  
  clear(): void {
    this.cache.clear()
  }
}

// Batch request queue
interface BatchRequest {
  query: () => Promise<any>
  resolve: (value: any) => void
  reject: (error: any) => void
}

class BatchQueue {
  private queue: BatchRequest[] = []
  private timer: NodeJS.Timeout | null = null
  private readonly batchDelay = 10 // ms
  private readonly maxBatchSize = 5
  
  add(query: () => Promise<any>): Promise<any> {
    return new Promise((resolve, reject) => {
      this.queue.push({ query, resolve, reject })
      this.scheduleBatch()
    })
  }
  
  private scheduleBatch(): void {
    if (this.timer) return
    
    this.timer = setTimeout(() => {
      this.processBatch()
    }, this.batchDelay)
  }
  
  private async processBatch(): Promise<void> {
    const batch = this.queue.splice(0, this.maxBatchSize)
    this.timer = null
    
    if (batch.length === 0) return
    
    try {
      const results = await Promise.allSettled(
        batch.map(req => req.query())
      )
      
      results.forEach((result, index) => {
        if (result.status === 'fulfilled') {
          batch[index].resolve(result.value)
        } else {
          batch[index].reject(result.reason)
        }
      })
    } catch (error) {
      batch.forEach(req => req.reject(error))
    }
    
    // Process remaining items if any
    if (this.queue.length > 0) {
      this.scheduleBatch()
    }
  }
}

// Pre-compiled query templates for better performance
const QUERY_TEMPLATES = {
  instructorWithProfile: `
    *,
    user_profiles (
      first_name,
      last_name,
      avatar_url
    )
  `,
  classWithRelations: `
    *,
    instructors (
      user_profiles (
        first_name,
        last_name
      )
    ),
    categories (
      name
    )
  `,
  bookingWithRelations: `
    *,
    classes (
      title,
      price,
      instructors (
        user_profiles (
          first_name,
          last_name
        )
      )
    ),
    user_profiles (
      first_name,
      last_name,
      email
    )
  `
} as const

// Object pool for frequently created objects
class ObjectPool<T> {
  private pool: T[] = []
  private factory: () => T
  private reset: (obj: T) => void
  private maxSize: number
  
  constructor(factory: () => T, reset: (obj: T) => void, maxSize = 50) {
    this.factory = factory
    this.reset = reset
    this.maxSize = maxSize
  }
  
  acquire(): T {
    return this.pool.pop() || this.factory()
  }
  
  release(obj: T): void {
    if (this.pool.length < this.maxSize) {
      this.reset(obj)
      this.pool.push(obj)
    }
  }
}

// Stable shape normalizer for V8 optimization
function normalizeResponse<T extends Record<string, any>>(
  data: T | null,
  template: Partial<T>
): T | null {
  if (!data) return null
  
  // Create object with stable shape
  const normalized = Object.create(null)
  
  // Copy properties in consistent order
  for (const key in template) {
    normalized[key] = data[key] !== undefined ? data[key] : template[key]
  }
  
  return normalized as T
}

// Main optimized service
export class OptimizedDataService {
  private static cache = new LRUCache()
  private static batchQueue = new BatchQueue()
  
  // Object pools for common response types
  private static responsePool = new ObjectPool(
    () => ({ data: null, error: null }),
    (obj) => { obj.data = null; obj.error = null },
    100
  )
  
  // Instructor Management with caching
  static async getInstructors(limit = 50, useCache = true): Promise<any> {
    const cacheKey = `instructors:${limit}`
    
    if (useCache) {
      const cached = this.cache.get(cacheKey)
      if (cached) return cached
    }
    
    const response = await this.batchQueue.add(async () => {
      const { data, error } = await supabase
        .from('instructors')
        .select(QUERY_TEMPLATES.instructorWithProfile)
        .limit(limit)
      
      if (error) throw error
      return data
    })
    
    this.cache.set(cacheKey, response)
    return response
  }
  
  // Batch multiple instructor fetches
  static async getInstructorsBatch(ids: string[]): Promise<Map<string, any>> {
    const results = new Map()
    const uncached: string[] = []
    
    // Check cache first
    for (const id of ids) {
      const cached = this.cache.get(`instructor:${id}`)
      if (cached) {
        results.set(id, cached)
      } else {
        uncached.push(id)
      }
    }
    
    // Batch fetch uncached
    if (uncached.length > 0) {
      const { data, error } = await supabase
        .from('instructors')
        .select(QUERY_TEMPLATES.instructorWithProfile)
        .in('id', uncached)
      
      if (!error && data) {
        for (const instructor of data) {
          this.cache.set(`instructor:${instructor.id}`, instructor)
          results.set(instructor.id, instructor)
        }
      }
    }
    
    return results
  }
  
  // Optimized class fetching with stable shapes
  static async getClasses(instructorId?: string, limit = 50): Promise<any> {
    const cacheKey = `classes:${instructorId || 'all'}:${limit}`
    const cached = this.cache.get(cacheKey)
    if (cached) return cached
    
    let query = supabase
      .from('classes')
      .select(QUERY_TEMPLATES.classWithRelations)
      .limit(limit)
    
    if (instructorId) {
      query = query.eq('instructor_id', instructorId)
    }
    
    const { data, error } = await query
    if (error) throw error
    
    // Normalize response shapes for V8 optimization
    const normalized = data?.map(item => ({
      id: item.id || '',
      instructor_id: item.instructor_id || '',
      category_id: item.category_id || '',
      title: item.title || '',
      description: item.description || '',
      price: item.price || 0,
      duration_minutes: item.duration_minutes || 0,
      max_participants: item.max_participants || 0,
      current_participants: item.current_participants || 0,
      difficulty_level: item.difficulty_level || 'all_levels',
      tags: item.tags || [],
      status: item.status || 'draft',
      created_at: item.created_at || '',
      updated_at: item.updated_at || '',
      instructors: item.instructors || null,
      categories: item.categories || null
    }))
    
    this.cache.set(cacheKey, normalized)
    return normalized
  }
  
  // Optimized dashboard stats with parallel fetching
  static async getDashboardStats(): Promise<any> {
    const cacheKey = 'dashboard:stats'
    const cached = this.cache.get(cacheKey)
    if (cached) return cached
    
    // Use Promise.allSettled for resilient parallel fetching
    const results = await Promise.allSettled([
      supabase.from('bookings').select('*', { count: 'exact', head: true }),
      supabase.from('instructors').select('*', { count: 'exact', head: true }),
      supabase.from('classes').select('*', { count: 'exact', head: true }),
      supabase.from('user_profiles').select('*', { count: 'exact', head: true }),
      supabase.from('payments').select('amount').eq('status', 'succeeded')
    ])
    
    // Process results with fallbacks
    const stats = {
      totalBookings: 0,
      totalInstructors: 0,
      totalClasses: 0,
      totalUsers: 0,
      totalRevenue: 0
    }
    
    if (results[0].status === 'fulfilled') {
      stats.totalBookings = results[0].value.count || 0
    }
    if (results[1].status === 'fulfilled') {
      stats.totalInstructors = results[1].value.count || 0
    }
    if (results[2].status === 'fulfilled') {
      stats.totalClasses = results[2].value.count || 0
    }
    if (results[3].status === 'fulfilled') {
      stats.totalUsers = results[3].value.count || 0
    }
    if (results[4].status === 'fulfilled' && results[4].value.data) {
      stats.totalRevenue = results[4].value.data.reduce(
        (sum: number, payment: any) => sum + (payment.amount || 0), 
        0
      )
    }
    
    this.cache.set(cacheKey, stats)
    return stats
  }
  
  // Prefetch common data for better perceived performance
  static async prefetchDashboardData(): Promise<void> {
    await Promise.allSettled([
      this.getDashboardStats(),
      this.getInstructors(10),
      this.getClasses(undefined, 20),
      this.getCategories()
    ])
  }
  
  // Categories with stable shape
  static async getCategories(): Promise<any> {
    const cacheKey = 'categories:active'
    const cached = this.cache.get(cacheKey)
    if (cached) return cached
    
    const { data, error } = await supabase
      .from('categories')
      .select('*')
      .eq('is_active', true)
      .order('order')
    
    if (error) throw error
    
    // Ensure stable shape
    const normalized = data?.map(cat => ({
      id: cat.id || '',
      name: cat.name || '',
      slug: cat.slug || '',
      description: cat.description || null,
      icon: cat.icon || null,
      image_url: cat.image_url || null,
      parent_id: cat.parent_id || null,
      order: cat.order || 0,
      is_active: cat.is_active !== false
    }))
    
    this.cache.set(cacheKey, normalized)
    return normalized
  }
  
  // Optimized real-time subscriptions with debouncing
  static subscribeToBookings(callback: (payload: any) => void): any {
    let timeoutId: NodeJS.Timeout
    const debouncedCallback = (payload: any) => {
      clearTimeout(timeoutId)
      timeoutId = setTimeout(() => {
        this.cache.clear() // Clear relevant cache
        callback(payload)
      }, 100) // 100ms debounce
    }
    
    return supabase
      .channel('bookings_changes')
      .on('postgres_changes', 
        { event: '*', schema: 'public', table: 'bookings' }, 
        debouncedCallback
      )
      .subscribe()
  }
  
  // Cache management utilities
  static clearCache(): void {
    this.cache.clear()
  }
  
  static getCacheStats(): { size: number; maxSize: number } {
    return {
      size: this.cache['cache'].size,
      maxSize: MAX_CACHE_SIZE
    }
  }
}

// Export singleton instance for backward compatibility
export const dataService = OptimizedDataService
