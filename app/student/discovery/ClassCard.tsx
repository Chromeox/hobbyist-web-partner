/**
 * Class Card Component
 * Displays class information in a card format for the discovery page
 */

'use client'

import React, { useState } from 'react'
import Link from 'next/link'
import { 
  StarIcon,
  MapPinIcon,
  ClockIcon,
  UserGroupIcon,
  BookmarkIcon,
  HeartIcon,
  ShareIcon,
  CalendarDaysIcon
} from '@heroicons/react/24/outline'
import {
  StarIcon as StarIconSolid,
  BookmarkIcon as BookmarkIconSolid,
  HeartIcon as HeartIconSolid
} from '@heroicons/react/24/solid'

export interface ClassData {
  id: string
  title: string
  description: string
  instructor: {
    id: string
    name: string
    rating: number
    reviewCount: number
    verified: boolean
    avatar?: string
  }
  category: string
  price: number
  duration: number
  difficulty: 'beginner' | 'intermediate' | 'advanced' | 'all_levels'
  maxParticipants: number
  currentParticipants: number
  rating: number
  reviewCount: number
  nextSession?: {
    date: string
    timeSlot: string
    location: string
  }
  images: string[]
  tags: string[]
  isAvailable: boolean
  hasWaitlist: boolean
  isFavorited?: boolean
  isSaved?: boolean
}

interface ClassCardProps {
  classData: ClassData
  onToggleFavorite?: (classId: string) => void
  onToggleSave?: (classId: string) => void
  onShare?: (classId: string) => void
  variant?: 'grid' | 'list'
  showInstructor?: boolean
}

const difficultyColors = {
  beginner: 'bg-green-100 text-green-800',
  intermediate: 'bg-yellow-100 text-yellow-800',
  advanced: 'bg-red-100 text-red-800',
  all_levels: 'bg-blue-100 text-blue-800'
}

const difficultyLabels = {
  beginner: 'Beginner',
  intermediate: 'Intermediate',
  advanced: 'Advanced',
  all_levels: 'All Levels'
}

export default function ClassCard({ 
  classData, 
  onToggleFavorite,
  onToggleSave,
  onShare,
  variant = 'grid',
  showInstructor = true
}: ClassCardProps) {
  const [imageLoaded, setImageLoaded] = useState(false)
  const [imageError, setImageError] = useState(false)

  const formatDate = (dateString: string) => {
    const date = new Date(dateString)
    return date.toLocaleDateString('en-US', { 
      weekday: 'short', 
      month: 'short', 
      day: 'numeric' 
    })
  }

  const formatDuration = (minutes: number) => {
    const hours = Math.floor(minutes / 60)
    const mins = minutes % 60
    if (hours === 0) return `${mins}m`
    if (mins === 0) return `${hours}h`
    return `${hours}h ${mins}m`
  }

  const getAvailabilityStatus = () => {
    if (!classData.isAvailable && !classData.hasWaitlist) {
      return { text: 'Sold Out', color: 'text-red-600', bg: 'bg-red-100' }
    }
    if (!classData.isAvailable && classData.hasWaitlist) {
      return { text: 'Join Waitlist', color: 'text-orange-600', bg: 'bg-orange-100' }
    }
    const spotsLeft = classData.maxParticipants - classData.currentParticipants
    if (spotsLeft <= 2) {
      return { text: `${spotsLeft} spot${spotsLeft === 1 ? '' : 's'} left`, color: 'text-orange-600', bg: 'bg-orange-100' }
    }
    return { text: 'Available', color: 'text-green-600', bg: 'bg-green-100' }
  }

  const availabilityStatus = getAvailabilityStatus()

  const handleToggleFavorite = (e: React.MouseEvent) => {
    e.preventDefault()
    e.stopPropagation()
    onToggleFavorite?.(classData.id)
  }

  const handleToggleSave = (e: React.MouseEvent) => {
    e.preventDefault()
    e.stopPropagation()
    onToggleSave?.(classData.id)
  }

  const handleShare = (e: React.MouseEvent) => {
    e.preventDefault()
    e.stopPropagation()
    onShare?.(classData.id)
  }

  if (variant === 'list') {
    return (
      <Link href={`/student/booking/${classData.id}`} className="group">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4 hover:shadow-md transition-all duration-200 hover:border-indigo-200">
          <div className="flex space-x-4">
            {/* Image */}
            <div className="flex-shrink-0 w-24 h-24 relative">
              {!imageError && classData.images?.[0] ? (
                <img
                  src={classData.images[0]}
                  alt={classData.title}
                  className={`w-full h-full object-cover rounded-lg transition-opacity duration-200 ${
                    imageLoaded ? 'opacity-100' : 'opacity-0'
                  }`}
                  onLoad={() => setImageLoaded(true)}
                  onError={() => setImageError(true)}
                />
              ) : (
                <div className="w-full h-full bg-gradient-to-br from-indigo-100 to-purple-100 rounded-lg flex items-center justify-center">
                  <span className="text-indigo-600 font-medium text-xs text-center">
                    {classData.category}
                  </span>
                </div>
              )}
            </div>

            {/* Content */}
            <div className="flex-1 min-w-0">
              <div className="flex justify-between items-start mb-2">
                <div className="flex-1">
                  <h3 className="text-lg font-semibold text-gray-900 group-hover:text-indigo-600 transition-colors line-clamp-1">
                    {classData.title}
                  </h3>
                  {showInstructor && (
                    <p className="text-sm text-gray-600 flex items-center">
                      by {classData.instructor.name}
                      {classData.instructor.verified && (
                        <span className="ml-1 text-indigo-600">✓</span>
                      )}
                    </p>
                  )}
                </div>
                <div className="flex items-center space-x-1 ml-4">
                  <button
                    onClick={handleToggleSave}
                    className="p-1 text-gray-400 hover:text-indigo-600 transition-colors"
                    aria-label={classData.isSaved ? 'Remove from saved' : 'Save class'}
                  >
                    {classData.isSaved ? (
                      <BookmarkIconSolid className="w-5 h-5 text-indigo-600" />
                    ) : (
                      <BookmarkIcon className="w-5 h-5" />
                    )}
                  </button>
                  <button
                    onClick={handleShare}
                    className="p-1 text-gray-400 hover:text-gray-600 transition-colors"
                    aria-label="Share class"
                  >
                    <ShareIcon className="w-5 h-5" />
                  </button>
                </div>
              </div>

              <p className="text-sm text-gray-600 line-clamp-2 mb-3">
                {classData.description}
              </p>

              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-4 text-sm text-gray-500">
                  <div className="flex items-center">
                    <StarIcon className="w-4 h-4 text-yellow-400 fill-current mr-1" />
                    {classData.rating} ({classData.reviewCount})
                  </div>
                  <div className="flex items-center">
                    <ClockIcon className="w-4 h-4 mr-1" />
                    {formatDuration(classData.duration)}
                  </div>
                  <div className="flex items-center">
                    <UserGroupIcon className="w-4 h-4 mr-1" />
                    {classData.currentParticipants}/{classData.maxParticipants}
                  </div>
                  {classData.nextSession && (
                    <div className="flex items-center">
                      <CalendarDaysIcon className="w-4 h-4 mr-1" />
                      {formatDate(classData.nextSession.date)}
                    </div>
                  )}
                </div>
                <div className="flex items-center space-x-3">
                  <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${availabilityStatus.bg} ${availabilityStatus.color}`}>
                    {availabilityStatus.text}
                  </span>
                  <span className="text-lg font-bold text-gray-900">${classData.price}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </Link>
    )
  }

  return (
    <Link href={`/student/booking/${classData.id}`} className="group">
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden hover:shadow-md transition-all duration-200 hover:border-indigo-200">
        {/* Image Container */}
        <div className="aspect-w-16 aspect-h-10 bg-gray-200 relative">
          {!imageError && classData.images?.[0] ? (
            <img
              src={classData.images[0]}
              alt={classData.title}
              className={`w-full h-48 object-cover transition-opacity duration-200 ${
                imageLoaded ? 'opacity-100' : 'opacity-0'
              }`}
              onLoad={() => setImageLoaded(true)}
              onError={() => setImageError(true)}
            />
          ) : (
            <div className="w-full h-48 bg-gradient-to-br from-indigo-100 to-purple-100 flex items-center justify-center">
              <span className="text-indigo-600 font-medium text-lg">{classData.category}</span>
            </div>
          )}
          
          {/* Overlay actions */}
          <div className="absolute top-3 right-3 flex space-x-1">
            <button
              onClick={handleToggleSave}
              className="p-2 bg-white bg-opacity-90 hover:bg-opacity-100 rounded-full shadow-sm transition-all"
              aria-label={classData.isSaved ? 'Remove from saved' : 'Save class'}
            >
              {classData.isSaved ? (
                <BookmarkIconSolid className="w-4 h-4 text-indigo-600" />
              ) : (
                <BookmarkIcon className="w-4 h-4 text-gray-600" />
              )}
            </button>
            <button
              onClick={handleShare}
              className="p-2 bg-white bg-opacity-90 hover:bg-opacity-100 rounded-full shadow-sm transition-all"
              aria-label="Share class"
            >
              <ShareIcon className="w-4 h-4 text-gray-600" />
            </button>
          </div>

          {/* Difficulty badge */}
          <div className="absolute bottom-3 left-3">
            <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${difficultyColors[classData.difficulty]}`}>
              {difficultyLabels[classData.difficulty]}
            </span>
          </div>
        </div>

        {/* Content */}
        <div className="p-4">
          <div className="flex justify-between items-start mb-2">
            <div className="flex-1 min-w-0">
              <h3 className="text-lg font-semibold text-gray-900 group-hover:text-indigo-600 transition-colors line-clamp-2">
                {classData.title}
              </h3>
              {showInstructor && (
                <p className="text-sm text-gray-600 flex items-center mt-1">
                  by {classData.instructor.name}
                  {classData.instructor.verified && (
                    <span className="ml-1 text-indigo-600 text-xs">✓</span>
                  )}
                </p>
              )}
            </div>
            <span className="text-xl font-bold text-gray-900 ml-2">${classData.price}</span>
          </div>

          <p className="text-sm text-gray-600 line-clamp-2 mb-3">
            {classData.description}
          </p>

          {/* Class details */}
          <div className="flex items-center justify-between text-sm text-gray-500 mb-3">
            <div className="flex items-center">
              <StarIcon className="w-4 h-4 text-yellow-400 fill-current mr-1" />
              {classData.rating} ({classData.reviewCount})
            </div>
            <div className="flex items-center">
              <ClockIcon className="w-4 h-4 mr-1" />
              {formatDuration(classData.duration)}
            </div>
            <div className="flex items-center">
              <UserGroupIcon className="w-4 h-4 mr-1" />
              {classData.currentParticipants}/{classData.maxParticipants}
            </div>
          </div>

          {/* Next session info */}
          {classData.nextSession && (
            <div className="flex items-center justify-between text-sm text-gray-600 mb-3 p-2 bg-gray-50 rounded-md">
              <div className="flex items-center">
                <CalendarDaysIcon className="w-4 h-4 mr-1" />
                {formatDate(classData.nextSession.date)} at {classData.nextSession.timeSlot}
              </div>
              <div className="flex items-center">
                <MapPinIcon className="w-4 h-4 mr-1" />
                {classData.nextSession.location}
              </div>
            </div>
          )}

          {/* Tags */}
          {classData.tags && classData.tags.length > 0 && (
            <div className="flex flex-wrap gap-1 mb-3">
              {classData.tags.slice(0, 3).map((tag, index) => (
                <span 
                  key={index}
                  className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-700"
                >
                  {tag}
                </span>
              ))}
              {classData.tags.length > 3 && (
                <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-700">
                  +{classData.tags.length - 3} more
                </span>
              )}
            </div>
          )}

          {/* Availability status */}
          <div className="flex items-center justify-between">
            <span className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${availabilityStatus.bg} ${availabilityStatus.color}`}>
              {availabilityStatus.text}
            </span>
            <div className="text-right">
              {classData.isAvailable ? (
                <span className="text-sm font-medium text-indigo-600">Book Now</span>
              ) : classData.hasWaitlist ? (
                <span className="text-sm font-medium text-orange-600">Join Waitlist</span>
              ) : (
                <span className="text-sm font-medium text-gray-400">Unavailable</span>
              )}
            </div>
          </div>
        </div>
      </div>
    </Link>
  )
}