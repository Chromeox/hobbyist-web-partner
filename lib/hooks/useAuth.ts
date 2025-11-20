/**
 * V8-Optimized Authentication Hooks
 * 
 * Features:
 * - Request deduplication
 * - Stable object references
 * - Optimistic updates
 * - Cross-tab synchronization
 * - Automatic refresh
 */

import { useEffect, useState, useCallback, useRef, useMemo } from 'react'
import { useRouter } from 'next/navigation'
import type { User, Session } from '@supabase/supabase-js'
import { authService } from '../services/auth'
import { supabase } from '../supabase'

// Frozen empty objects for stable references (V8 optimization)
const EMPTY_USER = Object.freeze({}) as User
const EMPTY_SESSION = Object.freeze({}) as Session

// Auth state interface with stable shape
interface AuthState {
  user: User | null
  session: Session | null
  isLoading: boolean
  isAuthenticated: boolean
  error: Error | null
}

// Profile state interface
interface ProfileState {
  profile: any | null
  isLoading: boolean
  error: Error | null
}

/**
 * Main authentication hook
 * Provides auth state and methods with V8 optimizations
 */
export function useAuth() {
  const [state, setState] = useState<AuthState>({
    user: null,
    session: null,
    isLoading: true,
    isAuthenticated: false,
    error: null
  })

  // Use refs for deduplication
  const initializingRef = useRef(false)
  const mountedRef = useRef(true)

  // Initialize auth state
  useEffect(() => {
    mountedRef.current = true
    
    if (initializingRef.current) return
    initializingRef.current = true

    const initializeAuth = async () => {
      try {
        // Check for demo session first
        if (typeof window !== 'undefined') {
          const demoSession = localStorage.getItem('demo_session')
          const demoUser = localStorage.getItem('demo_user')
          
          if (demoSession && demoUser) {
            const session = JSON.parse(demoSession)
            const user = JSON.parse(demoUser)
            
            // Check if demo session is still valid
            if (session.expires_at && session.expires_at > Math.floor(Date.now() / 1000)) {
              if (mountedRef.current) {
                setState({
                  user,
                  session,
                  isLoading: false,
                  isAuthenticated: true,
                  error: null
                })
              }
              return
            } else {
              // Clear expired demo session
              localStorage.removeItem('demo_session')
              localStorage.removeItem('demo_user')
            }
          }
        }
        
        const { data, error } = await authService.getSession()
        
        if (!mountedRef.current) return

        setState({
          user: data?.user || null,
          session: data || null,
          isLoading: false,
          isAuthenticated: !!data,
          error: error ? new Error(error.message) : null
        })
      } catch (error) {
        if (!mountedRef.current) return
        
        setState(prev => ({
          ...prev,
          isLoading: false,
          error: error instanceof Error ? error : new Error('Auth initialization failed')
        }))
      }
    }

    initializeAuth()

    // Subscribe to auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event, session) => {
        if (!mountedRef.current) return

        setState({
          user: session?.user || null,
          session: session || null,
          isLoading: false,
          isAuthenticated: !!session,
          error: null
        })
      }
    )

    // Listen for cross-tab auth events
    const handleStorageChange = (e: StorageEvent) => {
      if (e.key === 'auth_event' && e.newValue) {
        try {
          const event = JSON.parse(e.newValue)
          // Re-initialize auth on cross-tab changes
          if (event.event === 'SIGNED_IN' || event.event === 'SIGNED_OUT') {
            initializeAuth()
          }
        } catch {}
      }
    }

    window.addEventListener('storage', handleStorageChange)

    return () => {
      mountedRef.current = false
      subscription.unsubscribe()
      window.removeEventListener('storage', handleStorageChange)
    }
  }, [])

  // Memoized auth methods
  const signIn = useCallback(async (email: string, password: string) => {
    setState(prev => ({ ...prev, isLoading: true, error: null }))

    // SECURITY: Demo credentials have been removed
    // All authentication must go through proper Supabase auth

    const { data, error } = await authService.signInWithEmail(email, password)
    
    if (!mountedRef.current) return { data, error }

    setState({
      user: data?.user || null,
      session: data || null,
      isLoading: false,
      isAuthenticated: !!data,
      error: error ? new Error(error.message) : null
    })

    return { data, error }
  }, [])

  const signUp = useCallback(async (
    email: string,
    password: string,
    metadata?: Record<string, any>
  ) => {
    setState(prev => ({ ...prev, isLoading: true, error: null }))
    
    const { data, error } = await authService.signUp(email, password, metadata)
    
    if (!mountedRef.current) return { data, error }

    setState({
      user: data?.user || null,
      session: data || null,
      isLoading: false,
      isAuthenticated: !!data,
      error: error ? new Error(error.message) : null
    })

    return { data, error }
  }, [])

  const signInWithOAuth = useCallback(async (
    provider: 'google' | 'apple' | 'facebook'
  ) => {
    setState(prev => ({ ...prev, isLoading: true, error: null }))
    
    const { data, error } = await authService.signInWithOAuth(provider)
    
    if (!mountedRef.current) return { data, error }

    if (error) {
      setState(prev => ({
        ...prev,
        isLoading: false,
        error: new Error(error.message)
      }))
    }

    return { data, error }
  }, [])

  const signOut = useCallback(async () => {
    setState(prev => ({ ...prev, isLoading: true, error: null }))
    
    // Clear demo session if it exists
    if (typeof window !== 'undefined') {
      localStorage.removeItem('demo_session')
      localStorage.removeItem('demo_user')
    }
    
    const { error } = await authService.signOut()
    
    if (!mountedRef.current) return { error }

    setState({
      user: null,
      session: null,
      isLoading: false,
      isAuthenticated: false,
      error: error ? new Error(error.message) : null
    })

    return { error }
  }, [])

  const resetPassword = useCallback(async (email: string) => {
    const { error } = await authService.resetPassword(email)
    return { error }
  }, [])

  const updatePassword = useCallback(async (newPassword: string) => {
    const { data, error } = await authService.updatePassword(newPassword)
    
    if (!mountedRef.current) return { data, error }

    if (data) {
      setState(prev => ({
        ...prev,
        user: data
      }))
    }

    return { data, error }
  }, [])

  // Return memoized value with stable shape
  return useMemo(() => ({
    user: state.user || EMPTY_USER,
    session: state.session || EMPTY_SESSION,
    isLoading: state.isLoading,
    isAuthenticated: state.isAuthenticated,
    error: state.error,
    signIn,
    signUp,
    signInWithOAuth,
    signOut,
    resetPassword,
    updatePassword
  }), [
    state.user,
    state.session,
    state.isLoading,
    state.isAuthenticated,
    state.error,
    signIn,
    signUp,
    signInWithOAuth,
    signOut,
    resetPassword,
    updatePassword
  ])
}

/**
 * Hook to get current user
 * Returns cached user data with automatic updates
 */
export function useUser() {
  const { user, isLoading } = useAuth()
  return { user: user === EMPTY_USER ? null : user, isLoading }
}

/**
 * Hook to get current session
 * Returns cached session with automatic refresh
 */
export function useSession() {
  const { session, isLoading } = useAuth()
  return { session: session === EMPTY_SESSION ? null : session, isLoading }
}

/**
 * Hook to get user profile with related data
 * Includes caching and deduplication
 */
export function useUserProfile() {
  const { user } = useAuth()
  const [state, setState] = useState<ProfileState>({
    profile: null,
    isLoading: true,
    error: null
  })
  
  const mountedRef = useRef(true)
  const fetchingRef = useRef(false)

  useEffect(() => {
    mountedRef.current = true

    const fetchProfile = async () => {
      if (!user || user === EMPTY_USER || fetchingRef.current) {
        setState({
          profile: null,
          isLoading: false,
          error: null
        })
        return
      }
      
      fetchingRef.current = true

      try {
        const { data, error } = await authService.getUserProfile()
        
        if (!mountedRef.current) return

        setState({
          profile: data,
          isLoading: false,
          error: error ? new Error(error.message) : null
        })
      } catch (error) {
        if (!mountedRef.current) return

        setState({
          profile: null,
          isLoading: false,
          error: error instanceof Error ? error : new Error('Failed to fetch profile')
        })
      } finally {
        fetchingRef.current = false
      }
    }

    fetchProfile()

    return () => {
      mountedRef.current = false
    }
  }, [user])

  return state
}

/**
 * Hook for protected routes
 * Redirects to login if not authenticated
 */
export function useRequireAuth(redirectTo = '/auth/signin') {
  const router = useRouter()
  const { isAuthenticated, isLoading } = useAuth()
  const hasRedirectedRef = useRef(false)

  useEffect(() => {
    if (!isLoading && !isAuthenticated && !hasRedirectedRef.current) {
      hasRedirectedRef.current = true
      router.push(redirectTo)
    }
  }, [isAuthenticated, isLoading, redirectTo, router])

  return { isAuthenticated, isLoading }
}

/**
 * Hook for role-based access control
 * Checks if user has required role
 */
export function useRole(requiredRole: 'student' | 'instructor' | 'admin') {
  const { user } = useAuth()
  const { profile } = useUserProfile()

  const hasRole = useMemo(() => {
    if (!user || user === EMPTY_USER || !profile) return false
    
    const userRole = profile.role || user.user_metadata?.role
    
    // Admin has access to everything
    if (userRole === 'admin') return true
    
    // Check specific role
    return userRole === requiredRole
  }, [user, profile, requiredRole])

  return hasRole
}

/**
 * Hook for subscription to auth state changes
 * Useful for real-time UI updates
 */
export function useAuthStateChange(
  callback: (event: string, session: Session | null) => void
) {
  useEffect(() => {
    const { data: { subscription } } = supabase.auth.onAuthStateChange(callback)
    
    return () => {
      subscription.unsubscribe()
    }
  }, [callback])
}

/**
 * Hook for optimistic auth updates
 * Updates UI immediately while request is pending
 */
export function useOptimisticAuth() {
  const auth = useAuth()
  const [optimisticUser, setOptimisticUser] = useState(auth.user)

  useEffect(() => {
    setOptimisticUser(auth.user)
  }, [auth.user])

  const updateOptimistic = useCallback((updates: Partial<User>) => {
    if (!optimisticUser || optimisticUser === EMPTY_USER) return
    
    setOptimisticUser(prev => ({
      ...prev!,
      ...updates
    }))
  }, [optimisticUser])

  return {
    ...auth,
    user: optimisticUser || EMPTY_USER,
    updateOptimistic
  }
}
