/**
 * My Bookings Component
 * Displays student's booking history and upcoming classes
 */

'use client'

import React, { useState, useEffect } from 'react'
import Link from 'next/link'
import { 
  CalendarDaysIcon,
  MapPinIcon,
  ClockIcon,
  UserIcon,
  StarIcon,
  ArrowPathIcon,
  XMarkIcon,
  ChatBubbleLeftRightIcon,
  ShareIcon,
  EllipsisHorizontalIcon
} from '@heroicons/react/24/outline'
import {
  CheckCircleIcon,
  ExclamationTriangleIcon,
  XCircleIcon
} from '@heroicons/react/24/solid'

interface Booking {
  id: string
  classData: {
    id: string
    title: string
    category: string
    instructor: {
      id: string
      name: string
      rating: number
      verified: boolean
    }
    images: string[]
  }
  sessionData: {
    date: string
    timeSlot: string
    location: string
    address?: string
  }
  status: 'upcoming' | 'completed' | 'cancelled' | 'no_show' | 'pending'
  paymentStatus: 'paid' | 'pending' | 'refunded'
  bookingDate: string
  amount: number
  canCancel: boolean
  canReschedule: boolean
  canReview: boolean
  hasReviewed?: boolean
}

// Mock data for development
const mockBookings: Booking[] = [
  {
    id: 'booking_1',
    classData: {
      id: 'class_1',
      title: 'Advanced Ceramics Workshop',
      category: 'Pottery',
      instructor: {
        id: 'instructor_1',
        name: 'Sarah Chen',
        rating: 4.8,
        verified: true
      },
      images: ['/images/pottery-advanced.jpg']
    },
    sessionData: {
      date: '2024-01-20T14:00:00Z',
      timeSlot: '2:00 PM - 4:00 PM',
      location: 'Downtown Studio',
      address: '123 Art District Blvd, Vancouver, BC'
    },
    status: 'upcoming',
    paymentStatus: 'paid',
    bookingDate: '2024-01-10T09:30:00Z',
    amount: 65,
    canCancel: true,
    canReschedule: true,
    canReview: false
  },
  {
    id: 'booking_2',
    classData: {
      id: 'class_2',
      title: 'Watercolor Painting: Landscapes',
      category: 'Painting',
      instructor: {
        id: 'instructor_2',
        name: 'Michael Torres',
        rating: 4.9,
        verified: true
      },
      images: ['/images/watercolor-landscape.jpg']
    },
    sessionData: {
      date: '2024-01-05T10:00:00Z',
      timeSlot: '10:00 AM - 12:30 PM',
      location: 'Art Center',
      address: '456 Creative Way, Vancouver, BC'
    },
    status: 'completed',
    paymentStatus: 'paid',
    bookingDate: '2023-12-28T15:20:00Z',
    amount: 45,
    canCancel: false,
    canReschedule: false,
    canReview: true,
    hasReviewed: false
  },
  {
    id: 'booking_3',
    classData: {
      id: 'class_3',
      title: 'Jewelry Making: Silver Wire Wrapping',
      category: 'Jewelry',
      instructor: {
        id: 'instructor_3',
        name: 'Emma Rodriguez',
        rating: 4.7,
        verified: true
      },
      images: ['/images/jewelry-wire.jpg']
    },
    sessionData: {
      date: '2023-12-15T13:00:00Z',
      timeSlot: '1:00 PM - 4:00 PM',
      location: 'Creative Space',
      address: '789 Maker Lane, Vancouver, BC'
    },
    status: 'completed',
    paymentStatus: 'paid',
    bookingDate: '2023-12-01T11:45:00Z',
    amount: 75,
    canCancel: false,
    canReschedule: false,
    canReview: true,
    hasReviewed: true
  }
]

type BookingFilter = 'all' | 'upcoming' | 'completed' | 'cancelled'

const statusConfig = {
  upcoming: {
    label: 'Upcoming',
    icon: CalendarDaysIcon,
    color: 'text-blue-700',
    bg: 'bg-blue-100',
    border: 'border-blue-200'
  },
  completed: {
    label: 'Completed',
    icon: CheckCircleIcon,
    color: 'text-green-700',
    bg: 'bg-green-100',
    border: 'border-green-200'
  },
  cancelled: {
    label: 'Cancelled',
    icon: XCircleIcon,
    color: 'text-red-700',
    bg: 'bg-red-100',
    border: 'border-red-200'
  },
  no_show: {
    label: 'No Show',
    icon: ExclamationTriangleIcon,
    color: 'text-orange-700',
    bg: 'bg-orange-100',
    border: 'border-orange-200'
  },
  pending: {
    label: 'Pending',
    icon: ClockIcon,
    color: 'text-gray-700',
    bg: 'bg-gray-100',
    border: 'border-gray-200'
  }
}

export default function MyBookings() {
  const [bookings] = useState<Booking[]>(mockBookings)
  const [filter, setFilter] = useState<BookingFilter>('all')
  const [isLoading, setIsLoading] = useState(false)
  const [selectedBooking, setSelectedBooking] = useState<string | null>(null)

  const filteredBookings = bookings.filter(booking => {
    if (filter === 'all') return true
    return booking.status === filter
  })

  const upcomingCount = bookings.filter(b => b.status === 'upcoming').length
  const completedCount = bookings.filter(b => b.status === 'completed').length
  const cancelledCount = bookings.filter(b => b.status === 'cancelled').length

  const formatDate = (dateString: string) => {
    const date = new Date(dateString)
    const now = new Date()
    const diffTime = date.getTime() - now.getTime()
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
    
    const formatted = date.toLocaleDateString('en-US', {
      weekday: 'short',
      month: 'short',
      day: 'numeric',
      year: date.getFullYear() !== now.getFullYear() ? 'numeric' : undefined
    })
    
    if (diffDays === 0) return `Today • ${formatted}`
    if (diffDays === 1) return `Tomorrow • ${formatted}`
    if (diffDays > 0 && diffDays <= 7) return `In ${diffDays} days • ${formatted}`
    
    return formatted
  }

  const handleCancelBooking = async (bookingId: string) => {
    if (!confirm('Are you sure you want to cancel this booking?')) return
    
    setIsLoading(true)
    try {
      // API call to cancel booking
      console.log('Cancelling booking:', bookingId)
      // Update booking status in state
    } catch (error) {
      console.error('Failed to cancel booking:', error)
    } finally {
      setIsLoading(false)
    }
  }

  const handleRescheduleBooking = async (bookingId: string) => {
    // Navigate to reschedule page
    console.log('Reschedule booking:', bookingId)
  }

  const handleMessageInstructor = (instructorId: string, bookingId: string) => {
    // Navigate to messages or open chat
    console.log('Message instructor:', instructorId, 'for booking:', bookingId)
  }

  const handleRebookClass = (classId: string) => {
    // Navigate to booking page for the same class
    window.location.href = `/student/booking/${classId}`
  }

  const BookingCard = ({ booking }: { booking: Booking }) => {
    const status = statusConfig[booking.status]
    const StatusIcon = status.icon
    
    return (
      <div className="bg-white border border-gray-200 rounded-lg p-6 hover:shadow-md transition-shadow">
        <div className="flex items-start justify-between mb-4">
          <div className="flex-1">
            <h3 className="text-lg font-semibold text-gray-900 mb-2">
              {booking.classData.title}
            </h3>
            <div className="flex items-center text-sm text-gray-600 mb-2">
              <UserIcon className="w-4 h-4 mr-1" />
              {booking.classData.instructor.name}
              {booking.classData.instructor.verified && (
                <span className="ml-1 text-indigo-600">✓</span>
              )}
              <span className="mx-2">•</span>
              <span>{booking.classData.category}</span>
            </div>
            <div className="flex items-center text-sm text-gray-600 mb-2">
              <CalendarDaysIcon className="w-4 h-4 mr-1" />
              {formatDate(booking.sessionData.date)}
              <span className="mx-2">•</span>
              {booking.sessionData.timeSlot}
            </div>
            <div className="flex items-center text-sm text-gray-600">
              <MapPinIcon className="w-4 h-4 mr-1" />
              {booking.sessionData.location}
            </div>
          </div>
          
          <div className="flex flex-col items-end space-y-2">
            <div className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${status.bg} ${status.color}`}>
              <StatusIcon className="w-4 h-4 mr-1" />
              {status.label}
            </div>
            <div className="text-right">
              <p className="text-lg font-semibold text-gray-900">${booking.amount}</p>
              <p className="text-xs text-gray-500 capitalize">{booking.paymentStatus}</p>
            </div>
          </div>
        </div>

        {/* Actions */}
        <div className="flex items-center justify-between pt-4 border-t border-gray-200">
          <div className="flex items-center space-x-3">
            {booking.status === 'upcoming' && (
              <>
                {booking.canCancel && (
                  <button
                    onClick={() => handleCancelBooking(booking.id)}
                    disabled={isLoading}
                    className="text-sm font-medium text-red-600 hover:text-red-700 disabled:opacity-50"
                  >
                    Cancel
                  </button>
                )}
                {booking.canReschedule && (
                  <button
                    onClick={() => handleRescheduleBooking(booking.id)}
                    className="text-sm font-medium text-indigo-600 hover:text-indigo-700"
                  >
                    Reschedule
                  </button>
                )}
                <button
                  onClick={() => handleMessageInstructor(booking.classData.instructor.id, booking.id)}
                  className="text-sm font-medium text-gray-600 hover:text-gray-700"
                >
                  Message Instructor
                </button>
              </>
            )}
            
            {booking.status === 'completed' && (
              <>
                {booking.canReview && !booking.hasReviewed && (
                  <Link
                    href={`/student/reviews/write/${booking.id}`}
                    className="text-sm font-medium text-indigo-600 hover:text-indigo-700"
                  >
                    Write Review
                  </Link>
                )}
                {booking.hasReviewed && (
                  <Link
                    href={`/student/reviews/edit/${booking.id}`}
                    className="text-sm font-medium text-gray-600 hover:text-gray-700"
                  >
                    Edit Review
                  </Link>
                )}
                <button
                  onClick={() => handleRebookClass(booking.classData.id)}
                  className="text-sm font-medium text-indigo-600 hover:text-indigo-700"
                >
                  Book Again
                </button>
              </>
            )}
          </div>

          <div className="flex items-center space-x-2">
            <button
              className="p-1 text-gray-400 hover:text-gray-600"
              title="Share booking"
            >
              <ShareIcon className="w-4 h-4" />
            </button>
            <div className="relative">
              <button
                onClick={() => setSelectedBooking(
                  selectedBooking === booking.id ? null : booking.id
                )}
                className="p-1 text-gray-400 hover:text-gray-600"
                title="More options"
              >
                <EllipsisHorizontalIcon className="w-4 h-4" />
              </button>
              
              {selectedBooking === booking.id && (
                <div className="absolute right-0 top-8 z-10 w-48 bg-white border border-gray-200 rounded-lg shadow-lg py-1">
                  <Link
                    href={`/student/booking/${booking.classData.id}`}
                    className="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                  >
                    View Class Details
                  </Link>
                  <button
                    onClick={() => console.log('Download receipt')}
                    className="w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                  >
                    Download Receipt
                  </button>
                  <button
                    onClick={() => console.log('Report issue')}
                    className="w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                  >
                    Report an Issue
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">My Bookings</h1>
        <button
          onClick={() => window.location.reload()}
          disabled={isLoading}
          className="inline-flex items-center px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50"
        >
          <ArrowPathIcon className={`w-4 h-4 mr-2 ${isLoading ? 'animate-spin' : ''}`} />
          Refresh
        </button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-white border border-gray-200 rounded-lg p-4">
          <div className="text-2xl font-bold text-gray-900">{bookings.length}</div>
          <div className="text-sm text-gray-500">Total Bookings</div>
        </div>
        <div className="bg-white border border-gray-200 rounded-lg p-4">
          <div className="text-2xl font-bold text-blue-600">{upcomingCount}</div>
          <div className="text-sm text-gray-500">Upcoming</div>
        </div>
        <div className="bg-white border border-gray-200 rounded-lg p-4">
          <div className="text-2xl font-bold text-green-600">{completedCount}</div>
          <div className="text-sm text-gray-500">Completed</div>
        </div>
        <div className="bg-white border border-gray-200 rounded-lg p-4">
          <div className="text-2xl font-bold text-red-600">{cancelledCount}</div>
          <div className="text-sm text-gray-500">Cancelled</div>
        </div>
      </div>

      {/* Filters */}
      <div className="flex items-center space-x-1 bg-white border border-gray-200 rounded-lg p-1">
        {([
          { key: 'all', label: 'All Bookings' },
          { key: 'upcoming', label: 'Upcoming' },
          { key: 'completed', label: 'Completed' },
          { key: 'cancelled', label: 'Cancelled' }
        ] as const).map(({ key, label }) => (
          <button
            key={key}
            onClick={() => setFilter(key)}
            className={`px-4 py-2 text-sm font-medium rounded-md transition-colors ${
              filter === key
                ? 'bg-indigo-100 text-indigo-700'
                : 'text-gray-600 hover:text-gray-900 hover:bg-gray-100'
            }`}
          >
            {label}
          </button>
        ))}
      </div>

      {/* Bookings List */}
      {filteredBookings.length === 0 ? (
        <div className="text-center py-12 bg-white border border-gray-200 rounded-lg">
          <CalendarDaysIcon className="w-12 h-12 text-gray-400 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">
            {filter === 'all' ? 'No bookings yet' : `No ${filter} bookings`}
          </h3>
          <p className="text-gray-600 mb-4">
            {filter === 'all' 
              ? 'Start exploring classes to make your first booking!' 
              : `You don't have any ${filter} bookings.`
            }
          </p>
          <Link
            href="/student/discovery"
            className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
          >
            Explore Classes
          </Link>
        </div>
      ) : (
        <div className="space-y-4">
          {filteredBookings.map((booking) => (
            <BookingCard key={booking.id} booking={booking} />
          ))}
        </div>
      )}

      {/* Click outside handler for dropdowns */}
      {selectedBooking && (
        <div
          className="fixed inset-0 z-5"
          onClick={() => setSelectedBooking(null)}
        />
      )}
    </div>
  )
}