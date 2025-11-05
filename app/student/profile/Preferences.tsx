/**
 * Student Preferences Component
 * Manages student's learning preferences and recommendation settings
 */

'use client'

import React, { useState } from 'react'
import { 
  AdjustmentsHorizontalIcon,
  MapPinIcon,
  ClockIcon,
  CurrencyDollarIcon,
  AcademicCapIcon,
  CalendarDaysIcon,
  BellIcon,
  CheckIcon,
  XMarkIcon,
  ExclamationTriangleIcon,
  SparklesIcon
} from '@heroicons/react/24/outline'

interface StudentPreferences {
  categories: string[]
  difficultyLevels: string[]
  priceRange: {
    min: number
    max: number
  }
  timePreferences: string[]
  locationPreference: {
    type: 'anywhere' | 'specific' | 'radius'
    location?: string
    radius?: number // in km
  }
  classSize: 'any' | 'small' | 'medium' | 'large'
  duration: string[]
  notifications: {
    newClasses: boolean
    priceDrops: boolean
    followedInstructors: boolean
    recommendations: boolean
    reminders: boolean
  }
  autoBookWaitlist: boolean
  maxWaitlistPrice: number
}

// Mock preferences data
const mockPreferences: StudentPreferences = {
  categories: ['Pottery', 'Painting', 'Jewelry Making'],
  difficultyLevels: ['beginner', 'intermediate'],
  priceRange: {
    min: 25,
    max: 100
  },
  timePreferences: ['evening', 'weekend'],
  locationPreference: {
    type: 'radius',
    location: 'Vancouver, BC',
    radius: 25
  },
  classSize: 'small',
  duration: ['60-120', '120-180'],
  notifications: {
    newClasses: true,
    priceDrops: false,
    followedInstructors: true,
    recommendations: true,
    reminders: true
  },
  autoBookWaitlist: false,
  maxWaitlistPrice: 75
}

const categories = [
  'Pottery', 'Painting', 'Drawing', 'Jewelry Making', 'Woodworking',
  'Photography', 'Cooking', 'Baking', 'Knitting', 'Sewing', 'Calligraphy',
  'Printmaking', 'Sculpture', 'Glassblowing', 'Weaving', 'Embroidery',
  'Leatherwork', 'Ceramics', 'Macramé', 'Candle Making'
]

const difficultyOptions = [
  { value: 'beginner', label: 'Beginner' },
  { value: 'intermediate', label: 'Intermediate' }, 
  { value: 'advanced', label: 'Advanced' },
  { value: 'all_levels', label: 'All Levels' }
]

const timeOptions = [
  { value: 'morning', label: 'Morning (6AM-12PM)' },
  { value: 'afternoon', label: 'Afternoon (12PM-6PM)' },
  { value: 'evening', label: 'Evening (6PM-10PM)' },
  { value: 'weekend', label: 'Weekends' },
  { value: 'weekday', label: 'Weekdays' }
]

const durationOptions = [
  { value: '0-60', label: 'Under 1 hour' },
  { value: '60-120', label: '1-2 hours' },
  { value: '120-180', label: '2-3 hours' },
  { value: '180-240', label: '3-4 hours' },
  { value: '240+', label: '4+ hours' }
]

const classSizeOptions = [
  { value: 'any', label: 'Any size class' },
  { value: 'small', label: 'Small (1-8 people)' },
  { value: 'medium', label: 'Medium (8-15 people)' },
  { value: 'large', label: 'Large (15+ people)' }
]

export default function Preferences() {
  const [preferences, setPreferences] = useState<StudentPreferences>(mockPreferences)
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<string | null>(null)

  const handleSave = async () => {
    setIsLoading(true)
    setError(null)

    try {
      // Validate preferences
      if (preferences.categories.length === 0) {
        throw new Error('Please select at least one category')
      }

      if (preferences.priceRange.min >= preferences.priceRange.max) {
        throw new Error('Maximum price must be higher than minimum price')
      }

      // API call would go here
      await new Promise(resolve => setTimeout(resolve, 1000))
      
      setSuccess('Preferences saved successfully!')
      setTimeout(() => setSuccess(null), 3000)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save preferences')
    } finally {
      setIsLoading(false)
    }
  }

  const handleCategoryToggle = (category: string) => {
    setPreferences(prev => ({
      ...prev,
      categories: prev.categories.includes(category)
        ? prev.categories.filter(c => c !== category)
        : [...prev.categories, category]
    }))
  }

  const handleArrayToggle = <K extends keyof StudentPreferences>(
    key: K,
    value: string
  ) => {
    const currentArray = preferences[key] as string[]
    setPreferences(prev => ({
      ...prev,
      [key]: currentArray.includes(value)
        ? currentArray.filter(item => item !== value)
        : [...currentArray, value]
    }))
  }

  const handleNotificationToggle = (key: keyof StudentPreferences['notifications']) => {
    setPreferences(prev => ({
      ...prev,
      notifications: {
        ...prev.notifications,
        [key]: !prev.notifications[key]
      }
    }))
  }

  const PreferenceSection = ({ 
    title, 
    icon: Icon, 
    children 
  }: { 
    title: string
    icon: React.ElementType
    children: React.ReactNode 
  }) => (
    <div className="bg-white border border-gray-200 rounded-lg p-6">
      <div className="flex items-center mb-4">
        <Icon className="w-5 h-5 text-indigo-600 mr-2" />
        <h3 className="text-lg font-semibold text-gray-900">{title}</h3>
      </div>
      {children}
    </div>
  )

  const CheckboxList = ({ 
    options, 
    selected, 
    onChange,
    columns = 2
  }: { 
    options: string[] | { value: string; label: string }[]
    selected: string[]
    onChange: (value: string) => void
    columns?: number
  }) => (
    <div className={`grid grid-cols-1 md:grid-cols-${columns} gap-3`}>
      {options.map((option) => {
        const value = typeof option === 'string' ? option : option.value
        const label = typeof option === 'string' ? option : option.label
        return (
          <label key={value} className="flex items-center cursor-pointer">
            <input
              type="checkbox"
              checked={selected.includes(value)}
              onChange={() => onChange(value)}
              className="rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
            />
            <span className="ml-3 text-sm text-gray-700">{label}</span>
          </label>
        )
      })}
    </div>
  )

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 flex items-center">
            <AdjustmentsHorizontalIcon className="w-8 h-8 text-indigo-600 mr-2" />
            Learning Preferences
          </h1>
          <p className="text-gray-600 mt-1">
            Customize your class recommendations and discovery experience
          </p>
        </div>
        <button
          onClick={handleSave}
          disabled={isLoading}
          className="inline-flex items-center px-6 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {isLoading ? (
            <>
              <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
              Saving...
            </>
          ) : (
            <>
              <CheckIcon className="w-4 h-4 mr-2" />
              Save Preferences
            </>
          )}
        </button>
      </div>

      {/* Success/Error Messages */}
      {success && (
        <div className="bg-green-50 border border-green-200 rounded-lg p-4 flex items-center">
          <CheckIcon className="w-5 h-5 text-green-600 mr-3" />
          <span className="text-green-800">{success}</span>
        </div>
      )}

      {error && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4 flex items-center">
          <ExclamationTriangleIcon className="w-5 h-5 text-red-600 mr-3" />
          <span className="text-red-800">{error}</span>
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Left Column */}
        <div className="space-y-6">
          {/* Categories */}
          <PreferenceSection title="Favorite Categories" icon={AcademicCapIcon}>
            <p className="text-sm text-gray-600 mb-4">
              Select the types of classes you're interested in. We'll prioritize these in your recommendations.
            </p>
            <CheckboxList
              options={categories}
              selected={preferences.categories}
              onChange={handleCategoryToggle}
              columns={2}
            />
            <div className="mt-3 text-sm text-gray-500">
              Selected: {preferences.categories.length} categor{preferences.categories.length === 1 ? 'y' : 'ies'}
            </div>
          </PreferenceSection>

          {/* Difficulty Levels */}
          <PreferenceSection title="Skill Level" icon={AcademicCapIcon}>
            <p className="text-sm text-gray-600 mb-4">
              What difficulty levels are you comfortable with?
            </p>
            <CheckboxList
              options={difficultyOptions}
              selected={preferences.difficultyLevels}
              onChange={(value) => handleArrayToggle('difficultyLevels', value)}
              columns={2}
            />
          </PreferenceSection>

          {/* Time Preferences */}
          <PreferenceSection title="Preferred Times" icon={ClockIcon}>
            <p className="text-sm text-gray-600 mb-4">
              When do you prefer to take classes?
            </p>
            <CheckboxList
              options={timeOptions}
              selected={preferences.timePreferences}
              onChange={(value) => handleArrayToggle('timePreferences', value)}
              columns={1}
            />
          </PreferenceSection>

          {/* Duration */}
          <PreferenceSection title="Class Duration" icon={ClockIcon}>
            <p className="text-sm text-gray-600 mb-4">
              How long are you willing to spend in a class?
            </p>
            <CheckboxList
              options={durationOptions}
              selected={preferences.duration}
              onChange={(value) => handleArrayToggle('duration', value)}
              columns={1}
            />
          </PreferenceSection>
        </div>

        {/* Right Column */}
        <div className="space-y-6">
          {/* Price Range */}
          <PreferenceSection title="Price Range" icon={CurrencyDollarIcon}>
            <p className="text-sm text-gray-600 mb-4">
              What's your preferred price range for classes?
            </p>
            <div className="space-y-4">
              <div className="flex items-center space-x-4">
                <div className="flex-1">
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Minimum ($)
                  </label>
                  <input
                    type="number"
                    min="0"
                    max="500"
                    value={preferences.priceRange.min}
                    onChange={(e) => setPreferences(prev => ({
                      ...prev,
                      priceRange: { ...prev.priceRange, min: parseInt(e.target.value) || 0 }
                    }))}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-indigo-500 focus:border-indigo-500"
                  />
                </div>
                <div className="flex-1">
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Maximum ($)
                  </label>
                  <input
                    type="number"
                    min="0"
                    max="500"
                    value={preferences.priceRange.max}
                    onChange={(e) => setPreferences(prev => ({
                      ...prev,
                      priceRange: { ...prev.priceRange, max: parseInt(e.target.value) || 100 }
                    }))}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-indigo-500 focus:border-indigo-500"
                  />
                </div>
              </div>
              <div className="text-sm text-gray-500">
                Current range: ${preferences.priceRange.min} - ${preferences.priceRange.max}
              </div>
            </div>
          </PreferenceSection>

          {/* Location */}
          <PreferenceSection title="Location Preference" icon={MapPinIcon}>
            <p className="text-sm text-gray-600 mb-4">
              How far are you willing to travel for classes?
            </p>
            <div className="space-y-4">
              <div className="space-y-2">
                <label className="flex items-center">
                  <input
                    type="radio"
                    name="locationType"
                    checked={preferences.locationPreference.type === 'anywhere'}
                    onChange={() => setPreferences(prev => ({
                      ...prev,
                      locationPreference: { type: 'anywhere' }
                    }))}
                    className="text-indigo-600 focus:ring-indigo-500"
                  />
                  <span className="ml-2 text-sm text-gray-700">Anywhere</span>
                </label>
                
                <label className="flex items-center">
                  <input
                    type="radio"
                    name="locationType"
                    checked={preferences.locationPreference.type === 'radius'}
                    onChange={() => setPreferences(prev => ({
                      ...prev,
                      locationPreference: { 
                        type: 'radius', 
                        location: prev.locationPreference.location || '',
                        radius: prev.locationPreference.radius || 25 
                      }
                    }))}
                    className="text-indigo-600 focus:ring-indigo-500"
                  />
                  <span className="ml-2 text-sm text-gray-700">Within radius of my location</span>
                </label>
              </div>

              {preferences.locationPreference.type === 'radius' && (
                <div className="ml-6 space-y-3">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Your Location
                    </label>
                    <input
                      type="text"
                      placeholder="City, neighborhood, or address"
                      value={preferences.locationPreference.location || ''}
                      onChange={(e) => setPreferences(prev => ({
                        ...prev,
                        locationPreference: {
                          ...prev.locationPreference,
                          location: e.target.value
                        }
                      }))}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-indigo-500 focus:border-indigo-500"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Maximum Distance ({preferences.locationPreference.radius} km)
                    </label>
                    <input
                      type="range"
                      min="5"
                      max="100"
                      step="5"
                      value={preferences.locationPreference.radius || 25}
                      onChange={(e) => setPreferences(prev => ({
                        ...prev,
                        locationPreference: {
                          ...prev.locationPreference,
                          radius: parseInt(e.target.value)
                        }
                      }))}
                      className="w-full"
                    />
                  </div>
                </div>
              )}
            </div>
          </PreferenceSection>

          {/* Class Size */}
          <PreferenceSection title="Class Size" icon={CalendarDaysIcon}>
            <p className="text-sm text-gray-600 mb-4">
              What size classes do you prefer?
            </p>
            <div className="space-y-2">
              {classSizeOptions.map((option) => (
                <label key={option.value} className="flex items-center">
                  <input
                    type="radio"
                    name="classSize"
                    checked={preferences.classSize === option.value}
                    onChange={() => setPreferences(prev => ({
                      ...prev,
                      classSize: option.value as any
                    }))}
                    className="text-indigo-600 focus:ring-indigo-500"
                  />
                  <span className="ml-2 text-sm text-gray-700">{option.label}</span>
                </label>
              ))}
            </div>
          </PreferenceSection>

          {/* Notifications */}
          <PreferenceSection title="Notifications" icon={BellIcon}>
            <p className="text-sm text-gray-600 mb-4">
              Choose what notifications you'd like to receive.
            </p>
            <div className="space-y-3">
              <label className="flex items-center justify-between">
                <span className="text-sm text-gray-700">New classes in favorite categories</span>
                <input
                  type="checkbox"
                  checked={preferences.notifications.newClasses}
                  onChange={() => handleNotificationToggle('newClasses')}
                  className="rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
                />
              </label>
              
              <label className="flex items-center justify-between">
                <span className="text-sm text-gray-700">Price drops on saved classes</span>
                <input
                  type="checkbox"
                  checked={preferences.notifications.priceDrops}
                  onChange={() => handleNotificationToggle('priceDrops')}
                  className="rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
                />
              </label>
              
              <label className="flex items-center justify-between">
                <span className="text-sm text-gray-700">Updates from followed instructors</span>
                <input
                  type="checkbox"
                  checked={preferences.notifications.followedInstructors}
                  onChange={() => handleNotificationToggle('followedInstructors')}
                  className="rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
                />
              </label>
              
              <label className="flex items-center justify-between">
                <span className="text-sm text-gray-700">Personalized recommendations</span>
                <input
                  type="checkbox"
                  checked={preferences.notifications.recommendations}
                  onChange={() => handleNotificationToggle('recommendations')}
                  className="rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
                />
              </label>
              
              <label className="flex items-center justify-between">
                <span className="text-sm text-gray-700">Class reminders</span>
                <input
                  type="checkbox"
                  checked={preferences.notifications.reminders}
                  onChange={() => handleNotificationToggle('reminders')}
                  className="rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
                />
              </label>
            </div>
          </PreferenceSection>

          {/* Waitlist Settings */}
          <PreferenceSection title="Waitlist Settings" icon={SparklesIcon}>
            <p className="text-sm text-gray-600 mb-4">
              Configure automatic waitlist behavior.
            </p>
            <div className="space-y-4">
              <label className="flex items-center">
                <input
                  type="checkbox"
                  checked={preferences.autoBookWaitlist}
                  onChange={(e) => setPreferences(prev => ({
                    ...prev,
                    autoBookWaitlist: e.target.checked
                  }))}
                  className="rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
                />
                <span className="ml-2 text-sm text-gray-700">
                  Automatically book when spots become available
                </span>
              </label>
              
              {preferences.autoBookWaitlist && (
                <div className="ml-6">
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Maximum price for auto-booking (${preferences.maxWaitlistPrice})
                  </label>
                  <input
                    type="range"
                    min="0"
                    max="200"
                    step="5"
                    value={preferences.maxWaitlistPrice}
                    onChange={(e) => setPreferences(prev => ({
                      ...prev,
                      maxWaitlistPrice: parseInt(e.target.value)
                    }))}
                    className="w-full"
                  />
                </div>
              )}
            </div>
          </PreferenceSection>
        </div>
      </div>
    </div>
  )
}
