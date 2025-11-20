/**
 * Role-based access control utilities
 */

import { User } from '@supabase/supabase-js'

export type UserRole = 'admin' | 'instructor' | 'student'

/**
 * Check if user has admin role
 * Prioritizes app_metadata (server-only) over user_metadata for security
 */
export function isAdmin(user: User | null): boolean {
  if (!user) return false

  // Prioritize app_metadata (server-only, secure) over user_metadata (user-editable)
  const role = user.app_metadata?.role || user.user_metadata?.role
  return role === 'admin'
}

/**
 * Check if user has instructor role or higher
 * Prioritizes app_metadata (server-only) over user_metadata for security
 */
export function isInstructorOrHigher(user: User | null): boolean {
  if (!user) return false

  // Prioritize app_metadata (server-only, secure) over user_metadata (user-editable)
  const role = user.app_metadata?.role || user.user_metadata?.role
  return role === 'admin' || role === 'instructor'
}

/**
 * Check if user has specific role
 * Prioritizes app_metadata (server-only) over user_metadata for security
 */
export function hasRole(user: User | null, requiredRole: UserRole): boolean {
  if (!user) return false

  // Prioritize app_metadata (server-only, secure) over user_metadata (user-editable)
  const userRole = user.app_metadata?.role || user.user_metadata?.role

  // Admin has access to everything
  if (userRole === 'admin') return true

  // Check specific role
  return userRole === requiredRole
}

/**
 * Get user's role
 * Prioritizes app_metadata (server-only) over user_metadata for security
 */
export function getUserRole(user: User | null): UserRole | null {
  if (!user) return null

  // Prioritize app_metadata (server-only, secure) over user_metadata (user-editable)
  const role = user.app_metadata?.role || user.user_metadata?.role
  return role as UserRole || 'student'
}

/**
 * Admin role display names
 */
export const ROLE_DISPLAY_NAMES: Record<UserRole, string> = {
  admin: 'Administrator',
  instructor: 'Studio Owner',
  student: 'Student'
}

/**
 * Check if navigation item should be visible to user
 */
export function isNavItemVisible(user: User | null, itemId: string): boolean {
  const adminOnlyItems = [
    'payouts',
    'instructor-approvals', 
    'studio-approval'
  ]
  
  if (adminOnlyItems.includes(itemId)) {
    return isAdmin(user)
  }
  
  return true
}