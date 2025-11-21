/**
 * Role-based access control utilities (Better Auth)
 *
 * Migrated from Supabase Auth to Better Auth
 */

import type { User } from '@/lib/auth'

export type UserRole = 'admin' | 'instructor' | 'student' | 'studio'

/**
 * Check if user has admin role
 * Better Auth: role is directly on user object
 */
export function isAdmin(user: User | null): boolean {
  if (!user) return false

  // Better Auth: role is directly on user object, no metadata nesting
  const role = user.role || 'student'
  return role === 'admin'
}

/**
 * Check if user has instructor role or higher
 * Better Auth: role is directly on user object
 */
export function isInstructorOrHigher(user: User | null): boolean {
  if (!user) return false

  // Better Auth: role is directly on user object
  const role = user.role || 'student'
  return role === 'admin' || role === 'instructor' || role === 'studio'
}

/**
 * Check if user has specific role
 * Better Auth: role is directly on user object
 */
export function hasRole(user: User | null, requiredRole: UserRole): boolean {
  if (!user) return false

  // Better Auth: role is directly on user object
  const userRole = user.role || 'student'

  // Admin has access to everything
  if (userRole === 'admin') return true

  // Check specific role
  return userRole === requiredRole
}

/**
 * Get user's role
 * Better Auth: role is directly on user object
 */
export function getUserRole(user: User | null): UserRole | null {
  if (!user) return null

  // Better Auth: role is directly on user object
  const role = user.role || 'student'
  return role as UserRole
}

/**
 * Admin role display names
 */
export const ROLE_DISPLAY_NAMES: Record<UserRole, string> = {
  admin: 'Administrator',
  instructor: 'Instructor',
  studio: 'Studio Owner',
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