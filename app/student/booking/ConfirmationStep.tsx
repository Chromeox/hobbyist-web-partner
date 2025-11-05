/**
 * Booking Confirmation Step Component
 * Shows booking confirmation and provides options for post-booking actions
 */

'use client'

import React, { useState, useEffect } from 'react'
import Link from 'next/link'
import { 
  CheckCircleIcon,
  CalendarDaysIcon,
  MapPinIcon,
  ClockIcon,
  UserIcon,
  ShareIcon,
  DevicePhoneMobileIcon,
  EnvelopeIcon,
  PlusIcon,
  HeartIcon
} from '@heroicons/react/24/outline'
import { HeartIcon as HeartIconSolid } from '@heroicons/react/24/solid'

interface ConfirmationStepProps {
  bookingData: {
    id: string
    classData: {
      id: string
      title: string
      description: string
      price: number
      duration: number
      instructor: {
        id: string
        name: string
        rating: number
        verified: boolean
        bio?: string
        avatar?: string
      }
      category: string
      nextSession?: {
        date: string
        timeSlot: string
        location: string
        address?: string
      }
      images: string[]
    }
    paymentData: {
      paymentMethod: string
      amount: number
      transactionId: string
      cardLast4?: string
    }
    bookingDate: string
    status: string
  }
  onComplete: () => void
}

interface ReminderSettings {
  email: boolean
  sms: boolean
  push: boolean
  calendar: boolean
}

export default function ConfirmationStep({ bookingData, onComplete }: ConfirmationStepProps) {
  const [isFollowingInstructor, setIsFollowingInstructor] = useState(false)
  const [reminderSettings, setReminderSettings] = useState<ReminderSettings>({
    email: true,
    sms: false,
    push: true,
    calendar: true
  })
  const [showReminderSettings, setShowReminderSettings] = useState(false)
  const [isAddingToCalendar, setIsAddingToCalendar] = useState(false)
  const [isSharing, setIsSharing] = useState(false)

  const { classData, paymentData } = bookingData

  useEffect(() => {
    // Auto-scroll to top on mount
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }, [])

  const formatDate = (dateString: string) => {
    const date = new Date(dateString)
    return {
      weekday: date.toLocaleDateString('en-US', { weekday: 'long' }),
      date: date.toLocaleDateString('en-US', { 
        month: 'long', 
        day: 'numeric', 
        year: 'numeric' 
      }),
      time: date.toLocaleTimeString('en-US', { 
        hour: 'numeric', 
        minute: '2-digit',
        hour12: true 
      })
    }
  }

  const formatDuration = (minutes: number) => {
    const hours = Math.floor(minutes / 60)
    const mins = minutes % 60
    if (hours === 0) return `${mins} minutes`
    if (mins === 0) return `${hours} hour${hours > 1 ? 's' : ''}`
    return `${hours} hour${hours > 1 ? 's' : ''} ${mins} minutes`
  }

  const getPaymentMethodDisplay = () => {
    switch (paymentData.paymentMethod) {
      case 'card':
        return `Card ending in ${paymentData.cardLast4}`
      case 'apple_pay':
        return 'Apple Pay'
      case 'google_pay':
        return 'Google Pay'
      case 'credits':
        return 'Credits'
      default:
        return 'Payment method'
    }
  }

  const handleFollowInstructor = async () => {
    try {
      setIsFollowingInstructor(!isFollowingInstructor)
      // API call would go here
    } catch (error) {
      console.error('Failed to follow instructor:', error)
    }
  }

  const handleUpdateReminders = async () => {
    try {
      // API call to update reminder preferences
      console.log('Updating reminders:', reminderSettings)
      setShowReminderSettings(false)
    } catch (error) {
      console.error('Failed to update reminders:', error)
    }
  }

  const handleAddToCalendar = async () => {
    if (!classData.nextSession) return

    setIsAddingToCalendar(true)
    
    try {
      const startDate = new Date(classData.nextSession.date)
      const endDate = new Date(startDate.getTime() + classData.duration * 60 * 1000)
      
      const event = {
        title: classData.title,
        description: `${classData.description}\n\nInstructor: ${classData.instructor.name}\nBooking ID: ${bookingData.id}`,
        location: classData.nextSession.address || classData.nextSession.location,
        startDate: startDate.toISOString().replace(/[-:]/g, '').split('.')[0] + 'Z',
        endDate: endDate.toISOString().replace(/[-:]/g, '').split('.')[0] + 'Z'
      }

      // Create calendar link
      const googleCalendarUrl = `https://calendar.google.com/calendar/render?action=TEMPLATE&text=${encodeURIComponent(event.title)}&dates=${event.startDate}/${event.endDate}&details=${encodeURIComponent(event.description)}&location=${encodeURIComponent(event.location)}`
      
      window.open(googleCalendarUrl, '_blank')
    } catch (error) {
      console.error('Failed to add to calendar:', error)
    } finally {
      setIsAddingToCalendar(false)
    }
  }

  const handleShare = async () => {
    setIsSharing(true)
    
    try {
      const shareData = {
        title: `I just booked: ${classData.title}`,
        text: `I'm taking "${classData.title}" with ${classData.instructor.name}. Check out this amazing class!`,
        url: `${window.location.origin}/student/booking/${classData.id}`
      }

      if (navigator.share) {
        await navigator.share(shareData)
      } else {
        // Fallback: copy to clipboard
        await navigator.clipboard.writeText(shareData.url)
        // Show toast notification (you could add this)
        alert('Link copied to clipboard!')
      }
    } catch (error) {
      console.error('Failed to share:', error)
    } finally {
      setIsSharing(false)
    }
  }

  const sessionDetails = classData.nextSession ? formatDate(classData.nextSession.date) : null

  return (
    <div className="max-w-2xl mx-auto space-y-8">
      {/* Success Header */}
      <div className="text-center py-8 bg-green-50 rounded-lg border border-green-200">
        <CheckCircleIcon className="w-16 h-16 text-green-500 mx-auto mb-4" />
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Booking Confirmed!</h1>
        <p className="text-lg text-gray-600">
          You're all set for your upcoming class
        </p>
        <div className="mt-4 inline-flex items-center px-4 py-2 bg-green-100 rounded-full">
          <span className="text-sm font-medium text-green-800">
            Booking ID: {bookingData.id.toUpperCase()}
          </span>
        </div>
      </div>

      {/* Class Details Card */}
      <div className="bg-white border border-gray-200 rounded-lg overflow-hidden shadow-sm">
        <div className="p-6">
          <h2 className="text-2xl font-bold text-gray-900 mb-4">{classData.title}</h2>
          
          <div className="space-y-4">
            {/* Instructor */}
            <div className="flex items-center justify-between">
              <div className="flex items-center">
                <div className="w-12 h-12 bg-indigo-500 rounded-full flex items-center justify-center mr-4">
                  <span className="text-white font-semibold">
                    {classData.instructor.name.charAt(0)}
                  </span>
                </div>
                <div>
                  <p className="font-semibold text-gray-900">
                    {classData.instructor.name}
                    {classData.instructor.verified && (
                      <span className="ml-1 text-indigo-600">✓</span>
                    )}
                  </p>
                  <p className="text-sm text-gray-600">
                    {classData.instructor.rating}★ rating • Instructor
                  </p>
                </div>
              </div>
              
              <button
                onClick={handleFollowInstructor}
                className={`flex items-center px-4 py-2 rounded-lg transition-colors ${
                  isFollowingInstructor
                    ? 'bg-pink-100 text-pink-700 hover:bg-pink-200'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
              >
                {isFollowingInstructor ? (
                  <HeartIconSolid className="w-4 h-4 mr-2" />
                ) : (
                  <HeartIcon className="w-4 h-4 mr-2" />
                )}
                <span className="text-sm font-medium">
                  {isFollowingInstructor ? 'Following' : 'Follow'}
                </span>
              </button>
            </div>

            {/* Session Details */}
            {sessionDetails && classData.nextSession && (
              <div className="bg-gray-50 rounded-lg p-4 space-y-3">
                <div className="flex items-center">
                  <CalendarDaysIcon className="w-5 h-5 text-gray-400 mr-3" />
                  <div>
                    <p className="font-medium text-gray-900">{sessionDetails.weekday}</p>
                    <p className="text-sm text-gray-600">{sessionDetails.date}</p>
                  </div>
                </div>
                
                <div className="flex items-center">
                  <ClockIcon className="w-5 h-5 text-gray-400 mr-3" />
                  <div>
                    <p className="font-medium text-gray-900">{classData.nextSession.timeSlot}</p>
                    <p className="text-sm text-gray-600">{formatDuration(classData.duration)}</p>
                  </div>
                </div>
                
                <div className="flex items-center">
                  <MapPinIcon className="w-5 h-5 text-gray-400 mr-3" />
                  <div>
                    <p className="font-medium text-gray-900">{classData.nextSession.location}</p>
                    {classData.nextSession.address && (
                      <p className="text-sm text-gray-600">{classData.nextSession.address}</p>
                    )}
                  </div>
                </div>
              </div>
            )}

            {/* Payment Summary */}
            <div className="border-t border-gray-200 pt-4">
              <h3 className="font-semibold text-gray-900 mb-2">Payment Summary</h3>
              <div className="space-y-1">
                <div className="flex justify-between text-sm">
                  <span className="text-gray-600">Class fee</span>
                  <span className="text-gray-900">${paymentData.amount}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-600">Payment method</span>
                  <span className="text-gray-900">{getPaymentMethodDisplay()}</span>
                </div>
                <div className="flex justify-between text-sm font-semibold pt-2 border-t border-gray-200">
                  <span className="text-gray-900">Total paid</span>
                  <span className="text-gray-900">${paymentData.amount}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Quick Actions */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <button
          onClick={handleAddToCalendar}
          disabled={isAddingToCalendar || !classData.nextSession}
          className="flex items-center justify-center px-4 py-3 bg-white border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {isAddingToCalendar ? (
            <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-indigo-600 mr-2"></div>
          ) : (
            <PlusIcon className="w-5 h-5 mr-2 text-gray-600" />
          )}
          <span className="text-sm font-medium text-gray-700">Add to Calendar</span>
        </button>
        
        <button
          onClick={() => setShowReminderSettings(!showReminderSettings)}
          className="flex items-center justify-center px-4 py-3 bg-white border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors"
        >
          <EnvelopeIcon className="w-5 h-5 mr-2 text-gray-600" />
          <span className="text-sm font-medium text-gray-700">Reminders</span>
        </button>
        
        <button
          onClick={handleShare}
          disabled={isSharing}
          className="flex items-center justify-center px-4 py-3 bg-white border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {isSharing ? (
            <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-indigo-600 mr-2"></div>
          ) : (
            <ShareIcon className="w-5 h-5 mr-2 text-gray-600" />
          )}
          <span className="text-sm font-medium text-gray-700">Share</span>
        </button>
      </div>

      {/* Reminder Settings */}
      {showReminderSettings && (
        <div className="bg-white border border-gray-200 rounded-lg p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Reminder Preferences</h3>
          <div className="space-y-4">
            <label className="flex items-center">
              <input
                type="checkbox"
                checked={reminderSettings.email}
                onChange={(e) => setReminderSettings(prev => ({ ...prev, email: e.target.checked }))}
                className="rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
              />
              <EnvelopeIcon className="w-5 h-5 ml-3 mr-2 text-gray-400" />
              <span className="text-sm text-gray-700">Email reminder (24 hours before)</span>
            </label>
            
            <label className="flex items-center">
              <input
                type="checkbox"
                checked={reminderSettings.sms}
                onChange={(e) => setReminderSettings(prev => ({ ...prev, sms: e.target.checked }))}
                className="rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
              />
              <DevicePhoneMobileIcon className="w-5 h-5 ml-3 mr-2 text-gray-400" />
              <span className="text-sm text-gray-700">SMS reminder (2 hours before)</span>
            </label>
            
            <label className="flex items-center">
              <input
                type="checkbox"
                checked={reminderSettings.push}
                onChange={(e) => setReminderSettings(prev => ({ ...prev, push: e.target.checked }))}
                className="rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
              />
              <DevicePhoneMobileIcon className="w-5 h-5 ml-3 mr-2 text-gray-400" />
              <span className="text-sm text-gray-700">Push notification (30 minutes before)</span>
            </label>
          </div>
          
          <div className="flex space-x-3 mt-6 pt-4 border-t border-gray-200">
            <button
              onClick={() => setShowReminderSettings(false)}
              className="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 rounded-md hover:bg-gray-200 transition-colors"
            >
              Cancel
            </button>
            <button
              onClick={handleUpdateReminders}
              className="px-4 py-2 text-sm font-medium text-white bg-indigo-600 rounded-md hover:bg-indigo-700 transition-colors"
            >
              Save Preferences
            </button>
          </div>
        </div>
      )}

      {/* Next Steps */}
      <div className="bg-blue-50 border border-blue-200 rounded-lg p-6">
        <h3 className="text-lg font-semibold text-blue-900 mb-3">What's Next?</h3>
        <ul className="space-y-2 text-sm text-blue-800">
          <li className="flex items-start">
            <span className="flex-shrink-0 w-1.5 h-1.5 bg-blue-600 rounded-full mt-2 mr-3"></span>
            You'll receive a confirmation email with all the class details
          </li>
          <li className="flex items-start">
            <span className="flex-shrink-0 w-1.5 h-1.5 bg-blue-600 rounded-full mt-2 mr-3"></span>
            Get reminder notifications based on your preferences
          </li>
          <li className="flex items-start">
            <span className="flex-shrink-0 w-1.5 h-1.5 bg-blue-600 rounded-full mt-2 mr-3"></span>
            Arrive 10-15 minutes early to settle in and meet your instructor
          </li>
          <li className="flex items-start">
            <span className="flex-shrink-0 w-1.5 h-1.5 bg-blue-600 rounded-full mt-2 mr-3"></span>
            Don't forget to leave a review after your class!
          </li>
        </ul>
      </div>

      {/* Action Buttons */}
      <div className="flex flex-col sm:flex-row gap-4">
        <Link
          href="/student/dashboard/bookings"
          className="flex-1 px-6 py-3 bg-white border border-gray-300 rounded-lg text-center text-gray-700 hover:bg-gray-50 transition-colors font-medium"
        >
          View My Bookings
        </Link>
        
        <Link
          href="/student/discovery"
          className="flex-1 px-6 py-3 bg-indigo-600 text-white rounded-lg text-center hover:bg-indigo-700 transition-colors font-medium"
        >
          Book Another Class
        </Link>
      </div>

      {/* Help & Support */}
      <div className="text-center pt-6 border-t border-gray-200">
        <p className="text-sm text-gray-600 mb-2">
          Need help or have questions about your booking?
        </p>
        <div className="flex justify-center space-x-4 text-sm">
          <Link 
            href="/help" 
            className="text-indigo-600 hover:text-indigo-700 font-medium"
          >
            Help Center
          </Link>
          <span className="text-gray-300">•</span>
          <Link 
            href="/contact" 
            className="text-indigo-600 hover:text-indigo-700 font-medium"
          >
            Contact Support
          </Link>
        </div>
      </div>
    </div>
  )
}