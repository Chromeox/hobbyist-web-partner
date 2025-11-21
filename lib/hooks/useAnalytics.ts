/**
 * Analytics Tracking Hook
 * Provides easy-to-use methods for tracking key user actions in PostHog
 */

'use client'

import { usePostHog } from 'posthog-js/react'
import { useCallback } from 'react'

export function useAnalytics() {
  const posthog = usePostHog()

  // Authentication Events
  const trackSignIn = useCallback((method: 'email' | 'google' | 'apple') => {
    posthog?.capture('user_signed_in', { method })
  }, [posthog])

  const trackSignUp = useCallback((method: 'email' | 'google' | 'apple') => {
    posthog?.capture('user_signed_up', { method })
  }, [posthog])

  const trackSignOut = useCallback(() => {
    posthog?.capture('user_signed_out')
  }, [posthog])

  // Class Management Events
  const trackClassCreated = useCallback((data: {
    classId: string
    category: string
    level: string
    price: number
  }) => {
    posthog?.capture('class_created', data)
  }, [posthog])

  const trackClassUpdated = useCallback((classId: string) => {
    posthog?.capture('class_updated', { classId })
  }, [posthog])

  const trackClassDeleted = useCallback((classId: string) => {
    posthog?.capture('class_deleted', { classId })
  }, [posthog])

  // Instructor Events
  const trackInstructorApproved = useCallback((instructorId: string) => {
    posthog?.capture('instructor_approved', { instructorId })
  }, [posthog])

  const trackInstructorRejected = useCallback((instructorId: string) => {
    posthog?.capture('instructor_rejected', { instructorId })
  }, [posthog])

  const trackInstructorInvited = useCallback((email: string) => {
    posthog?.capture('instructor_invited', { email })
  }, [posthog])

  // Payment & Pricing Events
  const trackStripeConnected = useCallback(() => {
    posthog?.capture('stripe_connected')
  }, [posthog])

  const trackPricingModelChanged = useCallback((model: 'credits' | 'cash') => {
    posthog?.capture('pricing_model_changed', { model })
  }, [posthog])

  const trackPayoutRequested = useCallback((amount: number) => {
    posthog?.capture('payout_requested', { amount })
  }, [posthog])

  // Dashboard Feature Usage
  const trackDashboardCardViewed = useCallback((cardName: string) => {
    posthog?.capture('dashboard_card_viewed', { cardName })
  }, [posthog])

  const trackNavigationClick = useCallback((section: string) => {
    posthog?.capture('navigation_clicked', { section })
  }, [posthog])

  // Booking Events
  const trackBookingCreated = useCallback((data: {
    classId: string
    studentId: string
    paymentMethod: string
  }) => {
    posthog?.capture('booking_created', data)
  }, [posthog])

  const trackBookingCancelled = useCallback((bookingId: string) => {
    posthog?.capture('booking_cancelled', { bookingId })
  }, [posthog])

  // Student Management
  const trackStudentAdded = useCallback((studentId: string) => {
    posthog?.capture('student_added', { studentId })
  }, [posthog])

  // Onboarding Events
  const trackOnboardingStarted = useCallback(() => {
    posthog?.capture('onboarding_started')
  }, [posthog])

  const trackOnboardingCompleted = useCallback(() => {
    posthog?.capture('onboarding_completed')
  }, [posthog])

  const trackOnboardingStepCompleted = useCallback((step: number) => {
    posthog?.capture('onboarding_step_completed', { step })
  }, [posthog])

  // Review Events
  const trackReviewResponded = useCallback((reviewId: string) => {
    posthog?.capture('review_responded', { reviewId })
  }, [posthog])

  // Generic Event Tracking
  const trackEvent = useCallback((eventName: string, properties?: Record<string, any>) => {
    posthog?.capture(eventName, properties)
  }, [posthog])

  // Identify user (call after authentication)
  const identifyUser = useCallback((userId: string, properties?: Record<string, any>) => {
    posthog?.identify(userId, properties)
  }, [posthog])

  // Reset user (call on sign out)
  const resetUser = useCallback(() => {
    posthog?.reset()
  }, [posthog])

  return {
    // Auth
    trackSignIn,
    trackSignUp,
    trackSignOut,

    // Classes
    trackClassCreated,
    trackClassUpdated,
    trackClassDeleted,

    // Instructors
    trackInstructorApproved,
    trackInstructorRejected,
    trackInstructorInvited,

    // Payments
    trackStripeConnected,
    trackPricingModelChanged,
    trackPayoutRequested,

    // Dashboard
    trackDashboardCardViewed,
    trackNavigationClick,

    // Bookings
    trackBookingCreated,
    trackBookingCancelled,

    // Students
    trackStudentAdded,

    // Onboarding
    trackOnboardingStarted,
    trackOnboardingCompleted,
    trackOnboardingStepCompleted,

    // Reviews
    trackReviewResponded,

    // Generic
    trackEvent,
    identifyUser,
    resetUser,
  }
}
