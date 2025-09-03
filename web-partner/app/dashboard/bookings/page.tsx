/**
 * Bookings Page - Redirects to Reservations
 * Maintains backward compatibility for old bookmarks/links
 */

import { redirect } from 'next/navigation'

export default function BookingsPage() {
  // Redirect from old bookings URL to new reservations URL
  redirect('/dashboard/reservations')
}