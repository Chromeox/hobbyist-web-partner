/**
 * Booking Flow Component
 * Multi-step booking process for class reservations
 */

'use client'

import React, { useState, useEffect } from 'react'
import { useAuthContext } from '@/lib/context/AuthContext'
import PaymentStep from './PaymentStep'
import ConfirmationStep from './ConfirmationStep'
import { 
  UserIcon,
  CreditCardIcon,
  CheckCircleIcon,
  ChevronRightIcon,
  ExclamationTriangleIcon,
  StarIcon,
  MapPinIcon,
  ClockIcon,
  UserGroupIcon,
  CalendarDaysIcon
} from '@heroicons/react/24/outline'

interface BookingFlowProps {
  classId: string
  onComplete?: () => void
}

interface ClassData {
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
  difficulty: string
  maxParticipants: number
  currentParticipants: number
  rating: number
  reviewCount: number
  nextSession?: {
    date: string
    timeSlot: string
    location: string
    address?: string
  }
  images: string[]
  tags: string[]
  isAvailable: boolean
  hasWaitlist: boolean
}

interface BookingData {
  id: string
  classData: ClassData
  paymentData: any
  bookingDate: string
  status: string
  userInfo?: {
    firstName: string
    lastName: string
    email: string
    phone?: string
  }
}

// Mock class data - in real app, this would come from API
const mockClassData: ClassData = {
  id: '1',
  title: 'Beginner Pottery Workshop - Hand Building Techniques',
  description: 'Learn the fundamentals of pottery through hand-building techniques. Perfect for complete beginners who want to get their hands dirty and create beautiful ceramic pieces. We\'ll cover pinch pots, coil building, and slab construction.',
  price: 45,
  duration: 120,
  instructor: {
    id: 'instructor-1',
    name: 'Sarah Chen',
    rating: 4.8,
    verified: true,
    bio: 'Professional ceramic artist with 10+ years of teaching experience. Graduated from RISD with a focus on functional ceramics.',
    avatar: '/avatars/sarah.jpg'
  },
  category: 'Pottery',
  difficulty: 'beginner',
  maxParticipants: 8,
  currentParticipants: 6,
  rating: 4.8,
  reviewCount: 24,
  nextSession: {
    date: '2024-01-15T14:00:00Z',
    timeSlot: '2:00 PM - 4:00 PM',
    location: 'Downtown Studio',
    address: '123 Art District Blvd, Vancouver, BC'
  },
  images: ['/images/pottery-class.jpg'],
  tags: ['hand-building', 'beginner-friendly', 'ceramics'],
  isAvailable: true,
  hasWaitlist: true
}

type BookingStep = 'details' | 'guest-info' | 'payment' | 'confirmation'

export default function BookingFlow({ classId, onComplete }: BookingFlowProps) {
  const { user, isAuthenticated } = useAuthContext()
  const [currentStep, setCurrentStep] = useState<BookingStep>('details')
  const [classData, setClassData] = useState<ClassData | null>(null)
  const [bookingData, setBookingData] = useState<BookingData | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [isGuest, setIsGuest] = useState(false)
  const [guestInfo, setGuestInfo] = useState({
    firstName: '',
    lastName: '',
    email: '',
    phone: ''
  })

  useEffect(() => {
    loadClassData()
  }, [classId])

  const loadClassData = async () => {
    setIsLoading(true)
    setError(null)
    
    try {
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 1000))
      setClassData(mockClassData)
    } catch (err) {
      setError('Failed to load class details. Please try again.')
    } finally {
      setIsLoading(false)
    }
  }

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

  const getAvailabilityStatus = () => {
    if (!classData) return { text: 'Loading...', color: 'text-gray-500' }
    
    if (!classData.isAvailable && !classData.hasWaitlist) {
      return { text: 'Sold Out', color: 'text-red-600' }
    }
    if (!classData.isAvailable && classData.hasWaitlist) {
      return { text: 'Join Waitlist', color: 'text-orange-600' }
    }
    const spotsLeft = classData.maxParticipants - classData.currentParticipants
    if (spotsLeft <= 2) {
      return { text: `Only ${spotsLeft} spot${spotsLeft === 1 ? '' : 's'} left!`, color: 'text-orange-600' }
    }
    return { text: 'Available to book', color: 'text-green-600' }
  }

  const handleProceedToBooking = () => {
    if (!isAuthenticated) {
      setIsGuest(true)
      setCurrentStep('guest-info')
    } else {
      setCurrentStep('payment')
    }
  }

  const handleGuestInfoSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    
    // Validate guest info
    if (!guestInfo.firstName.trim() || !guestInfo.lastName.trim() || !guestInfo.email.trim()) {
      setError('Please fill in all required fields')
      return
    }
    
    if (!/\S+@\S+\.\S+/.test(guestInfo.email)) {
      setError('Please enter a valid email address')
      return
    }
    
    setError(null)
    setCurrentStep('payment')
  }

  const handlePaymentComplete = (paymentData: any) => {
    if (!classData) return
    
    const booking: BookingData = {
      id: `booking_${Date.now()}`,
      classData,
      paymentData,
      bookingDate: new Date().toISOString(),
      status: 'confirmed',
      userInfo: isGuest ? guestInfo : undefined
    }
    
    setBookingData(booking)
    setCurrentStep('confirmation')
  }

  const handleComplete = () => {
    onComplete?.()
  }

  const steps = [
    { id: 'details', name: 'Class Details', icon: UserIcon },
    ...(isGuest ? [{ id: 'guest-info', name: 'Your Info', icon: UserIcon }] : []),
    { id: 'payment', name: 'Payment', icon: CreditCardIcon },
    { id: 'confirmation', name: 'Confirmation', icon: CheckCircleIcon }
  ]

  const currentStepIndex = steps.findIndex(step => step.id === currentStep)

  if (isLoading) {
    return (
      <div className="max-w-4xl mx-auto py-12">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Loading class details...</p>
        </div>
      </div>
    )
  }

  if (error && !classData) {
    return (
      <div className="max-w-4xl mx-auto py-12">
        <div className="text-center bg-red-50 border border-red-200 rounded-lg p-8">
          <ExclamationTriangleIcon className="w-12 h-12 text-red-500 mx-auto mb-4" />
          <h3 className="text-lg font-semibold text-red-900 mb-2">Unable to Load Class</h3>
          <p className="text-red-700 mb-4">{error}</p>
          <button
            onClick={loadClassData}
            className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
          >
            Try Again
          </button>
        </div>
      </div>
    )
  }

  if (!classData) return null

  const availabilityStatus = getAvailabilityStatus()
  const sessionDetails = classData.nextSession ? formatDate(classData.nextSession.date) : null

  return (
    <div className="max-w-4xl mx-auto space-y-8">
      {/* Progress Steps */}
      <div className="bg-white border border-gray-200 rounded-lg p-6">
        <nav aria-label="Progress">
          <ol role="list" className="flex items-center">
            {steps.map((step, stepIdx) => {
              const isCompleted = stepIdx < currentStepIndex
              const isCurrent = stepIdx === currentStepIndex
              const Icon = step.icon
              
              return (
                <li key={step.id} className={`${stepIdx !== steps.length - 1 ? 'pr-8 sm:pr-20' : ''} relative`}>
                  <div className="flex items-center">
                    <div className={`flex items-center justify-center w-10 h-10 rounded-full border-2 ${
                      isCompleted 
                        ? 'bg-indigo-600 border-indigo-600'
                        : isCurrent
                        ? 'border-indigo-600 bg-white'
                        : 'border-gray-300 bg-white'
                    }`}>
                      {isCompleted ? (
                        <CheckCircleIcon className="w-6 h-6 text-white" />
                      ) : (
                        <Icon className={`w-5 h-5 ${
                          isCurrent ? 'text-indigo-600' : 'text-gray-400'
                        }`} />
                      )}
                    </div>
                    <span className={`ml-4 text-sm font-medium ${
                      isCompleted || isCurrent ? 'text-indigo-600' : 'text-gray-500'
                    }`}>
                      {step.name}
                    </span>
                  </div>
                  
                  {stepIdx !== steps.length - 1 && (
                    <div className="absolute top-5 left-5 -ml-px mt-0.5 w-full h-0.5">
                      <div className={`h-full ${
                        isCompleted ? 'bg-indigo-600' : 'bg-gray-300'
                      }`} />
                    </div>
                  )}
                </li>
              )
            })}
          </ol>
        </nav>
      </div>

      {/* Step Content */}
      {currentStep === 'details' && (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Class Details */}
          <div className="lg:col-span-2 space-y-6">
            {/* Class Header */}
            <div className="bg-white border border-gray-200 rounded-lg overflow-hidden">
              <div className="aspect-w-16 aspect-h-9 bg-gray-200">
                {classData.images?.[0] ? (
                  <img
                    src={classData.images[0]}
                    alt={classData.title}
                    className="w-full h-64 object-cover"
                  />
                ) : (
                  <div className="w-full h-64 bg-gradient-to-br from-indigo-100 to-purple-100 flex items-center justify-center">
                    <span className="text-indigo-600 font-medium text-xl">{classData.category}</span>
                  </div>
                )}
              </div>
              
              <div className="p-6">
                <div className="flex items-start justify-between mb-4">
                  <div className="flex-1">
                    <h1 className="text-2xl font-bold text-gray-900 mb-2">{classData.title}</h1>
                    <div className="flex items-center space-x-4 text-sm text-gray-600">
                      <div className="flex items-center">
                        <StarIcon className="w-4 h-4 text-yellow-400 fill-current mr-1" />
                        {classData.rating} ({classData.reviewCount} reviews)
                      </div>
                      <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-700">
                        {classData.difficulty.charAt(0).toUpperCase() + classData.difficulty.slice(1)}
                      </span>
                    </div>
                  </div>
                  <div className="text-right">
                    <div className="text-3xl font-bold text-gray-900">${classData.price}</div>
                    <p className={`text-sm font-medium ${availabilityStatus.color}`}>
                      {availabilityStatus.text}
                    </p>
                  </div>
                </div>

                <p className="text-gray-600 mb-6">{classData.description}</p>

                {/* Class Details Grid */}
                <div className="grid grid-cols-2 gap-4 mb-6">
                  <div className="flex items-center">
                    <ClockIcon className="w-5 h-5 text-gray-400 mr-3" />
                    <div>
                      <p className="text-sm font-medium text-gray-900">Duration</p>
                      <p className="text-sm text-gray-600">{formatDuration(classData.duration)}</p>
                    </div>
                  </div>
                  
                  <div className="flex items-center">
                    <UserGroupIcon className="w-5 h-5 text-gray-400 mr-3" />
                    <div>
                      <p className="text-sm font-medium text-gray-900">Class Size</p>
                      <p className="text-sm text-gray-600">
                        {classData.currentParticipants}/{classData.maxParticipants} enrolled
                      </p>
                    </div>
                  </div>
                  
                  {sessionDetails && classData.nextSession && (
                    <>
                      <div className="flex items-center">
                        <CalendarDaysIcon className="w-5 h-5 text-gray-400 mr-3" />
                        <div>
                          <p className="text-sm font-medium text-gray-900">Next Session</p>
                          <p className="text-sm text-gray-600">
                            {sessionDetails.weekday}, {sessionDetails.date}
                          </p>
                        </div>
                      </div>
                      
                      <div className="flex items-center">
                        <MapPinIcon className="w-5 h-5 text-gray-400 mr-3" />
                        <div>
                          <p className="text-sm font-medium text-gray-900">Location</p>
                          <p className="text-sm text-gray-600">{classData.nextSession.location}</p>
                        </div>
                      </div>
                    </>
                  )}
                </div>

                {/* Tags */}
                {classData.tags && classData.tags.length > 0 && (
                  <div className="flex flex-wrap gap-2">
                    {classData.tags.map((tag, index) => (
                      <span 
                        key={index}
                        className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-indigo-100 text-indigo-700"
                      >
                        {tag}
                      </span>
                    ))}
                  </div>
                )}
              </div>
            </div>

            {/* Instructor Info */}
            <div className="bg-white border border-gray-200 rounded-lg p-6">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">Your Instructor</h2>
              <div className="flex items-start space-x-4">
                <div className="w-16 h-16 bg-indigo-500 rounded-full flex items-center justify-center flex-shrink-0">
                  <span className="text-white font-semibold text-lg">
                    {classData.instructor.name.charAt(0)}
                  </span>
                </div>
                <div className="flex-1">
                  <div className="flex items-center mb-2">
                    <h3 className="text-lg font-semibold text-gray-900">
                      {classData.instructor.name}
                    </h3>
                    {classData.instructor.verified && (
                      <span className="ml-2 text-indigo-600 text-sm">✓ Verified</span>
                    )}
                  </div>
                  <div className="flex items-center mb-3">
                    <StarIcon className="w-4 h-4 text-yellow-400 fill-current mr-1" />
                    <span className="text-sm text-gray-600">{classData.instructor.rating} rating</span>
                  </div>
                  {classData.instructor.bio && (
                    <p className="text-sm text-gray-600">{classData.instructor.bio}</p>
                  )}
                </div>
              </div>
            </div>
          </div>

          {/* Booking Summary Sidebar */}
          <div className="lg:col-span-1">
            <div className="bg-white border border-gray-200 rounded-lg p-6 sticky top-6">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">Booking Summary</h2>
              
              {sessionDetails && classData.nextSession && (
                <div className="space-y-3 mb-6">
                  <div>
                    <p className="text-sm font-medium text-gray-900">Date & Time</p>
                    <p className="text-sm text-gray-600">
                      {sessionDetails.weekday}, {sessionDetails.date}
                    </p>
                    <p className="text-sm text-gray-600">{classData.nextSession.timeSlot}</p>
                  </div>
                  <div>
                    <p className="text-sm font-medium text-gray-900">Duration</p>
                    <p className="text-sm text-gray-600">{formatDuration(classData.duration)}</p>
                  </div>
                  <div>
                    <p className="text-sm font-medium text-gray-900">Location</p>
                    <p className="text-sm text-gray-600">{classData.nextSession.location}</p>
                  </div>
                </div>
              )}

              <div className="border-t border-gray-200 pt-4 mb-6">
                <div className="flex justify-between items-center">
                  <span className="text-base font-medium text-gray-900">Class fee</span>
                  <span className="text-xl font-bold text-gray-900">${classData.price}</span>
                </div>
              </div>

              {error && (
                <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg">
                  <p className="text-sm text-red-700">{error}</p>
                </div>
              )}

              <button
                onClick={handleProceedToBooking}
                disabled={!classData.isAvailable && !classData.hasWaitlist}
                className="w-full py-3 px-4 bg-indigo-600 text-white font-medium rounded-lg hover:bg-indigo-700 disabled:bg-gray-300 disabled:cursor-not-allowed transition-colors"
              >
                {classData.isAvailable 
                  ? 'Book This Class' 
                  : classData.hasWaitlist 
                  ? 'Join Waitlist' 
                  : 'Sold Out'
                }
              </button>
              
              <p className="text-xs text-gray-500 text-center mt-3">
                {isAuthenticated ? 'Secure checkout' : 'You can book as a guest or sign in'}
              </p>
            </div>
          </div>
        </div>
      )}

      {/* Guest Info Step */}
      {currentStep === 'guest-info' && (
        <div className="max-w-md mx-auto bg-white border border-gray-200 rounded-lg p-6">
          <h2 className="text-2xl font-bold text-gray-900 mb-6 text-center">Your Information</h2>
          
          {error && (
            <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg">
              <p className="text-sm text-red-700">{error}</p>
            </div>
          )}
          
          <form onSubmit={handleGuestInfoSubmit} className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  First Name *
                </label>
                <input
                  type="text"
                  required
                  value={guestInfo.firstName}
                  onChange={(e) => setGuestInfo(prev => ({ ...prev, firstName: e.target.value }))}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-indigo-500 focus:border-indigo-500"
                />
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Last Name *
                </label>
                <input
                  type="text"
                  required
                  value={guestInfo.lastName}
                  onChange={(e) => setGuestInfo(prev => ({ ...prev, lastName: e.target.value }))}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-indigo-500 focus:border-indigo-500"
                />
              </div>
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Email Address *
              </label>
              <input
                type="email"
                required
                value={guestInfo.email}
                onChange={(e) => setGuestInfo(prev => ({ ...prev, email: e.target.value }))}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-indigo-500 focus:border-indigo-500"
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Phone Number (optional)
              </label>
              <input
                type="tel"
                value={guestInfo.phone}
                onChange={(e) => setGuestInfo(prev => ({ ...prev, phone: e.target.value }))}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-indigo-500 focus:border-indigo-500"
              />
            </div>
            
            <div className="flex space-x-4 pt-6">
              <button
                type="button"
                onClick={() => setCurrentStep('details')}
                className="flex-1 px-6 py-3 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 transition-colors"
              >
                Back
              </button>
              
              <button
                type="submit"
                className="flex-1 px-6 py-3 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors"
              >
                Continue to Payment
              </button>
            </div>
          </form>
        </div>
      )}

      {/* Payment Step */}
      {currentStep === 'payment' && (
        <PaymentStep
          classData={classData}
          onPaymentComplete={handlePaymentComplete}
          onBack={() => setCurrentStep(isGuest ? 'guest-info' : 'details')}
          isGuest={isGuest}
        />
      )}

      {/* Confirmation Step */}
      {currentStep === 'confirmation' && bookingData && (
        <ConfirmationStep
          bookingData={bookingData}
          onComplete={handleComplete}
        />
      )}
    </div>
  )
}