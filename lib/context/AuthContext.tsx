/**
 * Authentication Context (Clerk)
 *
 * Provides a compatibility layer for components still using useAuthContext.
 * Wraps Clerk's hooks to maintain the same API signature.
 *
 * For new code, prefer using Clerk hooks directly:
 * - useUser() for user data
 * - useAuth() for auth state
 * - useClerk() for auth methods
 */

'use client'

import { useUser, useClerk, useAuth } from '@clerk/nextjs'
import { useRouter } from 'next/navigation'
import { useCallback, useMemo } from 'react'

// User type that matches what components expect
export interface User {
  id: string
  email: string
  firstName?: string | null
  lastName?: string | null
  name?: string | null
  imageUrl?: string | null
  role?: string
  businessName?: string
  // Clerk-specific
  primaryEmailAddress?: {
    emailAddress: string
  }
}

// Auth context value - maintains compatibility with old API
interface AuthContextValue {
  user: User | null
  session: { id: string } | null
  isLoading: boolean
  isAuthenticated: boolean
  error: Error | null
  signIn: (email: string, password: string) => Promise<{ data: any; error: Error | null }>
  signUp: (email: string, password: string, metadata?: Record<string, any>) => Promise<{ data: any; error: Error | null }>
  signInWithOAuth: (provider: 'google' | 'apple' | 'facebook') => Promise<{ data: any; error: Error | null }>
  signOut: () => Promise<{ error: Error | null }>
  resetPassword: (email: string) => Promise<{ error: Error | null }>
  updatePassword: (newPassword: string) => Promise<{ data: any; error: Error | null }>
  refreshSession: () => Promise<void>
}

/**
 * Hook to use auth context (Clerk-based)
 * Drop-in replacement for the old useAuthContext
 */
export function useAuthContext(): AuthContextValue {
  const { user: clerkUser, isLoaded: userLoaded, isSignedIn } = useUser()
  const { isLoaded: authLoaded, sessionId } = useAuth()
  const { signOut: clerkSignOut, openSignIn } = useClerk()
  const router = useRouter()

  // Transform Clerk user to our User type
  const user: User | null = useMemo(() => {
    if (!clerkUser) return null

    return {
      id: clerkUser.id,
      email: clerkUser.primaryEmailAddress?.emailAddress || '',
      firstName: clerkUser.firstName,
      lastName: clerkUser.lastName,
      name: clerkUser.fullName,
      imageUrl: clerkUser.imageUrl,
      role: (clerkUser.unsafeMetadata?.role as string) || 'student',
      businessName: clerkUser.unsafeMetadata?.businessName as string | undefined,
      primaryEmailAddress: clerkUser.primaryEmailAddress ? {
        emailAddress: clerkUser.primaryEmailAddress.emailAddress
      } : undefined
    }
  }, [clerkUser])

  const session = useMemo(() => {
    if (!sessionId) return null
    return { id: sessionId }
  }, [sessionId])

  const isLoading = !userLoaded || !authLoaded

  // Sign in - redirects to Clerk sign-in page
  // Note: For custom sign-in forms, use useSignIn hook directly
  const signIn = useCallback(async (_email: string, _password: string) => {
    // This is a compatibility stub - actual sign-in is handled by SignInForm
    // For programmatic sign-in, components should use useSignIn from @clerk/nextjs
    console.warn('signIn via useAuthContext is deprecated. Use SignInForm or useSignIn hook.')
    openSignIn()
    return { data: null, error: null }
  }, [openSignIn])

  // Sign up - redirects to Clerk sign-up page
  const signUp = useCallback(async (_email: string, _password: string, _metadata?: Record<string, any>) => {
    // This is a compatibility stub - actual sign-up is handled by SignUpForm
    console.warn('signUp via useAuthContext is deprecated. Use SignUpForm or useSignUp hook.')
    router.push('/auth/signup')
    return { data: null, error: null }
  }, [router])

  // OAuth sign in
  const signInWithOAuth = useCallback(async (provider: 'google' | 'apple' | 'facebook') => {
    console.warn('signInWithOAuth via useAuthContext is deprecated. Use Clerk OAuth directly.')
    // Clerk handles OAuth differently - would need to use signIn.authenticateWithRedirect
    return { data: null, error: new Error('Use Clerk OAuth directly') }
  }, [])

  // Sign out
  const signOut = useCallback(async () => {
    try {
      await clerkSignOut()
      router.push('/auth/signin')
      return { error: null }
    } catch (err) {
      return { error: err instanceof Error ? err : new Error('Sign out failed') }
    }
  }, [clerkSignOut, router])

  // Reset password - Clerk handles this via their UI
  const resetPassword = useCallback(async (_email: string) => {
    console.warn('resetPassword via useAuthContext is deprecated. Use Clerk forgot password flow.')
    router.push('/auth/forgot-password')
    return { error: null }
  }, [router])

  // Update password
  const updatePassword = useCallback(async (_newPassword: string) => {
    console.warn('updatePassword via useAuthContext is deprecated. Use Clerk user settings.')
    return { data: null, error: new Error('Use Clerk user settings to update password') }
  }, [])

  // Refresh session - Clerk handles this automatically
  const refreshSession = useCallback(async () => {
    // Clerk handles session refresh automatically
    // This is a no-op for compatibility
  }, [])

  return {
    user,
    session,
    isLoading,
    isAuthenticated: !!isSignedIn,
    error: null,
    signIn,
    signUp,
    signInWithOAuth,
    signOut,
    resetPassword,
    updatePassword,
    refreshSession
  }
}

// Legacy exports for compatibility
export { useAuthContext as useAuth }

// Re-export Clerk hooks for convenience
export { useUser, useAuth as useClerkAuth, useClerk } from '@clerk/nextjs'
