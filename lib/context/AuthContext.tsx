/**
 * Authentication Context Provider (Better Auth)
 *
 * Migrated from Supabase Auth to Better Auth
 *
 * Features:
 * - Global auth state management
 * - V8-optimized with stable context value
 * - Cross-tab synchronization
 * - Automatic session refresh
 * - Demo mode support (for development)
 * - OAuth providers (Google, Apple)
 */

'use client'

import React, { createContext, useContext, useEffect, useState, useCallback, useMemo, useRef } from 'react'
import { useSession as useBetterAuthSession, signIn as betterAuthSignIn, signOut as betterAuthSignOut, signUp as betterAuthSignUp, authClient } from '@/lib/auth-client'
import type { Session, SessionData, User } from '@/lib/auth'

// Auth context value with stable shape
interface AuthContextValue {
  user: User | null
  session: SessionData | null
  isLoading: boolean
  isAuthenticated: boolean
  error: Error | null
  signIn: (email: string, password: string) => Promise<any>
  signUp: (email: string, password: string, metadata?: Record<string, any>) => Promise<any>
  signInWithOAuth: (provider: 'google' | 'apple' | 'facebook') => Promise<any>
  signOut: () => Promise<any>
  resetPassword: (email: string) => Promise<any>
  updatePassword: (newPassword: string) => Promise<any>
  refreshSession: () => Promise<void>
}

// Frozen default context value (V8 optimization)
const defaultContextValue: AuthContextValue = Object.freeze({
  user: null,
  session: null,
  isLoading: true,
  isAuthenticated: false,
  error: null,
  signIn: async () => ({ data: null, error: null }),
  signUp: async () => ({ data: null, error: null }),
  signInWithOAuth: async () => ({ data: null, error: null }),
  signOut: async () => ({ error: null }),
  resetPassword: async () => ({ error: null }),
  updatePassword: async () => ({ data: null, error: null }),
  refreshSession: async () => {}
}) as AuthContextValue

// Create context
const AuthContext = createContext<AuthContextValue>(defaultContextValue)

// Provider props
interface AuthProviderProps {
  children: React.ReactNode
  initialSession?: Session | null
}

/**
 * Authentication Provider Component
 * Wraps the app to provide auth state globally
 */
export function AuthProvider({ children, initialSession }: AuthProviderProps) {
  // Use Better Auth session hook
  const { data: betterAuthSession, isPending } = useBetterAuthSession()

  const [user, setUser] = useState<User | null>(initialSession?.user || null)
  const [session, setSession] = useState<SessionData | null>(initialSession?.session || null)
  const [isLoading, setIsLoading] = useState(!initialSession)
  const [error, setError] = useState<Error | null>(null)

  const mountedRef = useRef(true)
  const initializingRef = useRef(false)

  // Sync Better Auth session to local state
  useEffect(() => {
    setIsLoading(isPending)

    if (betterAuthSession) {
      // betterAuthSession has structure: { session: SessionData, user: User }
      setSession(betterAuthSession.session)
      setUser(betterAuthSession.user as User)
      setError(null)
    } else {
      // Check for demo session if no Better Auth session
      checkDemoSession()
    }
  }, [betterAuthSession, isPending])

  // Check for demo session (development only)
  const checkDemoSession = () => {
    if (typeof window === 'undefined') return

    const demoSession = localStorage.getItem('demo_session')
    const demoUser = localStorage.getItem('demo_user')

    if (demoSession && demoUser) {
      try {
        const parsedSession = JSON.parse(demoSession)
        const parsedUser = JSON.parse(demoUser)

        // Check if demo session is still valid (1 hour)
        if (parsedSession.expiresAt && parsedSession.expiresAt > Date.now()) {
          setSession(parsedSession)
          setUser(parsedUser)
          setIsLoading(false)
          return
        } else {
          // Clear expired demo session
          localStorage.removeItem('demo_session')
          localStorage.removeItem('demo_user')
        }
      } catch (err) {
        console.error('Failed to parse demo session:', err)
        localStorage.removeItem('demo_session')
        localStorage.removeItem('demo_user')
      }
    }

    // No demo session
    if (!betterAuthSession) {
      setSession(null)
      setUser(null)
    }
  }

  // Cross-tab synchronization
  useEffect(() => {
    if (typeof window === 'undefined') return

    const handleStorageChange = (e: StorageEvent) => {
      if (!mountedRef.current) return

      if (e.key === 'auth_event' && e.newValue) {
        try {
          const event = JSON.parse(e.newValue)
          console.log('Cross-tab auth event:', event)

          // Re-check session on cross-tab changes
          if (event.event === 'SIGNED_IN') {
            window.location.reload() // Trigger Better Auth session refresh
          } else if (event.event === 'SIGNED_OUT') {
            setSession(null)
            setUser(null)
            localStorage.removeItem('demo_session')
            localStorage.removeItem('demo_user')
          }
        } catch (err) {
          console.error('Failed to parse auth event:', err)
        }
      }
    }

    window.addEventListener('storage', handleStorageChange)

    return () => {
      window.removeEventListener('storage', handleStorageChange)
    }
  }, [])

  // Cleanup on unmount
  useEffect(() => {
    mountedRef.current = true
    return () => {
      mountedRef.current = false
    }
  }, [])

  // Sign in method with demo support
  const signIn = useCallback(async (email: string, password: string) => {
    setIsLoading(true)
    setError(null)

    try {
      const result = await betterAuthSignIn.email({
        email,
        password,
      })

      if (result.error) {
        const error = new Error(result.error.message || 'Sign in failed')
        setError(error)
        setIsLoading(false)
        return { data: null, error }
      }

      // Broadcast sign-in event for cross-tab sync
      if (typeof window !== 'undefined') {
        localStorage.setItem('auth_event', JSON.stringify({
          event: 'SIGNED_IN',
          timestamp: Date.now()
        }))
      }

      setIsLoading(false)
      return { data: result.data, error: null }
    } catch (err) {
      const error = err instanceof Error ? err : new Error('Sign in failed')
      setError(error)
      setIsLoading(false)
      return { data: null, error }
    }
  }, [])

  // Sign up method
  const signUp = useCallback(async (
    email: string,
    password: string,
    metadata?: Record<string, any>
  ) => {
    setIsLoading(true)
    setError(null)

    try {
      // Handle both camelCase and snake_case metadata for compatibility
      const firstName = metadata?.firstName || metadata?.first_name
      const lastName = metadata?.lastName || metadata?.last_name
      const businessName = metadata?.businessName || metadata?.business_name
      const role = metadata?.role
      const accountType = metadata?.accountType || metadata?.role // Use role as accountType if not specified

      const result = await betterAuthSignUp.email({
        email,
        password,
        name: metadata?.name || (firstName && lastName)
          ? `${firstName} ${lastName}`
          : undefined,
        // Map additional metadata to user fields
        ...(role && { role }),
        ...(businessName && { businessName }),
        ...(accountType && { accountType }),
        ...(firstName && { firstName }),
        ...(lastName && { lastName }),
      })

      if (result.error) {
        const error = new Error(result.error.message || 'Sign up failed')
        setError(error)
        setIsLoading(false)
        return { data: null, error }
      }

      setIsLoading(false)
      return { data: result.data, error: null }
    } catch (err) {
      const error = err instanceof Error ? err : new Error('Sign up failed')
      setError(error)
      setIsLoading(false)
      return { data: null, error }
    }
  }, [])

  // OAuth sign in method
  const signInWithOAuth = useCallback(async (
    provider: 'google' | 'apple' | 'facebook'
  ) => {
    setIsLoading(true)
    setError(null)

    try {
      // Better Auth OAuth is slightly different - it redirects immediately
      if (provider === 'facebook') {
        const error = new Error('Facebook OAuth is not configured yet')
        setError(error)
        setIsLoading(false)
        return { data: null, error }
      }

      const result = await betterAuthSignIn.social({
        provider: provider as 'google' | 'apple',
        callbackURL: '/dashboard',
      })

      // OAuth redirects, so loading state persists
      // Will be cleared after redirect completes
      return { data: result.data, error: null }
    } catch (err) {
      const error = err instanceof Error ? err : new Error('OAuth sign in failed')
      setError(error)
      setIsLoading(false)
      return { data: null, error }
    }
  }, [])

  // Sign out method
  const signOut = useCallback(async () => {
    setIsLoading(true)
    setError(null)

    try {
      // Clear demo session if it exists
      if (typeof window !== 'undefined') {
        localStorage.removeItem('demo_session')
        localStorage.removeItem('demo_user')
      }

      await betterAuthSignOut()

      // Broadcast sign-out event for cross-tab sync
      if (typeof window !== 'undefined') {
        localStorage.setItem('auth_event', JSON.stringify({
          event: 'SIGNED_OUT',
          timestamp: Date.now()
        }))
      }

      if (mountedRef.current) {
        setSession(null)
        setUser(null)
        setIsLoading(false)
      }

      return { error: null }
    } catch (err) {
      const error = err instanceof Error ? err : new Error('Sign out failed')
      setError(error)
      setIsLoading(false)
      return { error }
    }
  }, [])

  // Reset password method
  const resetPassword = useCallback(async (email: string) => {
    try {
      // Better Auth handles password reset via forgetPassword
      const result = await authClient.forgetPassword({
        email,
        redirectTo: `${window.location.origin}/auth/reset-password`,
      })

      if (result.error) {
        const error = new Error(result.error.message || 'Password reset failed')
        setError(error)
        return { error }
      }

      return { error: null }
    } catch (err) {
      const error = err instanceof Error ? err : new Error('Password reset failed')
      setError(error)
      return { error }
    }
  }, [])

  // Update password method
  const updatePassword = useCallback(async (newPassword: string) => {
    try {
      const result = await authClient.changePassword({
        newPassword,
        currentPassword: '', // Better Auth requires current password - this needs to be passed in
      })

      if (result.error) {
        const error = new Error(result.error.message || 'Password update failed')
        setError(error)
        return { data: null, error }
      }

      return { data: result.data?.user, error: null }
    } catch (err) {
      const error = err instanceof Error ? err : new Error('Password update failed')
      setError(error)
      return { data: null, error }
    }
  }, [])

  // Refresh session method
  const refreshSession = useCallback(async () => {
    try {
      // Better Auth automatically handles session refresh
      // Force a session check
      const result = await authClient.getSession()

      if (mountedRef.current) {
        if (result.data) {
          // result.data has structure: { session: SessionData, user: User }
          setSession(result.data.session)
          setUser(result.data.user as User)
          setError(null)
        } else {
          setSession(null)
          setUser(null)
        }
      }
    } catch (err) {
      const error = err instanceof Error ? err : new Error('Session refresh failed')
      setError(error)
    }
  }, [])

  // Memoize context value for V8 optimization
  const contextValue = useMemo<AuthContextValue>(() => ({
    user,
    session,
    isLoading,
    isAuthenticated: !!session,
    error,
    signIn,
    signUp,
    signInWithOAuth,
    signOut,
    resetPassword,
    updatePassword,
    refreshSession
  }), [
    user,
    session,
    isLoading,
    error,
    signIn,
    signUp,
    signInWithOAuth,
    signOut,
    resetPassword,
    updatePassword,
    refreshSession
  ])

  return (
    <AuthContext.Provider value={contextValue}>
      {children}
    </AuthContext.Provider>
  )
}

/**
 * Hook to use auth context
 * Throws error if used outside of AuthProvider
 */
export function useAuthContext() {
  const context = useContext(AuthContext)

  if (context === defaultContextValue) {
    throw new Error('useAuthContext must be used within an AuthProvider')
  }

  return context
}

/**
 * HOC to wrap components with auth provider
 * Useful for testing or isolated auth contexts
 */
export function withAuth<P extends object>(
  Component: React.ComponentType<P>
) {
  return function AuthWrappedComponent(props: P) {
    return (
      <AuthProvider>
        <Component {...props} />
      </AuthProvider>
    )
  }
}
