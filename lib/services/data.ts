import { supabase } from '../supabase'

export class DataService {
  static async getDashboardStats() {
    const client = supabase as any

    const countRequests = await Promise.all([
      client.from('bookings').select('id', { count: 'exact', head: true }),
      client.from('instructor_profiles').select('id', { count: 'exact', head: true }),
      client.from('classes').select('id', { count: 'exact', head: true }),
      client.from('user_profiles').select('id', { count: 'exact', head: true })
    ])

    const [bookingsCount, instructorsCount, classesCount, usersCount] = countRequests.map(
      ({ count, error }, index) => {
        if (error) {
          console.warn(
            `Failed to load count for dashboard metric index ${index}:`,
            error.message
          )
        }
        return count ?? 0
      }
    )

    const { data: transactions, error: transactionError } = await client
      .from('credit_transactions')
      .select('amount, transaction_type')

    if (transactionError) {
      console.warn('Failed to load credit transactions for revenue stats:', transactionError.message)
    }

    const transactionRows = (transactions ?? []) as Array<{ amount: number }>
    const totalRevenue = transactionRows.reduce((sum, transaction) => {
      return transaction.amount > 0 ? sum + transaction.amount : sum
    }, 0)

    return {
      totalBookings: bookingsCount,
      totalInstructors: instructorsCount,
      totalClasses: classesCount,
      totalUsers: usersCount,
      totalRevenue
    }
  }

  static subscribeToBookings(callback: (payload: any) => void) {
    return supabase
      .channel('bookings_changes')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'bookings' },
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
