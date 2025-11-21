/**
 * Better Auth Client Configuration
 *
 * This is the client-side auth instance used in React components.
 * Provides hooks and methods for authentication in the frontend.
 *
 * Usage:
 * ```tsx
 * import { useSession, signIn, signOut } from "@/lib/auth-client"
 *
 * function MyComponent() {
 *   const { data: session, isPending } = useSession()
 *
 *   if (session) {
 *     return <div>Welcome, {session.user.name}!</div>
 *   }
 *
 *   return <button onClick={() => signIn.email({ email, password })}>Sign In</button>
 * }
 * ```
 */

"use client"

import { createAuthClient } from "better-auth/react"
import type { Session, User } from "./auth"

export const authClient = createAuthClient({
  baseURL: process.env.NEXT_PUBLIC_APP_URL || "http://localhost:3000",
})

// Export all hooks and methods
export const {
  useSession,
  signIn,
  signOut,
  signUp,
} = authClient

// Re-export types
export type { Session, User }

/**
 * Custom hook to get user from session
 * Returns null if no session exists
 */
export function useUser() {
  const { data: session, isPending, error } = useSession()

  return {
    user: session?.user ?? null,
    isPending,
    error,
  }
}

/**
 * Custom hook to check if user has a specific role
 * Supports: "student", "instructor", "admin", "studio"
 */
export function useHasRole(role: string | string[]) {
  const { user } = useUser()

  if (!user) return false

  const roles = Array.isArray(role) ? role : [role]
  const userWithRole = user as User
  return roles.includes(userWithRole.role || "student")
}

/**
 * Custom hook to require authentication
 * Redirects to sign-in if not authenticated
 */
export function useRequireAuth() {
  const { data: session, isPending } = useSession()

  return {
    session,
    isPending,
    isAuthenticated: !!session,
  }
}

// Export sign-in methods for convenience
export const signInWithEmail = signIn.email
export const signInWithGoogle = () => signIn.social({ provider: "google" })
export const signInWithApple = () => signIn.social({ provider: "apple" })

// Export sign-up method
export const signUpWithEmail = signUp.email
