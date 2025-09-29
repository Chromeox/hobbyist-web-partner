/**
 * Class Discovery Component
 * Main component for browsing and searching classes
 */

'use client'

import React, { useState, useEffect, useMemo } from 'react'
import { 
  MagnifyingGlassIcon,
  AdjustmentsHorizontalIcon,
  Squares2X2Icon,
  ListBulletIcon,
  ChevronDownIcon,
  ArrowsUpDownIcon
} from '@heroicons/react/24/outline'
import SearchFilters, { FilterState } from './SearchFilters'
import ClassCard, { ClassData } from './ClassCard'

// Mock data for development
const mockClasses: ClassData[] = [
  {
    id: '1',
    title: 'Beginner Pottery Workshop - Hand Building Techniques',
    description: 'Learn the fundamentals of pottery through hand-building techniques. Perfect for complete beginners who want to get their hands dirty and create beautiful ceramic pieces.',
    instructor: {
      id: 'instructor-1',
      name: 'Sarah Chen',
      rating: 4.8,
      reviewCount: 124,
      verified: true,
      avatar: '/avatars/sarah.jpg'
    },
    category: 'Pottery',
    price: 45,
    duration: 120,
    difficulty: 'beginner',
    maxParticipants: 8,
    currentParticipants: 6,
    rating: 4.8,
    reviewCount: 24,
    nextSession: {
      date: '2024-01-15T14:00:00Z',
      timeSlot: '2:00 PM - 4:00 PM',
      location: 'Downtown Studio'
    },
    images: ['/images/pottery-class.jpg'],
    tags: ['hand-building', 'beginner-friendly', 'ceramics'],
    isAvailable: true,
    hasWaitlist: true,
    isFavorited: false,
    isSaved: false
  },
  {
    id: '2',
    title: 'Watercolor Painting: Landscapes and Nature',
    description: 'Explore the beauty of watercolor painting while creating stunning landscape and nature scenes. Learn color mixing, wet-on-wet techniques, and composition.',
    instructor: {
      id: 'instructor-2',
      name: 'Michael Torres',
      rating: 4.9,
      reviewCount: 89,
      verified: true,
      avatar: '/avatars/michael.jpg'
    },
    category: 'Painting',
    price: 35,
    duration: 150,
    difficulty: 'intermediate',
    maxParticipants: 12,
    currentParticipants: 10,
    rating: 4.9,
    reviewCount: 18,
    nextSession: {
      date: '2024-01-16T10:00:00Z',
      timeSlot: '10:00 AM - 12:30 PM',
      location: 'Art Center'
    },
    images: ['/images/painting-class.jpg'],
    tags: ['watercolor', 'landscapes', 'color-theory'],
    isAvailable: true,
    hasWaitlist: false,
    isFavorited: true,
    isSaved: false
  },
  {
    id: '3',
    title: 'Advanced Jewelry Making: Silver Wire Wrapping',
    description: 'Master the art of silver wire wrapping to create elegant jewelry pieces. This advanced class covers complex wrapping techniques and finishing methods.',
    instructor: {
      id: 'instructor-3',
      name: 'Emma Rodriguez',
      rating: 4.7,
      reviewCount: 67,
      verified: true,
      avatar: '/avatars/emma.jpg'
    },
    category: 'Jewelry Making',
    price: 85,
    duration: 180,
    difficulty: 'advanced',
    maxParticipants: 6,
    currentParticipants: 6,
    rating: 4.7,
    reviewCount: 31,
    nextSession: {
      date: '2024-01-18T13:00:00Z',
      timeSlot: '1:00 PM - 4:00 PM',
      location: 'Creative Space'
    },
    images: ['/images/jewelry-class.jpg'],
    tags: ['silver', 'wire-wrapping', 'advanced'],
    isAvailable: false,
    hasWaitlist: true,
    isFavorited: false,
    isSaved: true
  },
  {
    id: '4',
    title: 'Modern Calligraphy Workshop for Beginners',
    description: 'Discover the art of modern calligraphy and create beautiful lettered pieces. Learn brush pen techniques and develop your own unique style.',
    instructor: {
      id: 'instructor-4',
      name: 'David Kim',
      rating: 4.6,
      reviewCount: 43,
      verified: false,
      avatar: '/avatars/david.jpg'
    },
    category: 'Calligraphy',
    price: 40,
    duration: 120,
    difficulty: 'beginner',
    maxParticipants: 15,
    currentParticipants: 12,
    rating: 4.6,
    reviewCount: 22,
    nextSession: {
      date: '2024-01-19T15:30:00Z',
      timeSlot: '3:30 PM - 5:30 PM',
      location: 'East Side Studio'
    },
    images: ['/images/calligraphy-class.jpg'],
    tags: ['modern-calligraphy', 'brush-pen', 'lettering'],
    isAvailable: true,
    hasWaitlist: false,
    isFavorited: false,
    isSaved: false
  }
]

type SortOption = 'relevance' | 'price_low' | 'price_high' | 'rating' | 'date' | 'popularity'

const sortOptions = [
  { value: 'relevance', label: 'Most Relevant' },
  { value: 'price_low', label: 'Price: Low to High' },
  { value: 'price_high', label: 'Price: High to Low' },
  { value: 'rating', label: 'Highest Rated' },
  { value: 'date', label: 'Upcoming Classes' },
  { value: 'popularity', label: 'Most Popular' }
]

interface ClassDiscoveryProps {
  initialFilters?: Partial<FilterState>
  initialSearchTerm?: string
}

export default function ClassDiscovery({ 
  initialFilters = {}, 
  initialSearchTerm = '' 
}: ClassDiscoveryProps) {
  const [searchTerm, setSearchTerm] = useState(initialSearchTerm)
  const [filters, setFilters] = useState<FilterState>({
    categories: [],
    priceRange: [0, 500],
    difficulty: [],
    location: '',
    date: '',
    timeOfDay: [],
    duration: [],
    maxParticipants: null,
    rating: null,
    availability: 'all',
    ...initialFilters
  })
  const [sortBy, setSortBy] = useState<SortOption>('relevance')
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid')
  const [showFilters, setShowFilters] = useState(false)
  const [savedClasses, setSavedClasses] = useState<Set<string>>(new Set(['3']))
  const [favoritedInstructors, setFavoritedInstructors] = useState<Set<string>>(new Set(['instructor-2']))
  const [isLoading, setIsLoading] = useState(false)

  // Filter and sort classes
  const filteredAndSortedClasses = useMemo(() => {
    let filtered = mockClasses.filter(classData => {
      // Search term filter
      if (searchTerm) {
        const searchLower = searchTerm.toLowerCase()
        const matchesSearch = (
          classData.title.toLowerCase().includes(searchLower) ||
          classData.description.toLowerCase().includes(searchLower) ||
          classData.instructor.name.toLowerCase().includes(searchLower) ||
          classData.category.toLowerCase().includes(searchLower) ||
          classData.tags.some(tag => tag.toLowerCase().includes(searchLower))
        )
        if (!matchesSearch) return false
      }

      // Category filter
      if (filters.categories.length > 0) {
        if (!filters.categories.includes(classData.category)) return false
      }

      // Price range filter
      if (classData.price < filters.priceRange[0] || classData.price > filters.priceRange[1]) {
        return false
      }

      // Difficulty filter
      if (filters.difficulty.length > 0) {
        if (!filters.difficulty.includes(classData.difficulty)) return false
      }

      // Location filter (simple text match)
      if (filters.location) {
        const locationLower = filters.location.toLowerCase()
        if (!classData.nextSession?.location.toLowerCase().includes(locationLower)) {
          return false
        }
      }

      // Rating filter
      if (filters.rating && classData.rating < filters.rating) {
        return false
      }

      // Availability filter
      if (filters.availability === 'available' && !classData.isAvailable) {
        return false
      }
      if (filters.availability === 'waitlist' && !classData.hasWaitlist) {
        return false
      }

      return true
    })

    // Sort classes
    filtered.sort((a, b) => {
      switch (sortBy) {
        case 'price_low':
          return a.price - b.price
        case 'price_high':
          return b.price - a.price
        case 'rating':
          return b.rating - a.rating
        case 'date':
          if (!a.nextSession || !b.nextSession) return 0
          return new Date(a.nextSession.date).getTime() - new Date(b.nextSession.date).getTime()
        case 'popularity':
          return b.reviewCount - a.reviewCount
        case 'relevance':
        default:
          return 0
      }
    })

    return filtered
  }, [searchTerm, filters, sortBy])

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

  const handleToggleFavoriteInstructor = (instructorId: string) => {
    setFavoritedInstructors(prev => {
      const newFavorited = new Set(prev)
      if (newFavorited.has(instructorId)) {
        newFavorited.delete(instructorId)
      } else {
        newFavorited.add(instructorId)
      }
      return newFavorited
    })
  }

  const handleShare = (classId: string) => {
    const classData = mockClasses.find(c => c.id === classId)
    if (classData && navigator.share) {
      navigator.share({
        title: classData.title,
        text: `Check out this ${classData.category.toLowerCase()} class by ${classData.instructor.name}!`,
        url: `${window.location.origin}/student/booking/${classId}`
      })
    } else {
      // Fallback: copy to clipboard
      const url = `${window.location.origin}/student/booking/${classId}`
      navigator.clipboard.writeText(url)
      // You could show a toast notification here
    }
  }

  // Update class data with saved/favorited state
  const classesWithState = filteredAndSortedClasses.map(classData => ({
    ...classData,
    isSaved: savedClasses.has(classData.id),
    isFavorited: favoritedInstructors.has(classData.instructor.id)
  }))

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="text-center py-8 bg-white rounded-lg shadow-sm border border-gray-200">
        <h1 className="text-3xl font-bold text-gray-900 mb-4">Discover Amazing Classes</h1>
        <p className="text-lg text-gray-600 max-w-2xl mx-auto">
          Find your next creative adventure with talented instructors in your area
        </p>
      </div>

      {/* Search and Filters */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div className="space-y-4">
          {/* Search bar */}
          <div className="relative">
            <MagnifyingGlassIcon className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
            <input
              type="text"
              placeholder="Search classes, instructors, or categories..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm"
            />
          </div>

          {/* Controls */}
          <div className="flex flex-col sm:flex-row gap-4 items-center justify-between">
            <div className="flex items-center space-x-2">
              <SearchFilters
                filters={filters}
                onFiltersChange={setFilters}
                isOpen={showFilters}
                onToggle={() => setShowFilters(!showFilters)}
              />
              
              <div className="relative">
                <select
                  value={sortBy}
                  onChange={(e) => setSortBy(e.target.value as SortOption)}
                  className="appearance-none bg-white border border-gray-300 rounded-md px-4 py-2 pr-8 text-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                >
                  {sortOptions.map((option) => (
                    <option key={option.value} value={option.value}>
                      {option.label}
                    </option>
                  ))}
                </select>
                <ArrowsUpDownIcon className="absolute right-2 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400 pointer-events-none" />
              </div>
            </div>

            <div className="flex items-center space-x-2">
              <span className="text-sm text-gray-600">
                {classesWithState.length} class{classesWithState.length === 1 ? '' : 'es'} found
              </span>
              
              <div className="flex items-center bg-gray-100 rounded-lg p-1">
                <button
                  onClick={() => setViewMode('grid')}
                  className={`p-2 rounded-md transition-colors ${
                    viewMode === 'grid'
                      ? 'bg-white text-indigo-600 shadow-sm'
                      : 'text-gray-600 hover:text-gray-900'
                  }`}
                  aria-label="Grid view"
                >
                  <Squares2X2Icon className="h-4 w-4" />
                </button>
                <button
                  onClick={() => setViewMode('list')}
                  className={`p-2 rounded-md transition-colors ${
                    viewMode === 'list'
                      ? 'bg-white text-indigo-600 shadow-sm'
                      : 'text-gray-600 hover:text-gray-900'
                  }`}
                  aria-label="List view"
                >
                  <ListBulletIcon className="h-4 w-4" />
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* Expanded Filters */}
        {showFilters && (
          <div className="mt-6">
            <SearchFilters
              filters={filters}
              onFiltersChange={setFilters}
              isOpen={true}
              onToggle={() => setShowFilters(false)}
              className="w-full"
            />
          </div>
        )}
      </div>

      {/* Results */}
      <div className="space-y-6">
        {isLoading ? (
          <div className="text-center py-12">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600 mx-auto"></div>
            <p className="mt-4 text-gray-600">Loading classes...</p>
          </div>
        ) : classesWithState.length === 0 ? (
          <div className="text-center py-12 bg-white rounded-lg shadow-sm border border-gray-200">
            <MagnifyingGlassIcon className="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-gray-900 mb-2">No classes found</h3>
            <p className="text-gray-600 mb-4">
              Try adjusting your search terms or filters to find more classes.
            </p>
            <button
              onClick={() => {
                setSearchTerm('')
                setFilters({
                  categories: [],
                  priceRange: [0, 500],
                  difficulty: [],
                  location: '',
                  date: '',
                  timeOfDay: [],
                  duration: [],
                  maxParticipants: null,
                  rating: null,
                  availability: 'all'
                })
              }}
              className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
            >
              Clear all filters
            </button>
          </div>
        ) : (
          <div className={
            viewMode === 'grid' 
              ? 'grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6'
              : 'space-y-4'
          }>
            {classesWithState.map((classData) => (
              <ClassCard
                key={classData.id}
                classData={classData}
                variant={viewMode}
                onToggleSave={handleToggleSave}
                onShare={handleShare}
              />
            ))}
          </div>
        )}
      </div>

      {/* Load more button */}
      {classesWithState.length > 0 && !isLoading && (
        <div className="text-center pt-8">
          <button className="inline-flex items-center px-6 py-3 border border-gray-300 shadow-sm text-base font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
            Load more classes
          </button>
        </div>
      )}
    </div>
  )
}