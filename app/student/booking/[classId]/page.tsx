/**
 * Individual Class Booking Page
 * Handles booking flow for a specific class
 */

'use client'

import React from 'react'
import { useRouter } from 'next/navigation'
import BookingFlow from '../BookingFlow'

interface BookingPageProps {
  params: Promise<{
    classId: string
  }>
}

export default async function BookingPage({ params }: BookingPageProps) {
  const { classId } = await params
  const router = useRouter()

  const handleBookingComplete = () => {
    // Redirect to student dashboard after successful booking
    router.push('/student/dashboard/bookings')
  }

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <BookingFlow 
          classId={classId}
          onComplete={handleBookingComplete}
        />
      </div>
    </div>
  )
}