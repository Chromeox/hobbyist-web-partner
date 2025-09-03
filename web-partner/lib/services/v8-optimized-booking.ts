/**
 * V8-Optimized Booking Service
 * 
 * Performance optimizations:
 * - Stable object shapes for hidden class optimization
 * - Pre-allocated arrays for better memory usage
 * - Monomorphic functions for inline caching
 * - Object pooling to reduce GC pressure
 * - Batch operations to minimize serialization overhead
 */

import { supabase } from '../supabase';

// Stable interfaces for V8 hidden class optimization
interface BookingShape {
  id: string;
  user_id: string;
  class_id: string;
  studio_id: string;
  status: 'pending' | 'confirmed' | 'cancelled' | 'completed';
  payment_method: 'credit' | 'cash' | 'subscription';
  credits_used: number;
  amount_paid: number;
  cancelled_at: string | null;
  cancellation_reason: string | null;
  attended: boolean;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

interface CreditTransaction {
  id: string;
  user_id: string;
  amount: number;
  type: 'debit' | 'credit';
  balance_after: number;
  description: string;
  reference_id: string | null;
  reference_type: string | null;
  created_at: string;
}

// Object pool for reducing GC pressure
class BookingPool {
  private static pool: BookingShape[] = [];
  private static readonly MAX_POOL_SIZE = 50;
  
  // Pre-initialized template for stable shape
  private static readonly BOOKING_TEMPLATE: BookingShape = {
    id: '',
    user_id: '',
    class_id: '',
    studio_id: '',
    status: 'pending',
    payment_method: 'credit',
    credits_used: 0,
    amount_paid: 0,
    cancelled_at: null,
    cancellation_reason: null,
    attended: false,
    notes: null,
    created_at: '',
    updated_at: ''
  };
  
  static acquire(): BookingShape {
    const booking = this.pool.pop();
    if (booking) {
      return booking;
    }
    // Create new with stable shape
    return Object.assign(Object.create(null), this.BOOKING_TEMPLATE);
  }
  
  static release(booking: BookingShape): void {
    if (this.pool.length < this.MAX_POOL_SIZE) {
      // Reset to template shape
      Object.assign(booking, this.BOOKING_TEMPLATE);
      this.pool.push(booking);
    }
  }
}

// Pre-compiled query selectors for better performance
const QUERY_SELECTORS = {
  BOOKING_WITH_RELATIONS: `
    *,
    classes (
      id,
      title,
      start_time,
      duration_minutes,
      price,
      instructor_id,
      location_id
    ),
    users:user_id (
      id,
      email,
      first_name,
      last_name
    )
  `,
  CREDIT_BALANCE: 'user_id,balance,updated_at',
  BOOKING_STATS: 'status,created_at,credits_used,amount_paid'
} as const;

export class V8OptimizedBookingService {
  // Cache for hot data
  private static creditCache = new Map<string, { balance: number; timestamp: number }>();
  private static readonly CACHE_TTL = 5000; // 5 seconds
  
  /**
   * Create booking with V8 optimizations
   * Monomorphic function with stable shapes
   */
  static async createBooking(
    userId: string,
    classId: string,
    studioId: string,
    paymentMethod: 'credit' | 'cash' | 'subscription' = 'credit'
  ): Promise<BookingShape> {
    // Get pooled object for stable shape
    const booking = BookingPool.acquire();
    
    // Fill with consistent property order (important for V8)
    booking.id = crypto.randomUUID();
    booking.user_id = userId;
    booking.class_id = classId;
    booking.studio_id = studioId;
    booking.status = 'pending';
    booking.payment_method = paymentMethod;
    booking.credits_used = paymentMethod === 'credit' ? 1 : 0;
    booking.amount_paid = 0;
    booking.cancelled_at = null;
    booking.cancellation_reason = null;
    booking.attended = false;
    booking.notes = null;
    booking.created_at = new Date().toISOString();
    booking.updated_at = new Date().toISOString();
    
    try {
      // Single transaction for atomicity and performance
      const { data, error } = await supabase.rpc('create_booking_optimized', {
        p_booking: booking
      });
      
      if (error) throw error;
      return data;
    } catch (error) {
      // Release object back to pool on error
      BookingPool.release(booking);
      throw error;
    }
  }
  
  /**
   * Batch booking creation for better performance
   * Reduces round trips and serialization overhead
   */
  static async createBookingsBatch(
    bookings: Array<{
      userId: string;
      classId: string;
      studioId: string;
      paymentMethod?: 'credit' | 'cash' | 'subscription';
    }>
  ): Promise<BookingShape[]> {
    // Pre-allocate result array
    const batchSize = bookings.length;
    const bookingShapes = new Array<BookingShape>(batchSize);
    
    // Create all booking objects with stable shapes
    for (let i = 0; i < batchSize; i++) {
      const booking = BookingPool.acquire();
      const input = bookings[i];
      
      // Fill in consistent order
      booking.id = crypto.randomUUID();
      booking.user_id = input.userId;
      booking.class_id = input.classId;
      booking.studio_id = input.studioId;
      booking.status = 'pending';
      booking.payment_method = input.paymentMethod || 'credit';
      booking.credits_used = booking.payment_method === 'credit' ? 1 : 0;
      booking.amount_paid = 0;
      booking.cancelled_at = null;
      booking.cancellation_reason = null;
      booking.attended = false;
      booking.notes = null;
      booking.created_at = new Date().toISOString();
      booking.updated_at = new Date().toISOString();
      
      bookingShapes[i] = booking;
    }
    
    try {
      const { data, error } = await supabase
        .from('bookings')
        .insert(bookingShapes)
        .select();
      
      if (error) throw error;
      return data || [];
    } catch (error) {
      // Release all objects back to pool
      bookingShapes.forEach(b => BookingPool.release(b));
      throw error;
    }
  }
  
  /**
   * Get user's credit balance with caching
   * Avoids repeated database hits for hot data
   */
  static async getUserCredits(userId: string, useCache = true): Promise<number> {
    // Check cache first
    if (useCache) {
      const cached = this.creditCache.get(userId);
      if (cached && (Date.now() - cached.timestamp < this.CACHE_TTL)) {
        return cached.balance;
      }
    }
    
    const { data, error } = await supabase
      .from('user_credits')
      .select(QUERY_SELECTORS.CREDIT_BALANCE)
      .eq('user_id', userId)
      .single();
    
    if (error) throw error;
    
    const balance = data?.balance || 0;
    
    // Update cache
    this.creditCache.set(userId, {
      balance,
      timestamp: Date.now()
    });
    
    return balance;
  }
  
  /**
   * Validate booking with optimized checks
   * Monomorphic for V8 inline caching
   */
  static async validateBooking(
    userId: string,
    classId: string,
    paymentMethod: 'credit' | 'cash' | 'subscription'
  ): Promise<{ valid: boolean; reason?: string }> {
    // Parallel validation for better performance
    const [creditBalance, classData, existingBooking] = await Promise.all([
      paymentMethod === 'credit' ? this.getUserCredits(userId) : Promise.resolve(0),
      supabase.from('classes').select('id,capacity,bookings_count').eq('id', classId).single(),
      supabase.from('bookings')
        .select('id')
        .eq('user_id', userId)
        .eq('class_id', classId)
        .eq('status', 'confirmed')
        .single()
    ]);
    
    // Check existing booking
    if (existingBooking.data) {
      return { valid: false, reason: 'Already booked' };
    }
    
    // Check class availability
    if (!classData.data) {
      return { valid: false, reason: 'Class not found' };
    }
    
    if (classData.data.bookings_count >= classData.data.capacity) {
      return { valid: false, reason: 'Class full' };
    }
    
    // Check credits if needed
    if (paymentMethod === 'credit' && creditBalance < 1) {
      return { valid: false, reason: 'Insufficient credits' };
    }
    
    return { valid: true };
  }
  
  /**
   * Cancel booking with optimized transaction
   */
  static async cancelBooking(
    bookingId: string,
    reason?: string
  ): Promise<BookingShape> {
    const { data, error } = await supabase.rpc('cancel_booking_optimized', {
      p_booking_id: bookingId,
      p_reason: reason || 'User requested'
    });
    
    if (error) throw error;
    
    // Clear credit cache for affected user
    if (data?.user_id) {
      this.creditCache.delete(data.user_id);
    }
    
    return data;
  }
  
  /**
   * Get bookings with optimized query
   * Uses stable shapes and pre-compiled selectors
   */
  static async getBookings(
    filters: {
      userId?: string;
      studioId?: string;
      status?: string;
      startDate?: string;
      endDate?: string;
      limit?: number;
    }
  ): Promise<BookingShape[]> {
    let query = supabase
      .from('bookings')
      .select(QUERY_SELECTORS.BOOKING_WITH_RELATIONS);
    
    // Apply filters (order matters for query planning)
    if (filters.studioId) {
      query = query.eq('studio_id', filters.studioId);
    }
    if (filters.userId) {
      query = query.eq('user_id', filters.userId);
    }
    if (filters.status) {
      query = query.eq('status', filters.status);
    }
    if (filters.startDate) {
      query = query.gte('created_at', filters.startDate);
    }
    if (filters.endDate) {
      query = query.lte('created_at', filters.endDate);
    }
    
    // Limit with default
    query = query.limit(filters.limit || 50);
    
    const { data, error } = await query;
    
    if (error) throw error;
    return data || [];
  }
  
  /**
   * Process credit transaction with stable shape
   */
  static async processCredits(
    userId: string,
    amount: number,
    type: 'debit' | 'credit',
    referenceId?: string
  ): Promise<CreditTransaction> {
    // Create transaction with stable shape
    const transaction: CreditTransaction = {
      id: crypto.randomUUID(),
      user_id: userId,
      amount: Math.abs(amount),
      type: type,
      balance_after: 0, // Will be set by database
      description: type === 'debit' ? 'Class booking' : 'Credit purchase',
      reference_id: referenceId || null,
      reference_type: referenceId ? 'booking' : null,
      created_at: new Date().toISOString()
    };
    
    const { data, error } = await supabase
      .from('credit_transactions')
      .insert(transaction)
      .select()
      .single();
    
    if (error) throw error;
    
    // Clear cache for this user
    this.creditCache.delete(userId);
    
    return data;
  }
  
  /**
   * Get booking statistics with optimized aggregation
   */
  static async getBookingStats(
    studioId: string,
    startDate: string,
    endDate: string
  ): Promise<{
    total: number;
    confirmed: number;
    cancelled: number;
    revenue: number;
    credits: number;
  }> {
    // Use RPC for optimized server-side aggregation
    const { data, error } = await supabase.rpc('get_booking_stats_optimized', {
      p_studio_id: studioId,
      p_start_date: startDate,
      p_end_date: endDate
    });
    
    if (error) throw error;
    
    // Return with stable shape
    return {
      total: data?.total || 0,
      confirmed: data?.confirmed || 0,
      cancelled: data?.cancelled || 0,
      revenue: data?.revenue || 0,
      credits: data?.credits || 0
    };
  }
  
  /**
   * Clear all caches
   */
  static clearCache(): void {
    this.creditCache.clear();
  }
  
  /**
   * Get cache statistics for monitoring
   */
  static getCacheStats(): {
    creditCacheSize: number;
    poolSize: number;
  } {
    return {
      creditCacheSize: this.creditCache.size,
      poolSize: BookingPool['pool'].length
    };
  }
}

// Export singleton for backwards compatibility
export const v8BookingService = V8OptimizedBookingService;