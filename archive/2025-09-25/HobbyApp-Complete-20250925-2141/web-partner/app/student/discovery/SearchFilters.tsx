/**
 * Advanced Search Filters Component
 * Provides comprehensive filtering options for class discovery
 */

'use client'

import React, { useState } from 'react'
import { 
  FunnelIcon, 
  XMarkIcon, 
  ChevronDownIcon, 
  ChevronUpIcon,
  MapPinIcon,
  CalendarDaysIcon,
  CurrencyDollarIcon,
  AcademicCapIcon,
  ClockIcon,
  UserGroupIcon
} from '@heroicons/react/24/outline'

export interface FilterState {
  categories: string[]
  priceRange: [number, number]
  difficulty: string[]
  location: string
  date: string
  timeOfDay: string[]
  duration: string[]
  maxParticipants: number | null
  rating: number | null
  availability: 'all' | 'available' | 'waitlist'
}

interface SearchFiltersProps {
  filters: FilterState
  onFiltersChange: (filters: FilterState) => void
  isOpen: boolean
  onToggle: () => void
  className?: string
}

const categories = [
  'Pottery', 'Painting', 'Drawing', 'Jewelry Making', 'Woodworking',
  'Photography', 'Cooking', 'Baking', 'Knitting', 'Sewing', 'Calligraphy',
  'Printmaking', 'Sculpture', 'Glassblowing', 'Weaving', 'Embroidery'
]

const difficultyLevels = [
  { value: 'beginner', label: 'Beginner' },
  { value: 'intermediate', label: 'Intermediate' },
  { value: 'advanced', label: 'Advanced' },
  { value: 'all_levels', label: 'All Levels' }
]

const timeOptions = [
  { value: 'morning', label: 'Morning (6AM-12PM)' },
  { value: 'afternoon', label: 'Afternoon (12PM-6PM)' },
  { value: 'evening', label: 'Evening (6PM-10PM)' },
  { value: 'weekend', label: 'Weekend' }
]

const durationOptions = [
  { value: '0-60', label: 'Under 1 hour' },
  { value: '60-120', label: '1-2 hours' },
  { value: '120-180', label: '2-3 hours' },
  { value: '180-240', label: '3-4 hours' },
  { value: '240+', label: '4+ hours' }
]

export default function SearchFilters({ 
  filters, 
  onFiltersChange, 
  isOpen, 
  onToggle,
  className = '' 
}: SearchFiltersProps) {
  const [expandedSections, setExpandedSections] = useState<Set<string>>(
    new Set(['categories', 'price', 'difficulty'])
  )

  const toggleSection = (section: string) => {
    setExpandedSections(prev => {
      const newSet = new Set(prev)
      if (newSet.has(section)) {
        newSet.delete(section)
      } else {
        newSet.add(section)
      }
      return newSet
    })
  }

  const updateFilter = <K extends keyof FilterState>(
    key: K, 
    value: FilterState[K]
  ) => {
    onFiltersChange({ ...filters, [key]: value })
  }

  const toggleArrayFilter = <K extends keyof FilterState>(
    key: K,
    value: string
  ) => {
    const currentArray = filters[key] as string[]
    const newArray = currentArray.includes(value)
      ? currentArray.filter(item => item !== value)
      : [...currentArray, value]
    updateFilter(key, newArray as FilterState[K])
  }

  const clearAllFilters = () => {
    onFiltersChange({
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
  }

  const getActiveFilterCount = () => {
    let count = 0
    if (filters.categories.length > 0) count++
    if (filters.priceRange[0] > 0 || filters.priceRange[1] < 500) count++
    if (filters.difficulty.length > 0) count++
    if (filters.location) count++
    if (filters.date) count++
    if (filters.timeOfDay.length > 0) count++
    if (filters.duration.length > 0) count++
    if (filters.maxParticipants) count++
    if (filters.rating) count++
    if (filters.availability !== 'all') count++
    return count
  }

  const FilterSection = ({ 
    title, 
    section, 
    icon: Icon, 
    children 
  }: { 
    title: string
    section: string
    icon: React.ElementType
    children: React.ReactNode 
  }) => {
    const isExpanded = expandedSections.has(section)
    
    return (
      <div className="border-b border-gray-200 pb-4">
        <button
          onClick={() => toggleSection(section)}
          className="flex items-center justify-between w-full py-2 text-left"
        >
          <div className="flex items-center">
            <Icon className="w-5 h-5 text-gray-400 mr-2" />
            <span className="font-medium text-gray-900">{title}</span>
          </div>
          {isExpanded ? (
            <ChevronUpIcon className="w-5 h-5 text-gray-400" />
          ) : (
            <ChevronDownIcon className="w-5 h-5 text-gray-400" />
          )}
        </button>
        {isExpanded && (
          <div className="mt-3 space-y-3">
            {children}
          </div>
        )}
      </div>
    )
  }

  const CheckboxList = ({ 
    options, 
    selected, 
    onChange 
  }: { 
    options: string[] | { value: string; label: string }[]
    selected: string[]
    onChange: (value: string) => void 
  }) => (
    <div className="space-y-2 max-h-48 overflow-y-auto">
      {options.map((option) => {
        const value = typeof option === 'string' ? option : option.value
        const label = typeof option === 'string' ? option : option.label
        return (
          <label key={value} className="flex items-center">
            <input
              type="checkbox"
              checked={selected.includes(value)}
              onChange={() => onChange(value)}
              className="rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
            />
            <span className="ml-2 text-sm text-gray-700">{label}</span>
          </label>
        )
      })}
    </div>
  )

  if (!isOpen) {
    return (
      <button
        onClick={onToggle}
        className={`inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm bg-white text-sm font-medium text-gray-700 hover:bg-gray-50 ${className}`}
      >
        <FunnelIcon className="w-4 h-4 mr-2" />
        Filters
        {getActiveFilterCount() > 0 && (
          <span className="ml-2 inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-indigo-100 text-indigo-800">
            {getActiveFilterCount()}
          </span>
        )}
      </button>
    )
  }

  return (
    <div className={`bg-white border border-gray-200 rounded-lg shadow-lg ${className}`}>
      <div className="p-4 border-b border-gray-200">
        <div className="flex items-center justify-between">
          <div className="flex items-center">
            <FunnelIcon className="w-5 h-5 text-gray-400 mr-2" />
            <h3 className="text-lg font-medium text-gray-900">Filters</h3>
            {getActiveFilterCount() > 0 && (
              <span className="ml-2 inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-indigo-100 text-indigo-800">
                {getActiveFilterCount()} active
              </span>
            )}
          </div>
          <div className="flex items-center space-x-2">
            <button
              onClick={clearAllFilters}
              className="text-sm text-indigo-600 hover:text-indigo-700 font-medium"
            >
              Clear all
            </button>
            <button
              onClick={onToggle}
              className="p-1 text-gray-400 hover:text-gray-500"
              aria-label="Close filters"
            >
              <XMarkIcon className="w-5 h-5" />
            </button>
          </div>
        </div>
      </div>

      <div className="p-4 space-y-6 max-h-96 overflow-y-auto">
        {/* Categories */}
        <FilterSection title="Categories" section="categories" icon={AcademicCapIcon}>
          <CheckboxList
            options={categories}
            selected={filters.categories}
            onChange={(value) => toggleArrayFilter('categories', value)}
          />
        </FilterSection>

        {/* Price Range */}
        <FilterSection title="Price Range" section="price" icon={CurrencyDollarIcon}>
          <div className="space-y-3">
            <div className="flex items-center space-x-2">
              <span className="text-sm text-gray-600">$</span>
              <input
                type="number"
                placeholder="Min"
                value={filters.priceRange[0]}
                onChange={(e) => updateFilter('priceRange', [
                  parseInt(e.target.value) || 0,
                  filters.priceRange[1]
                ])}
                className="w-20 px-2 py-1 border border-gray-300 rounded text-sm"
              />
              <span className="text-sm text-gray-400">to</span>
              <span className="text-sm text-gray-600">$</span>
              <input
                type="number"
                placeholder="Max"
                value={filters.priceRange[1]}
                onChange={(e) => updateFilter('priceRange', [
                  filters.priceRange[0],
                  parseInt(e.target.value) || 500
                ])}
                className="w-20 px-2 py-1 border border-gray-300 rounded text-sm"
              />
            </div>
            <input
              type="range"
              min="0"
              max="500"
              step="5"
              value={filters.priceRange[1]}
              onChange={(e) => updateFilter('priceRange', [
                filters.priceRange[0],
                parseInt(e.target.value)
              ])}
              className="w-full"
            />
          </div>
        </FilterSection>

        {/* Difficulty Level */}
        <FilterSection title="Difficulty Level" section="difficulty" icon={AcademicCapIcon}>
          <CheckboxList
            options={difficultyLevels}
            selected={filters.difficulty}
            onChange={(value) => toggleArrayFilter('difficulty', value)}
          />
        </FilterSection>

        {/* Location */}
        <FilterSection title="Location" section="location" icon={MapPinIcon}>
          <input
            type="text"
            placeholder="City, neighborhood, or zip code"
            value={filters.location}
            onChange={(e) => updateFilter('location', e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:ring-indigo-500 focus:border-indigo-500"
          />
        </FilterSection>

        {/* Date */}
        <FilterSection title="Date" section="date" icon={CalendarDaysIcon}>
          <input
            type="date"
            value={filters.date}
            onChange={(e) => updateFilter('date', e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:ring-indigo-500 focus:border-indigo-500"
          />
        </FilterSection>

        {/* Time of Day */}
        <FilterSection title="Time of Day" section="time" icon={ClockIcon}>
          <CheckboxList
            options={timeOptions}
            selected={filters.timeOfDay}
            onChange={(value) => toggleArrayFilter('timeOfDay', value)}
          />
        </FilterSection>

        {/* Duration */}
        <FilterSection title="Duration" section="duration" icon={ClockIcon}>
          <CheckboxList
            options={durationOptions}
            selected={filters.duration}
            onChange={(value) => toggleArrayFilter('duration', value)}
          />
        </FilterSection>

        {/* Class Size */}
        <FilterSection title="Class Size" section="size" icon={UserGroupIcon}>
          <div className="space-y-2">
            <label className="flex items-center">
              <input
                type="radio"
                name="classSize"
                checked={filters.maxParticipants === null}
                onChange={() => updateFilter('maxParticipants', null)}
                className="text-indigo-600 focus:ring-indigo-500"
              />
              <span className="ml-2 text-sm text-gray-700">Any size</span>
            </label>
            <label className="flex items-center">
              <input
                type="radio"
                name="classSize"
                checked={filters.maxParticipants === 5}
                onChange={() => updateFilter('maxParticipants', 5)}
                className="text-indigo-600 focus:ring-indigo-500"
              />
              <span className="ml-2 text-sm text-gray-700">Small (1-5 people)</span>
            </label>
            <label className="flex items-center">
              <input
                type="radio"
                name="classSize"
                checked={filters.maxParticipants === 15}
                onChange={() => updateFilter('maxParticipants', 15)}
                className="text-indigo-600 focus:ring-indigo-500"
              />
              <span className="ml-2 text-sm text-gray-700">Medium (6-15 people)</span>
            </label>
            <label className="flex items-center">
              <input
                type="radio"
                name="classSize"
                checked={filters.maxParticipants === 50}
                onChange={() => updateFilter('maxParticipants', 50)}
                className="text-indigo-600 focus:ring-indigo-500"
              />
              <span className="ml-2 text-sm text-gray-700">Large (15+ people)</span>
            </label>
          </div>
        </FilterSection>

        {/* Rating */}
        <FilterSection title="Minimum Rating" section="rating" icon={AcademicCapIcon}>
          <div className="space-y-2">
            {[4.5, 4.0, 3.5, 3.0].map((rating) => (
              <label key={rating} className="flex items-center">
                <input
                  type="radio"
                  name="rating"
                  checked={filters.rating === rating}
                  onChange={() => updateFilter('rating', rating)}
                  className="text-indigo-600 focus:ring-indigo-500"
                />
                <span className="ml-2 text-sm text-gray-700">
                  {rating}+ stars
                </span>
              </label>
            ))}
          </div>
        </FilterSection>

        {/* Availability */}
        <FilterSection title="Availability" section="availability" icon={UserGroupIcon}>
          <div className="space-y-2">
            <label className="flex items-center">
              <input
                type="radio"
                name="availability"
                checked={filters.availability === 'all'}
                onChange={() => updateFilter('availability', 'all')}
                className="text-indigo-600 focus:ring-indigo-500"
              />
              <span className="ml-2 text-sm text-gray-700">All classes</span>
            </label>
            <label className="flex items-center">
              <input
                type="radio"
                name="availability"
                checked={filters.availability === 'available'}
                onChange={() => updateFilter('availability', 'available')}
                className="text-indigo-600 focus:ring-indigo-500"
              />
              <span className="ml-2 text-sm text-gray-700">Available to book</span>
            </label>
            <label className="flex items-center">
              <input
                type="radio"
                name="availability"
                checked={filters.availability === 'waitlist'}
                onChange={() => updateFilter('availability', 'waitlist')}
                className="text-indigo-600 focus:ring-indigo-500"
              />
              <span className="ml-2 text-sm text-gray-700">Waitlist available</span>
            </label>
          </div>
        </FilterSection>
      </div>
    </div>
  )
}