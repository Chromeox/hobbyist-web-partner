import { supabase } from '../supabase'
import type { Database } from '../../types/supabase'

type Tables = Database['public']['Tables']

export class DataService {
  // Instructor Management
  static async getInstructors(limit = 50) {
    const { data, error } = await supabase
      .from('instructors')
      .select(`
        *,
        user_profiles (
          first_name,
          last_name,
          avatar_url
        )
      `)
      .limit(limit)

    if (error) throw error
    return data
  }

  static async getInstructorById(id: string) {
    const { data, error } = await supabase
      .from('instructors')
      .select(`
        *,
        user_profiles (
          first_name,
          last_name,
          avatar_url,
          bio,
          phone
        )
      `)
      .eq('id', id)
      .single()

    if (error) throw error
    return data
  }

  static async updateInstructorStatus(id: string, status: Tables['instructors']['Row']['stripe_account_status']) {
    const { data, error } = await supabase
      .from('instructors')
      .update({ stripe_account_status: status })
      .eq('id', id)
      .select()

    if (error) throw error
    return data
  }

  // Class Management
  static async getClasses(instructorId?: string, limit = 50) {
    let query = supabase
      .from('classes')
      .select(`
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
      `)
      .limit(limit)

    if (instructorId) {
      query = query.eq('instructor_id', instructorId)
    }

    const { data, error } = await query
    if (error) throw error
    return data
  }

  static async updateClassStatus(id: string, status: Tables['classes']['Row']['status']) {
    const { data, error } = await supabase
      .from('classes')
      .update({ status })
      .eq('id', id)
      .select()

    if (error) throw error
    return data
  }

  // Booking Management
  static async getBookings(limit = 50, status?: Tables['bookings']['Row']['status']) {
    let query = supabase
      .from('bookings')
      .select(`
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
      `)
      .order('created_at', { ascending: false })
      .limit(limit)

    if (status) {
      query = query.eq('status', status)
    }

    const { data, error } = await query
    if (error) throw error
    return data
  }

  static async updateBookingStatus(id: string, status: Tables['bookings']['Row']['status']) {
    const { data, error } = await supabase
      .from('bookings')
      .update({ status })
      .eq('id', id)
      .select()

    if (error) throw error
    return data
  }

  // Payment Management
  static async getPayments(limit = 50) {
    const { data, error } = await supabase
      .from('payments')
      .select(`
        *,
        bookings (
          classes (
            title
          ),
          user_profiles (
            first_name,
            last_name
          )
        )
      `)
      .order('created_at', { ascending: false })
      .limit(limit)

    if (error) throw error
    return data
  }

  // Reviews Management
  static async getReviews(limit = 50) {
    const { data, error } = await supabase
      .from('reviews')
      .select(`
        *,
        classes (
          title
        ),
        user_profiles!reviews_user_id_fkey (
          first_name,
          last_name,
          avatar_url
        ),
        instructors (
          user_profiles (
            first_name,
            last_name
          )
        )
      `)
      .order('created_at', { ascending: false })
      .limit(limit)

    if (error) throw error
    return data
  }

  // Categories Management
  static async getCategories() {
    const { data, error } = await supabase
      .from('categories')
      .select('*')
      .eq('is_active', true)
      .order('order')

    if (error) throw error
    return data
  }

  // Analytics & Dashboard Data
  static async getDashboardStats() {
    const [
      { count: totalBookings },
      { count: totalInstructors },
      { count: totalClasses },
      { count: totalUsers }
    ] = await Promise.all([
      supabase.from('bookings').select('*', { count: 'exact', head: true }),
      supabase.from('instructors').select('*', { count: 'exact', head: true }),
      supabase.from('classes').select('*', { count: 'exact', head: true }),
      supabase.from('user_profiles').select('*', { count: 'exact', head: true })
    ])

    // Revenue calculation
    const { data: revenueData } = await supabase
      .from('payments')
      .select('amount')
      .eq('status', 'succeeded')

    const totalRevenue = revenueData?.reduce((sum, payment) => sum + payment.amount, 0) || 0

    return {
      totalBookings: totalBookings || 0,
      totalInstructors: totalInstructors || 0,
      totalClasses: totalClasses || 0,
      totalUsers: totalUsers || 0,
      totalRevenue
    }
  }

  // Real-time subscriptions
  static subscribeToBookings(callback: (payload: any) => void) {
    return supabase
      .channel('bookings_changes')
      .on('postgres_changes', 
        { event: '*', schema: 'public', table: 'bookings' }, 
        callback
      )
      .subscribe()
  }

  static subscribeToPayments(callback: (payload: any) => void) {
    return supabase
      .channel('payments_changes')
      .on('postgres_changes', 
        { event: '*', schema: 'public', table: 'payments' }, 
        callback
      )
      .subscribe()
  }
}

// Authentication helpers
export class AuthService {
  static async signIn(email: string, password: string) {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password
    })

    if (error) throw error
    return data
  }

  static async signOut() {
    const { error } = await supabase.auth.signOut()
    if (error) throw error
  }

  static async getCurrentUser() {
    const { data: { user }, error } = await supabase.auth.getUser()
    if (error) throw error
    return user
  }

  static async getCurrentSession() {
    const { data: { session }, error } = await supabase.auth.getSession()
    if (error) throw error
    return session
  }

  static onAuthStateChange(callback: (event: string, session: any) => void) {
    return supabase.auth.onAuthStateChange(callback)
  }
}