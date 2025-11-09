/**
 * Student Home Page
 * Main landing page for students with quick access to key features
 */

'use client'

import React, { useState, useEffect } from 'react'
import Link from 'next/link'
import { useAuthContext } from '@/lib/context/AuthContext'
import { 
  MagnifyingGlassIcon,
  CalendarDaysIcon,
  HeartIcon,
  BookmarkIcon,
  StarIcon,
  MapPinIcon,
  ClockIcon,
  UserGroupIcon,
  ArrowRightIcon
} from '@heroicons/react/24/outline'
import { HeartIcon as HeartIconSolid } from '@heroicons/react/24/solid'

// Mock data for development
const mockRecentClasses = [
  {
    id: '1',
    title: 'Beginner Pottery Workshop',
    instructor: 'Sarah Chen',
    date: '2024-01-15T14:00:00Z',
    price: 45,
    rating: 4.8,
    reviewCount: 24,
    image: '/images/pottery-class.jpg',
    category: 'Pottery',
    location: 'Downtown Studio'
  },
  {
    id: '2',
    title: 'Watercolor Painting Basics',
    instructor: 'Michael Torres',
    date: '2024-01-16T10:00:00Z',
    price: 35,
    rating: 4.9,
    reviewCount: 18,
    image: '/images/painting-class.jpg',
    category: 'Painting',
    location: 'Art Center'
  }
]

const mockUpcomingBookings = [
  {
    id: '1',
    title: 'Advanced Ceramics',
    instructor: 'Sarah Chen',
    date: '2024-01-20T14:00:00Z',
    location: 'Downtown Studio',
    status: 'confirmed'
  }
]

const mockRecommendations = [
  {
    id: '3',
    title: 'Jewelry Making Workshop',
    instructor: 'Emma Rodriguez',
    date: '2024-01-18T13:00:00Z',
    price: 55,
    rating: 4.7,
    reviewCount: 31,
    image: '/images/jewelry-class.jpg',
    category: 'Crafts',
    location: 'Creative Space',
    reason: 'Based on your pottery interests'
  },
  {
    id: '4',
    title: 'Calligraphy for Beginners',
    instructor: 'David Kim',
    date: '2024-01-19T15:30:00Z',
    price: 40,
    rating: 4.6,
    reviewCount: 22,
    image: '/images/calligraphy-class.jpg',
    category: 'Art',
    location: 'East Side Studio',
    reason: 'Popular in your area'
  }
]

export default function StudentHomePage() {
  const { user } = useAuthContext()
  const [savedClasses, setSavedClasses] = useState<Set<string>>(new Set())

  const toggleSave = (classId: string) => {
    setSavedClasses(prev => {
      const newSaved = new Set(prev)
      if (newSaved.has(classId)) {
        newSaved.delete(classId)
      } else {
        newSaved.add(classId)
      }
      return newSaved
    })
  }

  const formatDate = (dateString: string) => {
    const date = new Date(dateString)
    return date.toLocaleDateString('en-US', { 
      weekday: 'short', 
      month: 'short', 
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
      hour12: true
    })
  }

  const QuickActionCard = ({ icon: Icon, title, description, href, color }: {
    icon: React.ElementType
    title: string
    description: string
    href: string
    color: string
  }) => (
    <Link href={href} className="group">
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 hover:shadow-md transition-shadow duration-200">
        <div className={`inline-flex items-center justify-center w-12 h-12 rounded-lg ${color} mb-4`}>
          <Icon className="w-6 h-6 text-white" />
        </div>
        <h3 className="text-lg font-medium text-gray-900 mb-2 group-hover:text-indigo-600 transition-colors">
          {title}
        </h3>
        <p className="text-sm text-gray-500">{description}</p>
      </div>
    </Link>
  )

  const ClassCard = ({ classData, isRecommendation = false }: { 
    classData: any
    isRecommendation?: boolean 
  }) => (
    <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden hover:shadow-md transition-shadow duration-200">
      <div className="aspect-w-16 aspect-h-9 bg-gray-200">
        <div className="w-full h-32 bg-gradient-to-br from-indigo-100 to-purple-100 flex items-center justify-center">
          <span className="text-indigo-600 font-medium">{classData.category}</span>
        </div>
      </div>
      
      <div className="p-4">
        <div className="flex justify-between items-start mb-2">
          <h3 className="text-sm font-medium text-gray-900 truncate flex-1">
            {classData.title}
          </h3>
          <button
            onClick={() => toggleSave(classData.id)}
            className="ml-2 p-1 rounded-full hover:bg-gray-100 transition-colors"
            aria-label={savedClasses.has(classData.id) ? 'Remove from saved' : 'Save class'}
          >
            {savedClasses.has(classData.id) ? (
              <BookmarkIcon className="w-5 h-5 text-indigo-600 fill-current" />
            ) : (
              <BookmarkIcon className="w-5 h-5 text-gray-400" />
            )}
          </button>
        </div>
        
        <p className="text-xs text-gray-500 mb-2">{classData.instructor}</p>
        
        <div className="flex items-center mb-2">
          <div className="flex items-center">
            <StarIcon className="w-4 h-4 text-yellow-400 fill-current" />
            <span className="text-xs text-gray-600 ml-1">
              {classData.rating} ({classData.reviewCount})
            </span>
          </div>
        </div>
        
        <div className="flex items-center justify-between text-xs text-gray-500 mb-3">
          <div className="flex items-center">
            <MapPinIcon className="w-3 h-3 mr-1" />
            {classData.location}
          </div>
          <div className="flex items-center">
            <ClockIcon className="w-3 h-3 mr-1" />
            {formatDate(classData.date)}
          </div>
        </div>
        
        {isRecommendation && classData.reason && (
          <p className="text-xs text-indigo-600 mb-3 italic">{classData.reason}</p>
        )}
        
        <div className="flex items-center justify-between">
          <span className="text-lg font-semibold text-gray-900">${classData.price}</span>
          <Link
            href={`/student/booking/${classData.id}`}
            className="bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-medium px-3 py-2 rounded-md transition-colors"
          >
            Book Now
          </Link>
        </div>
      </div>
    </div>
  )

  return (
    <div className="space-y-8">
      {/* Welcome Header */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h1 className="text-2xl font-bold text-gray-900 mb-2">
          Welcome back, {user?.user_metadata?.first_name || user?.email?.split('@')[0] || 'there'}! 👋
        </h1>
        <p className="text-gray-600">
          Discover amazing classes and connect with talented instructors in your area.
        </p>
      </div>

      {/* Quick Actions */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <QuickActionCard
          icon={MagnifyingGlassIcon}
          title="Discover Classes"
          description="Find your next creative adventure"
          href="/student/discovery"
          color="bg-indigo-600"
        />
        <QuickActionCard
          icon={CalendarDaysIcon}
          title="My Bookings"
          description="View your upcoming classes"
          href="/student/dashboard/bookings"
          color="bg-green-600"
        />
        <QuickActionCard
          icon={HeartIcon}
          title="Following"
          description="Check your favorite instructors"
          href="/student/dashboard/following"
          color="bg-pink-600"
        />
        <QuickActionCard
          icon={BookmarkIcon}
          title="Saved Classes"
          description="Classes you want to book later"
          href="/student/dashboard/saved"
          color="bg-purple-600"
        />
      </div>

      {/* Upcoming Bookings */}
      {mockUpcomingBookings.length > 0 && (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold text-gray-900">Upcoming Classes</h2>
            <Link
              href="/student/dashboard/bookings"
              className="text-indigo-600 hover:text-indigo-700 text-sm font-medium flex items-center"
            >
              View all
              <ArrowRightIcon className="w-4 h-4 ml-1" />
            </Link>
          </div>
          <div className="space-y-3">
            {mockUpcomingBookings.map((booking) => (
              <div
                key={booking.id}
                className="flex items-center p-3 bg-gray-50 rounded-lg"
              >
                <div className="flex-1">
                  <h3 className="text-sm font-medium text-gray-900">{booking.title}</h3>
                  <p className="text-xs text-gray-500">with {booking.instructor}</p>
                  <div className="flex items-center mt-1 text-xs text-gray-500">
                    <ClockIcon className="w-3 h-3 mr-1" />
                    {formatDate(booking.date)}
                    <MapPinIcon className="w-3 h-3 ml-3 mr-1" />
                    {booking.location}
                  </div>
                </div>
                <div className="flex items-center">
                  <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
                    Confirmed
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Recently Viewed */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold text-gray-900">Recently Viewed</h2>
          <Link
            href="/student/discovery"
            className="text-indigo-600 hover:text-indigo-700 text-sm font-medium flex items-center"
          >
            Explore more
            <ArrowRightIcon className="w-4 h-4 ml-1" />
          </Link>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {mockRecentClasses.map((classData) => (
            <ClassCard key={classData.id} classData={classData} />
          ))}
        </div>
      </div>

      {/* Recommendations */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h2 className="text-lg font-semibold text-gray-900">Recommended for You</h2>
            <p className="text-sm text-gray-500">Curated based on your interests and activity</p>
          </div>
          <Link
            href="/student/dashboard/recommendations"
            className="text-indigo-600 hover:text-indigo-700 text-sm font-medium flex items-center"
          >
            View all
            <ArrowRightIcon className="w-4 h-4 ml-1" />
          </Link>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {mockRecommendations.map((classData) => (
            <ClassCard key={classData.id} classData={classData} isRecommendation={true} />
          ))}
        </div>
      </div>

      {/* Stats Overview */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4 text-center">
          <div className="text-2xl font-bold text-indigo-600 mb-1">12</div>
          <div className="text-sm text-gray-500">Classes Completed</div>
        </div>
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4 text-center">
          <div className="text-2xl font-bold text-green-600 mb-1">3</div>
          <div className="text-sm text-gray-500">Instructors Following</div>
        </div>
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4 text-center">
          <div className="text-2xl font-bold text-purple-600 mb-1">8</div>
          <div className="text-sm text-gray-500">Classes Saved</div>
        </div>
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4 text-center">
          <div className="text-2xl font-bold text-pink-600 mb-1">4.9</div>
          <div className="text-sm text-gray-500">Avg Rating Given</div>
        </div>
      </div>
    </div>
  )
}
