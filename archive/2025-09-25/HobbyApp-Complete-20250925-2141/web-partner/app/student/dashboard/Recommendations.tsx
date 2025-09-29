/**
 * Recommendations Component
 * Displays personalized class recommendations for students
 */

'use client'

import React, { useState } from 'react'
import Link from 'next/link'
import { 
  SparklesIcon,
  StarIcon,
  MapPinIcon,
  ClockIcon,
  UserGroupIcon,
  BookmarkIcon,
  XMarkIcon,
  ArrowPathIcon,
  AdjustmentsHorizontalIcon
} from '@heroicons/react/24/outline'
import {
  BookmarkIcon as BookmarkIconSolid
} from '@heroicons/react/24/solid'

interface Recommendation {
  id: string
  classData: {
    id: string
    title: string
    description: string
    category: string
    price: number
    duration: number
    difficulty: 'beginner' | 'intermediate' | 'advanced' | 'all_levels'
    instructor: {
      id: string
      name: string
      rating: number
      verified: boolean
    }
    rating: number
    reviewCount: number
    nextSession?: {
      date: string
      timeSlot: string
      location: string
    }
    images: string[]
    tags: string[]
    spotsLeft: number
    isAvailable: boolean
  }
  recommendationType: 'similar_interests' | 'followed_instructors' | 'popular_in_category' | 'location_based' | 'trending' | 'price_match'
  score: number
  reason: string
  isNew?: boolean
}

// Mock recommendation data
const mockRecommendations: Recommendation[] = [
  {
    id: 'rec_1',
    classData: {
      id: 'class_1',
      title: 'Advanced Pottery: Glazing Techniques',
      description: 'Learn professional glazing methods to create stunning ceramic pieces with unique finishes and textures.',
      category: 'Pottery',
      price: 75,
      duration: 180,
      difficulty: 'advanced',
      instructor: {
        id: 'instructor_1',
        name: 'Sarah Chen',
        rating: 4.8,
        verified: true
      },
      rating: 4.9,
      reviewCount: 32,
      nextSession: {
        date: '2024-01-28T13:00:00Z',
        timeSlot: '1:00 PM - 4:00 PM',
        location: 'Downtown Studio'
      },
      images: ['/images/pottery-glazing.jpg'],
      tags: ['glazing', 'advanced', 'ceramics'],
      spotsLeft: 3,
      isAvailable: true
    },
    recommendationType: 'followed_instructors',
    score: 0.95,
    reason: 'New class from Sarah Chen, who you follow',
    isNew: true
  },
  {
    id: 'rec_2',
    classData: {
      id: 'class_2',
      title: 'Acrylic Painting: Abstract Landscapes',
      description: 'Explore abstract techniques while painting dreamy landscape scenes with vibrant acrylics.',
      category: 'Painting',
      price: 45,
      duration: 150,
      difficulty: 'intermediate',
      instructor: {
        id: 'instructor_2',
        name: 'Lisa Park',
        rating: 4.7,
        verified: true
      },
      rating: 4.8,
      reviewCount: 28,
      nextSession: {
        date: '2024-01-26T14:30:00Z',
        timeSlot: '2:30 PM - 5:00 PM',
        location: 'Art Center'
      },
      images: ['/images/acrylic-abstract.jpg'],
      tags: ['abstract', 'landscapes', 'acrylic'],
      spotsLeft: 5,
      isAvailable: true
    },
    recommendationType: 'similar_interests',
    score: 0.87,
    reason: 'Similar to watercolor classes you\'ve taken'
  },
  {
    id: 'rec_3',
    classData: {
      id: 'class_3',
      title: 'Macramé Wall Hanging Workshop',
      description: 'Create beautiful boho-style wall hangings using traditional macramé knots and natural fibers.',
      category: 'Crafts',
      price: 55,
      duration: 120,
      difficulty: 'beginner',
      instructor: {
        id: 'instructor_3',
        name: 'Amy Rodriguez',
        rating: 4.6,
        verified: false
      },
      rating: 4.7,
      reviewCount: 19,
      nextSession: {
        date: '2024-01-27T10:00:00Z',
        timeSlot: '10:00 AM - 12:00 PM',
        location: 'Creative Space'
      },
      images: ['/images/macrame-workshop.jpg'],
      tags: ['macrame', 'wall-hanging', 'fiber-arts'],
      spotsLeft: 1,
      isAvailable: true
    },
    recommendationType: 'trending',
    score: 0.82,
    reason: 'Trending in your area this week'
  },
  {
    id: 'rec_4',
    classData: {
      id: 'class_4',
      title: 'Polymer Clay Miniatures',
      description: 'Craft adorable miniature food and objects using polymer clay sculpting techniques.',
      category: 'Sculpture',
      price: 40,
      duration: 120,
      difficulty: 'beginner',
      instructor: {
        id: 'instructor_4',
        name: 'Kevin Tanaka',
        rating: 4.5,
        verified: true
      },
      rating: 4.6,
      reviewCount: 15,
      nextSession: {
        date: '2024-01-29T15:00:00Z',
        timeSlot: '3:00 PM - 5:00 PM',
        location: 'Maker Studio'
      },
      images: ['/images/polymer-clay.jpg'],
      tags: ['polymer-clay', 'miniatures', 'sculpting'],
      spotsLeft: 8,
      isAvailable: true
    },
    recommendationType: 'price_match',
    score: 0.78,
    reason: 'Matches your preferred price range'
  },
  {
    id: 'rec_5',
    classData: {
      id: 'class_5',
      title: 'Leather Craft: Wallet Making',
      description: 'Learn basic leatherworking skills while crafting your own custom leather wallet.',
      category: 'Leatherwork',
      price: 68,
      duration: 150,
      difficulty: 'intermediate',
      instructor: {
        id: 'instructor_5',
        name: 'Marcus Johnson',
        rating: 4.8,
        verified: true
      },
      rating: 4.9,
      reviewCount: 41,
      nextSession: {
        date: '2024-02-02T13:30:00Z',
        timeSlot: '1:30 PM - 4:00 PM',
        location: 'Craft Workshop'
      },
      images: ['/images/leather-wallet.jpg'],
      tags: ['leather', 'wallet', 'craftsmanship'],
      spotsLeft: 4,
      isAvailable: true
    },
    recommendationType: 'location_based',
    score: 0.75,
    reason: 'Popular near your location'
  }
]

const recommendationTypeConfig = {
  similar_interests: {
    icon: '🎨',
    label: 'Similar Interests',
    description: 'Based on classes you\'ve enjoyed'
  },
  followed_instructors: {
    icon: '👥',
    label: 'Followed Instructors',
    description: 'New classes from instructors you follow'
  },
  popular_in_category: {
    icon: '🔥',
    label: 'Popular in Category',
    description: 'Trending in categories you like'
  },
  location_based: {
    icon: '📍',
    label: 'Near You',
    description: 'Popular classes in your area'
  },
  trending: {
    icon: '⚡',
    label: 'Trending',
    description: 'What\'s hot right now'
  },
  price_match: {
    icon: '💰',
    label: 'Great Value',
    description: 'Matches your budget preferences'
  }
}

const difficultyColors = {
  beginner: 'bg-green-100 text-green-800',
  intermediate: 'bg-yellow-100 text-yellow-800',
  advanced: 'bg-red-100 text-red-800',
  all_levels: 'bg-blue-100 text-blue-800'
}

export default function Recommendations() {
  const [recommendations, setRecommendations] = useState<Recommendation[]>(mockRecommendations)
  const [savedClasses, setSavedClasses] = useState<Set<string>>(new Set())
  const [dismissedRecommendations, setDismissedRecommendations] = useState<Set<string>>(new Set())
  const [selectedType, setSelectedType] = useState<string | null>(null)
  const [isRefreshing, setIsRefreshing] = useState(false)

  const filteredRecommendations = recommendations.filter(rec => {
    if (dismissedRecommendations.has(rec.id)) return false
    if (selectedType && rec.recommendationType !== selectedType) return false
    return true
  })

  const handleToggleSave = (classId: string) => {
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

  const handleDismiss = (recommendationId: string) => {
    setDismissedRecommendations(prev => new Set([...prev, recommendationId]))
  }

  const handleRefresh = async () => {
    setIsRefreshing(true)
    try {
      // API call to refresh recommendations
      await new Promise(resolve => setTimeout(resolve, 1000))
      // In real app, would update recommendations from API
    } finally {
      setIsRefreshing(false)
    }
  }

  const formatDate = (dateString: string) => {
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

  const formatDuration = (minutes: number) => {
    const hours = Math.floor(minutes / 60)
    const mins = minutes % 60
    if (hours === 0) return `${mins}m`
    if (mins === 0) return `${hours}h`
    return `${hours}h ${mins}m`
  }

  const RecommendationCard = ({ recommendation }: { recommendation: Recommendation }) => {
    const { classData, recommendationType, reason, isNew } = recommendation
    const typeConfig = recommendationTypeConfig[recommendationType]
    
    return (
      <div className="bg-white border border-gray-200 rounded-lg overflow-hidden hover:shadow-md transition-all duration-200 relative">
        {isNew && (
          <div className="absolute top-3 left-3 z-10">
            <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
              New!
            </span>
          </div>
        )}
        
        <button
          onClick={() => handleDismiss(recommendation.id)}
          className="absolute top-3 right-3 z-10 p-1 bg-white bg-opacity-80 hover:bg-opacity-100 rounded-full shadow-sm transition-all"
          title="Dismiss this recommendation"
        >
          <XMarkIcon className="w-4 h-4 text-gray-600" />
        </button>

        {/* Image */}
        <div className="aspect-w-16 aspect-h-10 bg-gray-200 relative">
          <div className="w-full h-48 bg-gradient-to-br from-indigo-100 to-purple-100 flex items-center justify-center">
            <span className="text-indigo-600 font-medium text-lg">{classData.category}</span>
          </div>
        </div>

        <div className="p-4">
          {/* Recommendation type badge */}
          <div className="flex items-center justify-between mb-3">
            <div className="flex items-center">
              <span className="text-sm mr-1">{typeConfig.icon}</span>
              <span className="text-xs font-medium text-gray-600">{typeConfig.label}</span>
            </div>
            <button
              onClick={() => handleToggleSave(classData.id)}
              className="p-1 text-gray-400 hover:text-indigo-600 transition-colors"
              title={savedClasses.has(classData.id) ? 'Remove from saved' : 'Save class'}
            >
              {savedClasses.has(classData.id) ? (
                <BookmarkIconSolid className="w-5 h-5 text-indigo-600" />
              ) : (
                <BookmarkIcon className="w-5 h-5" />
              )}
            </button>
          </div>

          {/* Class title and instructor */}
          <div className="mb-3">
            <h3 className="text-lg font-semibold text-gray-900 mb-1 line-clamp-2">
              {classData.title}
            </h3>
            <p className="text-sm text-gray-600 flex items-center">
              by {classData.instructor.name}
              {classData.instructor.verified && (
                <span className="ml-1 text-indigo-600 text-xs">✓</span>
              )}
            </p>
          </div>

          {/* Recommendation reason */}
          <div className="mb-3 p-2 bg-blue-50 rounded-md">
            <p className="text-sm text-blue-800">
              <SparklesIcon className="w-4 h-4 inline mr-1" />
              {reason}
            </p>
          </div>

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
            <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${difficultyColors[classData.difficulty]}`}>
              {classData.difficulty.replace('_', ' ')}
            </span>
          </div>

          {/* Session info */}
          {classData.nextSession && (
            <div className="flex items-center justify-between text-sm text-gray-600 mb-3 p-2 bg-gray-50 rounded-md">
              <div className="flex items-center">
                <ClockIcon className="w-4 h-4 mr-1" />
                {formatDate(classData.nextSession.date)}
              </div>
              <div className="flex items-center">
                <MapPinIcon className="w-4 h-4 mr-1" />
                {classData.nextSession.location}
              </div>
            </div>
          )}

          {/* Availability and price */}
          <div className="flex items-center justify-between">
            <div>
              <p className={`text-sm font-medium ${
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
              <p className="text-xs text-gray-500 mt-1">Match score: {Math.round(recommendation.score * 100)}%</p>
            </div>
            <div className="text-right">
              <p className="text-xl font-bold text-gray-900">${classData.price}</p>
              <Link
                href={`/student/booking/${classData.id}`}
                className="inline-flex items-center px-4 py-2 mt-2 bg-indigo-600 text-white text-sm font-medium rounded-md hover:bg-indigo-700 transition-colors"
              >
                Book Now
              </Link>
            </div>
          </div>
        </div>
      </div>
    )
  }

  const typeFilters = Object.entries(recommendationTypeConfig).map(([key, config]) => ({
    key,
    ...config,
    count: recommendations.filter(r => r.recommendationType === key && !dismissedRecommendations.has(r.id)).length
  }))

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 flex items-center">
            <SparklesIcon className="w-8 h-8 text-indigo-600 mr-2" />
            Recommendations
          </h1>
          <p className="text-gray-600 mt-1">
            Personalized class suggestions based on your interests and activity
          </p>
        </div>
        <div className="flex items-center space-x-3">
          <button
            onClick={handleRefresh}
            disabled={isRefreshing}
            className="inline-flex items-center px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50"
          >
            <ArrowPathIcon className={`w-4 h-4 mr-2 ${isRefreshing ? 'animate-spin' : ''}`} />
            Refresh
          </button>
          <Link
            href="/student/profile/preferences"
            className="inline-flex items-center px-4 py-2 text-sm font-medium text-indigo-600 bg-indigo-100 rounded-md hover:bg-indigo-200"
          >
            <AdjustmentsHorizontalIcon className="w-4 h-4 mr-2" />
            Preferences
          </Link>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-white border border-gray-200 rounded-lg p-4">
          <div className="text-2xl font-bold text-gray-900">{filteredRecommendations.length}</div>
          <div className="text-sm text-gray-500">New Recommendations</div>
        </div>
        <div className="bg-white border border-gray-200 rounded-lg p-4">
          <div className="text-2xl font-bold text-blue-600">
            {recommendations.filter(r => r.isNew && !dismissedRecommendations.has(r.id)).length}
          </div>
          <div className="text-sm text-gray-500">Fresh This Week</div>
        </div>
        <div className="bg-white border border-gray-200 rounded-lg p-4">
          <div className="text-2xl font-bold text-green-600">
            {Math.round(recommendations.reduce((sum, r) => sum + r.score, 0) / recommendations.length * 100)}%
          </div>
          <div className="text-sm text-gray-500">Avg Match Score</div>
        </div>
        <div className="bg-white border border-gray-200 rounded-lg p-4">
          <div className="text-2xl font-bold text-purple-600">{savedClasses.size}</div>
          <div className="text-sm text-gray-500">Classes Saved</div>
        </div>
      </div>

      {/* Filter Pills */}
      <div className="flex flex-wrap gap-2">
        <button
          onClick={() => setSelectedType(null)}
          className={`inline-flex items-center px-4 py-2 rounded-full text-sm font-medium transition-colors ${
            selectedType === null
              ? 'bg-indigo-100 text-indigo-700 border border-indigo-200'
              : 'bg-white text-gray-700 border border-gray-200 hover:bg-gray-50'
          }`}
        >
          All Recommendations ({filteredRecommendations.length})
        </button>
        {typeFilters.map(filter => (
          <button
            key={filter.key}
            onClick={() => setSelectedType(filter.key)}
            disabled={filter.count === 0}
            className={`inline-flex items-center px-4 py-2 rounded-full text-sm font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed ${
              selectedType === filter.key
                ? 'bg-indigo-100 text-indigo-700 border border-indigo-200'
                : 'bg-white text-gray-700 border border-gray-200 hover:bg-gray-50'
            }`}
          >
            <span className="mr-1">{filter.icon}</span>
            {filter.label} ({filter.count})
          </button>
        ))}
      </div>

      {/* Recommendations Grid */}
      {filteredRecommendations.length === 0 ? (
        <div className="text-center py-12 bg-white border border-gray-200 rounded-lg">
          <SparklesIcon className="w-12 h-12 text-gray-400 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">
            {dismissedRecommendations.size > 0 ? 'All caught up!' : 'No recommendations yet'}
          </h3>
          <p className="text-gray-600 mb-4">
            {dismissedRecommendations.size > 0 
              ? 'You\'ve seen all your recommendations. Check back later for new ones!'
              : 'Take a few classes to get personalized recommendations.'
            }
          </p>
          <div className="flex justify-center space-x-3">
            <Link
              href="/student/discovery"
              className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
            >
              Explore Classes
            </Link>
            {dismissedRecommendations.size > 0 && (
              <button
                onClick={() => setDismissedRecommendations(new Set())}
                className="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
              >
                Show Dismissed
              </button>
            )}
          </div>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredRecommendations.map((recommendation) => (
            <RecommendationCard key={recommendation.id} recommendation={recommendation} />
          ))}
        </div>
      )}
    </div>
  )
}