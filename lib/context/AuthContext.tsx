/**
 * Authentication Context Provider
 * 
 * Features:
 * - Global auth state management
 * - V8-optimized with stable context value
 * - Cross-tab synchronization
 * - Automatic session refresh
 */

'use client'

import React, { createContext, useContext, useEffect, useState, useCallback, useMemo, useRef } from 'react'
import type { User, Session } from '@supabase/supabase-js'
import { authService } from '../services/auth'
import { supabase } from '../supabase'

// Auth context value with stable shape
interface AuthContextValue {
  user: User | null
  session: Session | null
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
  const [user, setUser] = useState<User | null>(initialSession?.user || null)
  const [session, setSession] = useState<Session | null>(initialSession || null)
  const [isLoading, setIsLoading] = useState(!initialSession)
  const [error, setError] = useState<Error | null>(null)
  
  const mountedRef = useRef(true)
  const initializingRef = useRef(false)

  // Initialize auth state
  useEffect(() => {
    mountedRef.current = true

    const initializeAuth = async () => {
      if (initializingRef.current || initialSession) return
      initializingRef.current = true

      try {
        // Check for demo session first
        if (typeof window !== 'undefined') {
          const demoSession = localStorage.getItem('demo_session')
          const demoUser = localStorage.getItem('demo_user')
          
          if (demoSession && demoUser) {
            const session = JSON.parse(demoSession)
            const user = JSON.parse(demoUser)
            
            // Check if demo session is still valid (1 hour)
            if (session.expires_at && session.expires_at > Math.floor(Date.now() / 1000)) {
              if (mountedRef.current) {
                setSession(session)
                setUser(user)
                setIsLoading(false)
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

        if (error) {
          setError(new Error(error.message))
        } else {
          setSession(data)
          setUser(data?.user || null)
        }
      } catch (err) {
        if (!mountedRef.current) return
        setError(err instanceof Error ? err : new Error('Auth initialization failed'))
      } finally {
        if (mountedRef.current) {
          setIsLoading(false)
        }
      }
    }

    initializeAuth()

    // Subscribe to auth state changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event, newSession) => {
        if (!mountedRef.current) return

        console.log('Auth state changed:', event)
        
        setSession(newSession)
        setUser(newSession?.user || null)
        setIsLoading(false)
        setError(null)

        // Handle specific events
        switch (event) {
          case 'SIGNED_IN':
            // Prefetch user profile after sign in
            authService.getUserProfile()
            break
          case 'SIGNED_OUT':
            // Clear all cached data
            authService.clearCache()
            break
          case 'TOKEN_REFRESHED':
            console.log('Token refreshed successfully')
            break
          case 'USER_UPDATED':
            // Invalidate user profile cache
            authService.clearCache()
            authService.getUserProfile()
            break
        }
      }
    )

    // Listen for cross-tab auth events
    const handleStorageChange = (e: StorageEvent) => {
      if (e.key === 'auth_event' && e.newValue && mountedRef.current) {
        try {
          const event = JSON.parse(e.newValue)
          console.log('Cross-tab auth event:', event)
          
          // Re-initialize auth on cross-tab changes
          if (event.event === 'SIGNED_IN' || event.event === 'SIGNED_OUT') {
            initializeAuth()
          }
        } catch (err) {
          console.error('Failed to parse auth event:', err)
        }
      }
    }

    if (typeof window !== 'undefined') {
      window.addEventListener('storage', handleStorageChange)
    }

    return () => {
      mountedRef.current = false
      subscription.unsubscribe()
      if (typeof window !== 'undefined') {
        window.removeEventListener('storage', handleStorageChange)
      }
    }
  }, [initialSession])

  // Sign in method with demo support
  const signIn = useCallback(async (email: string, password: string) => {
    setIsLoading(true)
    setError(null)

    // SECURITY: Demo credentials have been removed
    // All authentication must go through proper Supabase auth

    // Regular authentication flow
    const { data, error } = await authService.signInWithEmail(email, password)
    
    if (mountedRef.current) {
      if (error) {
        setError(new Error(error.message))
      } else {
        setSession(data)
        setUser(data?.user || null)
      }
      setIsLoading(false)
    }

    return { data, error }
  }, [])

  // Sign up method
  const signUp = useCallback(async (
    email: string,
    password: string,
    metadata?: Record<string, any>
  ) => {
    setIsLoading(true)
    setError(null)
    
    const { data, error } = await authService.signUp(email, password, metadata)
    
    if (mountedRef.current) {
      if (error) {
        setError(new Error(error.message))
      } else {
        setSession(data)
        setUser(data?.user || null)
      }
      setIsLoading(false)
    }

    return { data, error }
  }, [])

  // OAuth sign in method
  const signInWithOAuth = useCallback(async (
    provider: 'google' | 'apple' | 'facebook'
  ) => {
    setIsLoading(true)
    setError(null)
    
    const { data, error } = await authService.signInWithOAuth(provider)
    
    if (mountedRef.current) {
      if (error) {
        setError(new Error(error.message))
        setIsLoading(false)
      }
      // Loading state will be cleared by auth state change listener
    }

    return { data, error }
  }, [])

  // Sign out method
  const signOut = useCallback(async () => {
    setIsLoading(true)
    setError(null)
    
    // Clear demo session if it exists
    if (typeof window !== 'undefined') {
      localStorage.removeItem('demo_session')
      localStorage.removeItem('demo_user')
    }
    
    const { error } = await authService.signOut()
    
    if (mountedRef.current) {
      if (error) {
        setError(new Error(error.message))
      } else {
        setSession(null)
        setUser(null)
      }
      setIsLoading(false)
    }

    return { error }
  }, [])

  // Reset password method
  const resetPassword = useCallback(async (email: string) => {
    const { error } = await authService.resetPassword(email)
    
    if (mountedRef.current && error) {
      setError(new Error(error.message))
    }

    return { error }
  }, [])

  // Update password method
  const updatePassword = useCallback(async (newPassword: string) => {
    const { data, error } = await authService.updatePassword(newPassword)
    
    if (mountedRef.current) {
      if (error) {
        setError(new Error(error.message))
      } else if (data) {
        setUser(data)
      }
    }

    return { data, error }
  }, [])

  // Refresh session method
  const refreshSession = useCallback(async () => {
    const { data, error } = await authService.refreshSession()
    
    if (mountedRef.current) {
      if (error) {
        setError(new Error(error.message))
      } else {
        setSession(data)
        setUser(data?.user || null)
      }
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