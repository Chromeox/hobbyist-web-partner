/**
 * Following Component
 * Displays followed instructors and their latest classes
 */

'use client'

import React, { useState } from 'react'
import Link from 'next/link'
import { 
  HeartIcon,
  StarIcon,
  MapPinIcon,
  CalendarDaysIcon,
  UserIcon,
  BellIcon,
  EllipsisHorizontalIcon,
  MagnifyingGlassIcon
} from '@heroicons/react/24/outline'
import {
  HeartIcon as HeartIconSolid,
  BellIcon as BellIconSolid
} from '@heroicons/react/24/solid'

interface FollowedInstructor {
  id: string
  name: string
  bio: string
  rating: number
  reviewCount: number
  totalStudents: number
  verified: boolean
  specialties: string[]
  avatar?: string
  followedAt: string
  notificationsEnabled: boolean
  latestClasses: {
    id: string
    title: string
    price: number
    date?: string
    timeSlot?: string
    location?: string
    spotsLeft?: number
    isAvailable: boolean
  }[]
  upcomingClassesCount: number
}

// Mock data for development
const mockFollowedInstructors: FollowedInstructor[] = [
  {
    id: 'instructor_1',
    name: 'Sarah Chen',
    bio: 'Professional ceramic artist with 10+ years of teaching experience. Specializes in hand-building techniques and glazing.',
    rating: 4.8,
    reviewCount: 124,
    totalStudents: 350,
    verified: true,
    specialties: ['Pottery', 'Ceramics', 'Hand-building'],
    followedAt: '2023-12-15T10:00:00Z',
    notificationsEnabled: true,
    upcomingClassesCount: 3,
    latestClasses: [
      {
        id: 'class_1',
        title: 'Advanced Wheel Throwing',
        price: 65,
        date: '2024-01-25T14:00:00Z',
        timeSlot: '2:00 PM - 4:30 PM',
        location: 'Downtown Studio',
        spotsLeft: 2,
        isAvailable: true
      },
      {
        id: 'class_2',
        title: 'Glazing Techniques Workshop',
        price: 55,
        date: '2024-01-30T10:00:00Z',
        timeSlot: '10:00 AM - 1:00 PM',
        location: 'Downtown Studio',
        spotsLeft: 0,
        isAvailable: false
      }
    ]
  },
  {
    id: 'instructor_2',
    name: 'Michael Torres',
    bio: 'Watercolor specialist and former art teacher. Loves helping students discover the joy of painting landscapes and nature.',
    rating: 4.9,
    reviewCount: 89,
    totalStudents: 200,
    verified: true,
    specialties: ['Watercolor', 'Landscape Painting', 'Color Theory'],
    followedAt: '2024-01-02T15:30:00Z',
    notificationsEnabled: false,
    upcomingClassesCount: 2,
    latestClasses: [
      {
        id: 'class_3',
        title: 'Sunset Seascapes in Watercolor',
        price: 40,
        date: '2024-01-22T16:00:00Z',
        timeSlot: '4:00 PM - 6:30 PM',
        location: 'Art Center',
        spotsLeft: 5,
        isAvailable: true
      }
    ]
  },
  {
    id: 'instructor_3',
    name: 'Emma Rodriguez',
    bio: 'Jewelry designer and metalworking artist. Creates contemporary pieces using traditional techniques.',
    rating: 4.7,
    reviewCount: 67,
    totalStudents: 150,
    verified: true,
    specialties: ['Jewelry Making', 'Metalworking', 'Wire Wrapping'],
    followedAt: '2023-11-20T09:15:00Z',
    notificationsEnabled: true,
    upcomingClassesCount: 1,
    latestClasses: [
      {
        id: 'class_4',
        title: 'Silver Ring Making Workshop',
        price: 85,
        date: '2024-02-05T13:00:00Z',
        timeSlot: '1:00 PM - 5:00 PM',
        location: 'Creative Space',
        spotsLeft: 1,
        isAvailable: true
      }
    ]
  }
]

export default function Following() {
  const [instructors, setInstructors] = useState<FollowedInstructor[]>(mockFollowedInstructors)
  const [searchTerm, setSearchTerm] = useState('')
  const [selectedInstructor, setSelectedInstructor] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(false)

  const filteredInstructors = instructors.filter(instructor =>
    instructor.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    instructor.specialties.some(specialty => 
      specialty.toLowerCase().includes(searchTerm.toLowerCase())
    )
  )

  const handleUnfollow = async (instructorId: string) => {
    if (!confirm('Are you sure you want to unfollow this instructor?')) return

    setIsLoading(true)
    try {
      // API call to unfollow instructor
      setInstructors(prev => prev.filter(instructor => instructor.id !== instructorId))
    } catch (error) {
      console.error('Failed to unfollow instructor:', error)
    } finally {
      setIsLoading(false)
    }
  }

  const handleToggleNotifications = async (instructorId: string) => {
    setIsLoading(true)
    try {
      // API call to toggle notifications
      setInstructors(prev => prev.map(instructor => 
        instructor.id === instructorId
          ? { ...instructor, notificationsEnabled: !instructor.notificationsEnabled }
          : instructor
      ))
    } catch (error) {
      console.error('Failed to update notifications:', error)
    } finally {
      setIsLoading(false)
    }
  }

  const formatFollowedDate = (dateString: string) => {
    const date = new Date(dateString)
    return date.toLocaleDateString('en-US', { 
      month: 'short', 
      year: 'numeric' 
    })
  }

  const formatClassDate = (dateString: string) => {
    const date = new Date(dateString)
    const now = new Date()
    const diffTime = date.getTime() - now.getTime()
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
    
    if (diffDays === 0) return 'Today'
    if (diffDays === 1) return 'Tomorrow'
    if (diffDays > 0 && diffDays <= 7) return `In ${diffDays} days`
    
    return date.toLocaleDateString('en-US', { 
      month: 'short', 
      day: 'numeric' 
    })
  }

  const InstructorCard = ({ instructor }: { instructor: FollowedInstructor }) => (
    <div className="bg-white border border-gray-200 rounded-lg p-6 hover:shadow-md transition-shadow">
      <div className="flex items-start justify-between mb-4">
        <div className="flex items-start space-x-4 flex-1">
          <div className="w-16 h-16 bg-indigo-500 rounded-full flex items-center justify-center flex-shrink-0">
            <span className="text-white font-semibold text-lg">
              {instructor.name.charAt(0)}
            </span>
          </div>
          
          <div className="flex-1 min-w-0">
            <div className="flex items-center mb-2">
              <h3 className="text-lg font-semibold text-gray-900 truncate">
                {instructor.name}
              </h3>
              {instructor.verified && (
                <span className="ml-2 text-indigo-600 text-sm">✓</span>
              )}
            </div>
            
            <div className="flex items-center text-sm text-gray-600 mb-2">
              <StarIcon className="w-4 h-4 text-yellow-400 fill-current mr-1" />
              {instructor.rating} ({instructor.reviewCount} reviews)
              <span className="mx-2">•</span>
              {instructor.totalStudents} students
            </div>
            
            <p className="text-sm text-gray-600 mb-3 line-clamp-2">
              {instructor.bio}
            </p>
            
            <div className="flex flex-wrap gap-2 mb-3">
              {instructor.specialties.slice(0, 3).map((specialty, index) => (
                <span
                  key={index}
                  className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-indigo-100 text-indigo-700"
                >
                  {specialty}
                </span>
              ))}
              {instructor.specialties.length > 3 && (
                <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-700">
                  +{instructor.specialties.length - 3} more
                </span>
              )}
            </div>
            
            <p className="text-xs text-gray-500">
              Following since {formatFollowedDate(instructor.followedAt)}
            </p>
          </div>
        </div>

        <div className="flex items-center space-x-2 ml-4">
          <button
            onClick={() => handleToggleNotifications(instructor.id)}
            disabled={isLoading}
            className={`p-2 rounded-full transition-colors disabled:opacity-50 ${
              instructor.notificationsEnabled
                ? 'text-indigo-600 bg-indigo-100 hover:bg-indigo-200'
                : 'text-gray-400 bg-gray-100 hover:bg-gray-200'
            }`}
            title={instructor.notificationsEnabled ? 'Disable notifications' : 'Enable notifications'}
          >
            {instructor.notificationsEnabled ? (
              <BellIconSolid className="w-4 h-4" />
            ) : (
              <BellIcon className="w-4 h-4" />
            )}
          </button>
          
          <div className="relative">
            <button
              onClick={() => setSelectedInstructor(
                selectedInstructor === instructor.id ? null : instructor.id
              )}
              className="p-2 text-gray-400 hover:text-gray-600 rounded-full hover:bg-gray-100 transition-colors"
              title="More options"
            >
              <EllipsisHorizontalIcon className="w-4 h-4" />
            </button>
            
            {selectedInstructor === instructor.id && (
              <div className="absolute right-0 top-10 z-10 w-48 bg-white border border-gray-200 rounded-lg shadow-lg py-1">
                <Link
                  href={`/instructor/${instructor.id}`}
                  className="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                >
                  View Profile
                </Link>
                <button
                  onClick={() => console.log('Message instructor')}
                  className="w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                >
                  Send Message
                </button>
                <button
                  onClick={() => handleUnfollow(instructor.id)}
                  disabled={isLoading}
                  className="w-full text-left px-4 py-2 text-sm text-red-600 hover:bg-red-50 disabled:opacity-50"
                >
                  Unfollow
                </button>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Latest Classes */}
      {instructor.latestClasses.length > 0 && (
        <div className="border-t border-gray-200 pt-4">
          <div className="flex items-center justify-between mb-3">
            <h4 className="text-sm font-medium text-gray-900">Latest Classes</h4>
            {instructor.upcomingClassesCount > instructor.latestClasses.length && (
              <Link
                href={`/instructor/${instructor.id}/classes`}
                className="text-sm text-indigo-600 hover:text-indigo-700 font-medium"
              >
                View all ({instructor.upcomingClassesCount})
              </Link>
            )}
          </div>
          
          <div className="space-y-3">
            {instructor.latestClasses.map((classData) => (
              <div
                key={classData.id}
                className="flex items-center justify-between p-3 bg-gray-50 rounded-lg"
              >
                <div className="flex-1 min-w-0">
                  <h5 className="text-sm font-medium text-gray-900 truncate">
                    {classData.title}
                  </h5>
                  <div className="flex items-center mt-1 text-xs text-gray-600">
                    {classData.date && (
                      <>
                        <CalendarDaysIcon className="w-3 h-3 mr-1" />
                        {formatClassDate(classData.date)}
                        {classData.timeSlot && (
                          <>
                            <span className="mx-2">•</span>
                            {classData.timeSlot}
                          </>
                        )}
                      </>
                    )}
                    {classData.location && (
                      <>
                        <span className="mx-2">•</span>
                        <MapPinIcon className="w-3 h-3 mr-1" />
                        {classData.location}
                      </>
                    )}
                  </div>
                  {typeof classData.spotsLeft === 'number' && (
                    <p className={`text-xs mt-1 ${
                      classData.spotsLeft === 0 
                        ? 'text-red-600' 
                        : classData.spotsLeft <= 2 
                        ? 'text-orange-600' 
                        : 'text-green-600'
                    }`}>
                      {classData.spotsLeft === 0 
                        ? 'Sold out' 
                        : `${classData.spotsLeft} spot${classData.spotsLeft === 1 ? '' : 's'} left`
                      }
                    </p>
                  )}
                </div>
                
                <div className="flex items-center space-x-3 ml-4">
                  <span className="text-sm font-semibold text-gray-900">
                    ${classData.price}
                  </span>
                  <Link
                    href={`/student/booking/${classData.id}`}
                    className={`px-3 py-1 text-xs font-medium rounded-md transition-colors ${
                      classData.isAvailable
                        ? 'bg-indigo-600 text-white hover:bg-indigo-700'
                        : 'bg-gray-300 text-gray-500 cursor-not-allowed'
                    }`}
                  >
                    {classData.isAvailable ? 'Book' : 'Full'}
                  </Link>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  )

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Following</h1>
          <p className="text-gray-600 mt-1">
            Stay updated with your favorite instructors and their latest classes
          </p>
        </div>
        <Link
          href="/student/discovery"
          className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
        >
          Find More Instructors
        </Link>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-white border border-gray-200 rounded-lg p-4">
          <div className="text-2xl font-bold text-gray-900">{instructors.length}</div>
          <div className="text-sm text-gray-500">Instructors Following</div>
        </div>
        <div className="bg-white border border-gray-200 rounded-lg p-4">
          <div className="text-2xl font-bold text-indigo-600">
            {instructors.reduce((sum, instructor) => sum + instructor.upcomingClassesCount, 0)}
          </div>
          <div className="text-sm text-gray-500">Upcoming Classes</div>
        </div>
        <div className="bg-white border border-gray-200 rounded-lg p-4">
          <div className="text-2xl font-bold text-green-600">
            {instructors.filter(instructor => instructor.notificationsEnabled).length}
          </div>
          <div className="text-sm text-gray-500">Notifications Enabled</div>
        </div>
      </div>

      {/* Search */}
      <div className="relative">
        <MagnifyingGlassIcon className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
        <input
          type="text"
          placeholder="Search instructors..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm"
        />
      </div>

      {/* Instructors List */}
      {filteredInstructors.length === 0 ? (
        <div className="text-center py-12 bg-white border border-gray-200 rounded-lg">
          {searchTerm ? (
            <>
              <MagnifyingGlassIcon className="w-12 h-12 text-gray-400 mx-auto mb-4" />
              <h3 className="text-lg font-medium text-gray-900 mb-2">No instructors found</h3>
              <p className="text-gray-600 mb-4">
                Try adjusting your search terms to find instructors.
              </p>
              <button
                onClick={() => setSearchTerm('')}
                className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-indigo-600 bg-indigo-100 hover:bg-indigo-200"
              >
                Clear search
              </button>
            </>
          ) : (
            <>
              <HeartIcon className="w-12 h-12 text-gray-400 mx-auto mb-4" />
              <h3 className="text-lg font-medium text-gray-900 mb-2">No instructors followed yet</h3>
              <p className="text-gray-600 mb-4">
                Follow your favorite instructors to stay updated on their latest classes.
              </p>
              <Link
                href="/student/discovery"
                className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
              >
                Explore Instructors
              </Link>
            </>
          )}
        </div>
      ) : (
        <div className="space-y-6">
          {filteredInstructors.map((instructor) => (
            <InstructorCard key={instructor.id} instructor={instructor} />
          ))}
        </div>
      )}

      {/* Click outside handler for dropdowns */}
      {selectedInstructor && (
        <div
          className="fixed inset-0 z-5"
          onClick={() => setSelectedInstructor(null)}
        />
      )}
    </div>
  )
}