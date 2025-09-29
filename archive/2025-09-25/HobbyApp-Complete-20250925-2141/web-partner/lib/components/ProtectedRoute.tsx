/**
 * Protected Route Component
 * 
 * Features:
 * - Route protection with authentication check
 * - Role-based access control
 * - Loading states during auth verification
 * - Automatic redirection
 */

'use client'

import React, { useEffect, memo } from 'react'
import { useRouter, usePathname } from 'next/navigation'
import { useAuthContext } from '../context/AuthContext'
import { Loader2 } from 'lucide-react'

interface ProtectedRouteProps {
  children: React.ReactNode
  requiredRole?: 'student' | 'instructor' | 'admin'
  redirectTo?: string
  fallback?: React.ReactNode
}

/**
 * Protected Route Component
 * Wraps content that requires authentication
 */
export const ProtectedRoute = memo(function ProtectedRoute({
  children,
  requiredRole,
  redirectTo = '/auth/signin',
  fallback
}: ProtectedRouteProps) {
  const router = useRouter()
  const pathname = usePathname()
  const { user, isLoading, isAuthenticated } = useAuthContext()

  useEffect(() => {
    if (!isLoading && !isAuthenticated) {
      // Store the intended destination
      const returnUrl = encodeURIComponent(pathname)
      router.push(`${redirectTo}?returnUrl=${returnUrl}`)
    }
  }, [isLoading, isAuthenticated, router, pathname, redirectTo])

  // Check role if required
  useEffect(() => {
    if (!isLoading && isAuthenticated && requiredRole) {
      const userRole = user?.user_metadata?.role || user?.role
      
      // Admin has access to everything
      if (userRole === 'admin') return
      
      // Check if user has required role
      if (userRole !== requiredRole) {
        router.push('/unauthorized')
      }
    }
  }, [isLoading, isAuthenticated, user, requiredRole, router])

  // Show loading state
  if (isLoading) {
    return fallback || <DefaultLoadingFallback />
  }

  // Show nothing while redirecting
  if (!isAuthenticated) {
    return null
  }

  // Check role access
  if (requiredRole) {
    const userRole = user?.user_metadata?.role || user?.role
    if (userRole !== 'admin' && userRole !== requiredRole) {
      return null
    }
  }

  return <>{children}</>
})

/**
 * Default loading fallback component
 */
function DefaultLoadingFallback() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="text-center">
        <Loader2 className="h-8 w-8 animate-spin text-blue-600 mx-auto" />
        <p className="mt-4 text-gray-600">Loading...</p>
      </div>
    </div>
  )
}

/**
 * Role-based route protection component
 * More specific than ProtectedRoute for role checking
 */
interface RoleProtectedRouteProps {
  children: React.ReactNode
  roles: Array<'student' | 'instructor' | 'admin'>
  fallback?: React.ReactNode
}

export const RoleProtectedRoute = memo(function RoleProtectedRoute({
  children,
  roles,
  fallback
}: RoleProtectedRouteProps) {
  const { user, isLoading, isAuthenticated } = useAuthContext()
  const router = useRouter()

  const userRole = user?.user_metadata?.role || user?.role || 'student'
  const hasAccess = roles.includes(userRole as any) || userRole === 'admin'

  useEffect(() => {
    if (!isLoading && isAuthenticated && !hasAccess) {
      router.push('/unauthorized')
    }
  }, [isLoading, isAuthenticated, hasAccess, router])

  if (isLoading) {
    return fallback || <DefaultLoadingFallback />
  }

  if (!isAuthenticated || !hasAccess) {
    return null
  }

  return <>{children}</>
})

/**
 * Public route component
 * Redirects to dashboard if already authenticated
 */
interface PublicRouteProps {
  children: React.ReactNode
  redirectTo?: string
}

export const PublicRoute = memo(function PublicRoute({
  children,
  redirectTo = '/dashboard'
}: PublicRouteProps) {
  const router = useRouter()
  const { isAuthenticated, isLoading } = useAuthContext()

  useEffect(() => {
    if (!isLoading && isAuthenticated) {
      router.push(redirectTo)
    }
  }, [isLoading, isAuthenticated, router, redirectTo])

  if (isLoading) {
    return <DefaultLoadingFallback />
  }

  if (isAuthenticated) {
    return null
  }

  return <>{children}</>
})

/**
 * HOC for protecting pages
 * Wraps page components with authentication check
 */
export function withProtectedRoute<P extends object>(
  Component: React.ComponentType<P>,
  options?: {
    requiredRole?: 'student' | 'instructor' | 'admin'
    redirectTo?: string
    fallback?: React.ReactNode
  }
) {
  return function ProtectedComponent(props: P) {
    return (
      <ProtectedRoute {...options}>
        <Component {...props} />
      </ProtectedRoute>
    )
  }
}

/**
 * HOC for role-based protection
 */
export function withRoleProtection<P extends object>(
  Component: React.ComponentType<P>,
  roles: Array<'student' | 'instructor' | 'admin'>,
  fallback?: React.ReactNode
) {
  return function RoleProtectedComponent(props: P) {
    return (
      <RoleProtectedRoute roles={roles} fallback={fallback}>
        <Component {...props} />
      </RoleProtectedRoute>
    )
  }
}