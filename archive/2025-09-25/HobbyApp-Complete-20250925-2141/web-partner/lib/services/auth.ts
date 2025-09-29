/**
 * Optimized Authentication Service for Supabase
 * 
 * Features:
 * - V8-optimized with stable object shapes
 * - LRU cache for session data
 * - Request deduplication
 * - Automatic token refresh
 * - Cross-tab synchronization
 */

import { supabase } from '../supabase'
import type { User, Session, AuthError } from '@supabase/supabase-js'
import type { Database } from '../../types/supabase'

// Stable shape for user profile (V8 optimization)
interface UserProfile {
  id: string
  email: string
  role: 'student' | 'instructor' | 'admin'
  profile: {
    firstName: string
    lastName: string
    phone: string
    avatarUrl: string
    bio: string
  } | null
  instructor: {
    businessName: string
    verified: boolean
    rating: number
    totalStudents: number
    specialties: string[]
  } | null
  createdAt: string
  updatedAt: string
}

// Stable shape for auth response
interface AuthResponse<T = any> {
  data: T | null
  error: AuthError | null
  cached: boolean
  timestamp: number
}

// LRU Cache for session and user data
class AuthCache {
  private cache = new Map<string, { data: any; timestamp: number }>()
  private readonly maxSize = 50
  private readonly ttl = 60000 // 60 seconds

  set(key: string, data: any): void {
    // Maintain LRU order
    if (this.cache.size >= this.maxSize) {
      const firstKey = this.cache.keys().next().value
      this.cache.delete(firstKey)
    }
    
    this.cache.set(key, {
      data: Object.freeze(data), // Freeze for V8 optimization
      timestamp: Date.now()
    })
  }

  get(key: string): any | null {
    const cached = this.cache.get(key)
    
    if (!cached) return null
    
    // Check TTL
    if (Date.now() - cached.timestamp > this.ttl) {
      this.cache.delete(key)
      return null
    }
    
    // Move to end (LRU)
    this.cache.delete(key)
    this.cache.set(key, cached)
    
    return cached.data
  }

  clear(): void {
    this.cache.clear()
  }

  invalidate(pattern: string): void {
    for (const key of this.cache.keys()) {
      if (key.includes(pattern)) {
        this.cache.delete(key)
      }
    }
  }
}

// Request deduplication
class RequestDeduplicator {
  private pending = new Map<string, Promise<any>>()

  async deduplicate<T>(
    key: string,
    fn: () => Promise<T>
  ): Promise<T> {
    const existing = this.pending.get(key)
    if (existing) return existing

    const promise = fn().finally(() => {
      this.pending.delete(key)
    })

    this.pending.set(key, promise)
    return promise
  }
}

export class AuthService {
  private static instance: AuthService
  private cache = new AuthCache()
  private deduplicator = new RequestDeduplicator()
  private sessionRefreshTimer: NodeJS.Timeout | null = null

  private constructor() {
    // Set up auth state change listener
    supabase.auth.onAuthStateChange((event, session) => {
      this.handleAuthStateChange(event, session)
    })
  }

  static getInstance(): AuthService {
    if (!AuthService.instance) {
      AuthService.instance = new AuthService()
    }
    return AuthService.instance
  }

  // Handle auth state changes
  private handleAuthStateChange(event: string, session: Session | null): void {
    // Clear cache on sign out
    if (event === 'SIGNED_OUT') {
      this.cache.clear()
      this.clearSessionRefreshTimer()
    }
    
    // Cache new session
    if (event === 'SIGNED_IN' || event === 'TOKEN_REFRESHED') {
      if (session) {
        this.cache.set('session', this.normalizeSession(session))
        this.setupSessionRefreshTimer(session)
      }
    }
    
    // Broadcast to other tabs
    if (typeof window !== 'undefined') {
      window.localStorage.setItem('auth_event', JSON.stringify({
        event,
        timestamp: Date.now()
      }))
    }
  }

  // Normalize session to stable shape (V8 optimization)
  private normalizeSession(session: Session): Session {
    return {
      access_token: session.access_token || '',
      refresh_token: session.refresh_token || '',
      expires_in: session.expires_in || 0,
      expires_at: session.expires_at || 0,
      token_type: session.token_type || 'bearer',
      user: session.user ? this.normalizeUser(session.user) : null
    } as Session
  }

  // Normalize user to stable shape (V8 optimization)
  private normalizeUser(user: User): User {
    return {
      id: user.id || '',
      aud: user.aud || '',
      role: user.role || '',
      email: user.email || '',
      email_confirmed_at: user.email_confirmed_at || '',
      phone: user.phone || '',
      confirmed_at: user.confirmed_at || '',
      last_sign_in_at: user.last_sign_in_at || '',
      app_metadata: user.app_metadata || {},
      user_metadata: user.user_metadata || {},
      identities: user.identities || [],
      created_at: user.created_at || '',
      updated_at: user.updated_at || ''
    } as User
  }

  // Setup automatic session refresh
  private setupSessionRefreshTimer(session: Session): void {
    this.clearSessionRefreshTimer()
    
    // Refresh 5 minutes before expiry
    const expiresAt = session.expires_at || 0
    const now = Math.floor(Date.now() / 1000)
    const timeUntilRefresh = (expiresAt - now - 300) * 1000
    
    if (timeUntilRefresh > 0) {
      this.sessionRefreshTimer = setTimeout(() => {
        this.refreshSession()
      }, timeUntilRefresh)
    }
  }

  private clearSessionRefreshTimer(): void {
    if (this.sessionRefreshTimer) {
      clearTimeout(this.sessionRefreshTimer)
      this.sessionRefreshTimer = null
    }
  }

  // Sign in with email and password
  async signInWithEmail(
    email: string,
    password: string
  ): Promise<AuthResponse<Session>> {
    return this.deduplicator.deduplicate(
      `signin_${email}`,
      async () => {
        const { data, error } = await supabase.auth.signInWithPassword({
          email,
          password
        })

        if (data?.session) {
          this.cache.set('session', this.normalizeSession(data.session))
        }

        return {
          data: data?.session || null,
          error,
          cached: false,
          timestamp: Date.now()
        }
      }
    )
  }

  // Sign up with email and password
  async signUp(
    email: string,
    password: string,
    metadata?: Record<string, any>
  ): Promise<AuthResponse<Session>> {
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: metadata
      }
    })

    if (data?.session) {
      this.cache.set('session', this.normalizeSession(data.session))
    }

    return {
      data: data?.session || null,
      error,
      cached: false,
      timestamp: Date.now()
    }
  }

  // Sign in with OAuth provider
  async signInWithOAuth(
    provider: 'google' | 'apple' | 'facebook'
  ): Promise<AuthResponse<{ url: string }>> {
    const { data, error } = await supabase.auth.signInWithOAuth({
      provider,
      options: {
        redirectTo: `${window.location.origin}/auth/callback`,
        scopes: provider === 'google' ? 'email profile' : undefined
      }
    })

    return {
      data: data?.url ? { url: data.url } : null,
      error,
      cached: false,
      timestamp: Date.now()
    }
  }

  // Sign out
  async signOut(): Promise<AuthResponse<null>> {
    const { error } = await supabase.auth.signOut()
    
    this.cache.clear()
    this.clearSessionRefreshTimer()

    return {
      data: null,
      error,
      cached: false,
      timestamp: Date.now()
    }
  }

  // Get current session
  async getSession(): Promise<AuthResponse<Session>> {
    // Check cache first
    const cached = this.cache.get('session')
    if (cached) {
      return {
        data: cached,
        error: null,
        cached: true,
        timestamp: Date.now()
      }
    }

    // Deduplicate concurrent requests
    return this.deduplicator.deduplicate(
      'get_session',
      async () => {
        const { data, error } = await supabase.auth.getSession()

        if (data?.session) {
          const normalized = this.normalizeSession(data.session)
          this.cache.set('session', normalized)
          this.setupSessionRefreshTimer(data.session)
        }

        return {
          data: data?.session || null,
          error,
          cached: false,
          timestamp: Date.now()
        }
      }
    )
  }

  // Get current user
  async getUser(): Promise<AuthResponse<User>> {
    // Check cache first
    const cachedSession = this.cache.get('session')
    if (cachedSession?.user) {
      return {
        data: cachedSession.user,
        error: null,
        cached: true,
        timestamp: Date.now()
      }
    }

    // Deduplicate concurrent requests
    return this.deduplicator.deduplicate(
      'get_user',
      async () => {
        const { data, error } = await supabase.auth.getUser()

        if (data?.user) {
          const normalized = this.normalizeUser(data.user)
          // Update cached session with user
          const session = this.cache.get('session')
          if (session) {
            session.user = normalized
            this.cache.set('session', session)
          }
        }

        return {
          data: data?.user || null,
          error,
          cached: false,
          timestamp: Date.now()
        }
      }
    )
  }

  // Get user profile with related data
  async getUserProfile(): Promise<AuthResponse<UserProfile>> {
    const cacheKey = 'user_profile'
    
    // Check cache first
    const cached = this.cache.get(cacheKey)
    if (cached) {
      return {
        data: cached,
        error: null,
        cached: true,
        timestamp: Date.now()
      }
    }

    return this.deduplicator.deduplicate(
      cacheKey,
      async () => {
        const { data: { user }, error: userError } = await supabase.auth.getUser()
        
        if (userError || !user) {
          return {
            data: null,
            error: userError,
            cached: false,
            timestamp: Date.now()
          }
        }

        // Fetch profile and instructor data in parallel
        const [profileResult, instructorResult] = await Promise.all([
          supabase
            .from('user_profiles')
            .select('*')
            .eq('user_id', user.id)
            .single(),
          supabase
            .from('instructors')
            .select('*')
            .eq('user_id', user.id)
            .single()
        ])

        // Create stable shape profile
        const profile: UserProfile = {
          id: user.id,
          email: user.email || '',
          role: user.user_metadata?.role || 'student',
          profile: profileResult.data ? {
            firstName: profileResult.data.first_name || '',
            lastName: profileResult.data.last_name || '',
            phone: profileResult.data.phone || '',
            avatarUrl: profileResult.data.avatar_url || '',
            bio: profileResult.data.bio || ''
          } : null,
          instructor: instructorResult.data ? {
            businessName: instructorResult.data.business_name || '',
            verified: instructorResult.data.verified || false,
            rating: instructorResult.data.rating || 0,
            totalStudents: instructorResult.data.total_students || 0,
            specialties: instructorResult.data.specialties || []
          } : null,
          createdAt: user.created_at,
          updatedAt: user.updated_at || ''
        }

        // Cache the profile
        this.cache.set(cacheKey, profile)

        return {
          data: profile,
          error: null,
          cached: false,
          timestamp: Date.now()
        }
      }
    )
  }

  // Refresh session
  async refreshSession(): Promise<AuthResponse<Session>> {
    const { data, error } = await supabase.auth.refreshSession()

    if (data?.session) {
      const normalized = this.normalizeSession(data.session)
      this.cache.set('session', normalized)
      this.setupSessionRefreshTimer(data.session)
    }

    return {
      data: data?.session || null,
      error,
      cached: false,
      timestamp: Date.now()
    }
  }

  // Reset password
  async resetPassword(email: string): Promise<AuthResponse<null>> {
    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/auth/reset-password`
    })

    return {
      data: null,
      error,
      cached: false,
      timestamp: Date.now()
    }
  }

  // Update password
  async updatePassword(newPassword: string): Promise<AuthResponse<User>> {
    const { data, error } = await supabase.auth.updateUser({
      password: newPassword
    })

    return {
      data: data?.user || null,
      error,
      cached: false,
      timestamp: Date.now()
    }
  }

  // Clear all caches
  clearCache(): void {
    this.cache.clear()
  }
}

// Export singleton instance
export const authService = AuthService.getInstance()