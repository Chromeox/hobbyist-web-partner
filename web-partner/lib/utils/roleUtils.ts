/**
 * Role-based access control utilities
 */

import { User } from '@supabase/supabase-js'

export type UserRole = 'admin' | 'instructor' | 'student'

/**
 * Check if user has admin role
 */
export function isAdmin(user: User | null): boolean {
  if (!user) return false
  
  // Check for admin role in user metadata
  const role = user.user_metadata?.role || user.app_metadata?.role
  return role === 'admin' || user.id === 'admin-user-id'
}

/**
 * Check if user has instructor role or higher
 */
export function isInstructorOrHigher(user: User | null): boolean {
  if (!user) return false
  
  const role = user.user_metadata?.role || user.app_metadata?.role
  return role === 'admin' || role === 'instructor' || user.id === 'admin-user-id' || user.id === 'demo-user-id'
}

/**
 * Check if user has specific role
 */
export function hasRole(user: User | null, requiredRole: UserRole): boolean {
  if (!user) return false
  
  const userRole = user.user_metadata?.role || user.app_metadata?.role
  
  // Admin has access to everything
  if (userRole === 'admin' || user.id === 'admin-user-id') return true
  
  // Check specific role
  return userRole === requiredRole
}

/**
 * Get user's role
 */
export function getUserRole(user: User | null): UserRole | null {
  if (!user) return null
  
  // Check for admin user ID first
  if (user.id === 'admin-user-id') return 'admin'
  if (user.id === 'demo-user-id') return 'instructor'
  
  const role = user.user_metadata?.role || user.app_metadata?.role
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