/**
 * Student Profile Component
 * Manages student profile information and account settings
 */

'use client'

import React, { useState } from 'react'
import Link from 'next/link'
import { useAuthContext } from '@/lib/context/AuthContext'
import { 
  UserIcon,
  EnvelopeIcon,
  PhoneIcon,
  MapPinIcon,
  CalendarDaysIcon,
  CameraIcon,
  PencilIcon,
  CheckIcon,
  XMarkIcon,
  ExclamationTriangleIcon,
  CreditCardIcon,
  BellIcon,
  ShieldCheckIcon,
  TrashIcon
} from '@heroicons/react/24/outline'

interface ProfileData {
  firstName: string
  lastName: string
  email: string
  phone: string
  dateOfBirth: string
  location: string
  bio: string
  avatar?: string
  joinedDate: string
  totalBookings: number
  completedClasses: number
  averageRating: number
  preferredCategories: string[]
}

// Mock profile data
const mockProfile: ProfileData = {
  firstName: 'Alex',
  lastName: 'Johnson',
  email: 'alex.johnson@email.com',
  phone: '+1 (555) 123-4567',
  dateOfBirth: '1990-05-15',
  location: 'Vancouver, BC',
  bio: 'Creative enthusiast who loves exploring new art forms and learning from talented instructors. Always excited to try something new!',
  joinedDate: '2023-10-15T00:00:00Z',
  totalBookings: 12,
  completedClasses: 8,
  averageRating: 4.8,
  preferredCategories: ['Pottery', 'Painting', 'Jewelry Making']
}

interface PaymentMethod {
  id: string
  type: 'card'
  last4: string
  brand: string
  expiryMonth: number
  expiryYear: number
  isDefault: boolean
}

const mockPaymentMethods: PaymentMethod[] = [
  {
    id: '1',
    type: 'card',
    last4: '4242',
    brand: 'visa',
    expiryMonth: 12,
    expiryYear: 2025,
    isDefault: true
  },
  {
    id: '2',
    type: 'card',
    last4: '0005',
    brand: 'mastercard',
    expiryMonth: 8,
    expiryYear: 2026,
    isDefault: false
  }
]

type EditingField = 'basic' | 'contact' | 'bio' | null

export default function StudentProfile() {
  const { user } = useAuthContext()
  const [profile, setProfile] = useState<ProfileData>(mockProfile)
  const [paymentMethods, setPaymentMethods] = useState<PaymentMethod[]>(mockPaymentMethods)
  const [editingField, setEditingField] = useState<EditingField>(null)
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<string | null>(null)

  const [editForm, setEditForm] = useState({
    firstName: profile.firstName,
    lastName: profile.lastName,
    email: profile.email,
    phone: profile.phone,
    location: profile.location,
    bio: profile.bio
  })

  const handleEditStart = (field: EditingField) => {
    setEditingField(field)
    setError(null)
    setSuccess(null)
  }

  const handleEditCancel = () => {
    setEditingField(null)
    setEditForm({
      firstName: profile.firstName,
      lastName: profile.lastName,
      email: profile.email,
      phone: profile.phone,
      location: profile.location,
      bio: profile.bio
    })
  }

  const handleEditSave = async () => {
    setIsLoading(true)
    setError(null)

    try {
      // Validate required fields
      if (!editForm.firstName.trim() || !editForm.lastName.trim() || !editForm.email.trim()) {
        throw new Error('Name and email are required')
      }

      // Validate email format
      if (!/\S+@\S+\.\S+/.test(editForm.email)) {
        throw new Error('Please enter a valid email address')
      }

      // API call would go here
      await new Promise(resolve => setTimeout(resolve, 1000))

      setProfile(prev => ({
        ...prev,
        firstName: editForm.firstName,
        lastName: editForm.lastName,
        email: editForm.email,
        phone: editForm.phone,
        location: editForm.location,
        bio: editForm.bio
      }))

      setEditingField(null)
      setSuccess('Profile updated successfully!')
      setTimeout(() => setSuccess(null), 3000)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update profile')
    } finally {
      setIsLoading(false)
    }
  }

  const handleDeletePaymentMethod = async (methodId: string) => {
    if (!confirm('Are you sure you want to delete this payment method?')) return

    setIsLoading(true)
    try {
      // API call would go here
      setPaymentMethods(prev => prev.filter(method => method.id !== methodId))
      setSuccess('Payment method deleted successfully!')
      setTimeout(() => setSuccess(null), 3000)
    } catch (err) {
      setError('Failed to delete payment method')
    } finally {
      setIsLoading(false)
    }
  }

  const handleSetDefaultPayment = async (methodId: string) => {
    setIsLoading(true)
    try {
      // API call would go here
      setPaymentMethods(prev => prev.map(method => ({
        ...method,
        isDefault: method.id === methodId
      })))
      setSuccess('Default payment method updated!')
      setTimeout(() => setSuccess(null), 3000)
    } catch (err) {
      setError('Failed to update default payment method')
    } finally {
      setIsLoading(false)
    }
  }

  const formatJoinDate = (dateString: string) => {
    const date = new Date(dateString)
    return date.toLocaleDateString('en-US', { 
      month: 'long', 
      year: 'numeric' 
    })
  }

  const EditableField = ({ 
    field, 
    value, 
    placeholder, 
    type = 'text',
    multiline = false 
  }: {
    field: keyof typeof editForm
    value: string
    placeholder: string
    type?: string
    multiline?: boolean
  }) => {
    if (multiline) {
      return (
        <textarea
          value={editForm[field]}
          onChange={(e) => setEditForm(prev => ({ ...prev, [field]: e.target.value }))}
          placeholder={placeholder}
          className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-indigo-500 focus:border-indigo-500 resize-none"
          rows={3}
        />
      )
    }

    return (
      <input
        type={type}
        value={editForm[field]}
        onChange={(e) => setEditForm(prev => ({ ...prev, [field]: e.target.value }))}
        placeholder={placeholder}
        className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-indigo-500 focus:border-indigo-500"
      />
    )
  }

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">My Profile</h1>
        <Link
          href="/student/profile/preferences"
          className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-indigo-600 bg-indigo-100 hover:bg-indigo-200"
        >
          Manage Preferences
        </Link>
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

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Left Column - Profile Info */}
        <div className="lg:col-span-2 space-y-6">
          {/* Basic Information */}
          <div className="bg-white border border-gray-200 rounded-lg p-6">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-lg font-semibold text-gray-900">Basic Information</h2>
              {editingField !== 'basic' ? (
                <button
                  onClick={() => handleEditStart('basic')}
                  className="inline-flex items-center px-3 py-2 text-sm font-medium text-indigo-600 hover:text-indigo-700"
                >
                  <PencilIcon className="w-4 h-4 mr-1" />
                  Edit
                </button>
              ) : (
                <div className="flex items-center space-x-2">
                  <button
                    onClick={handleEditSave}
                    disabled={isLoading}
                    className="inline-flex items-center px-3 py-2 text-sm font-medium text-green-600 hover:text-green-700 disabled:opacity-50"
                  >
                    <CheckIcon className="w-4 h-4 mr-1" />
                    Save
                  </button>
                  <button
                    onClick={handleEditCancel}
                    disabled={isLoading}
                    className="inline-flex items-center px-3 py-2 text-sm font-medium text-gray-600 hover:text-gray-700"
                  >
                    <XMarkIcon className="w-4 h-4 mr-1" />
                    Cancel
                  </button>
                </div>
              )}
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  First Name
                </label>
                {editingField === 'basic' ? (
                  <EditableField
                    field="firstName"
                    value={profile.firstName}
                    placeholder="Enter first name"
                  />
                ) : (
                  <p className="text-gray-900">{profile.firstName}</p>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Last Name
                </label>
                {editingField === 'basic' ? (
                  <EditableField
                    field="lastName"
                    value={profile.lastName}
                    placeholder="Enter last name"
                  />
                ) : (
                  <p className="text-gray-900">{profile.lastName}</p>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Date of Birth
                </label>
                <p className="text-gray-900">{new Date(profile.dateOfBirth).toLocaleDateString()}</p>
                <p className="text-xs text-gray-500 mt-1">Contact support to change</p>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Member Since
                </label>
                <p className="text-gray-900">{formatJoinDate(profile.joinedDate)}</p>
              </div>
            </div>
          </div>

          {/* Contact Information */}
          <div className="bg-white border border-gray-200 rounded-lg p-6">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-lg font-semibold text-gray-900">Contact Information</h2>
              {editingField !== 'contact' ? (
                <button
                  onClick={() => handleEditStart('contact')}
                  className="inline-flex items-center px-3 py-2 text-sm font-medium text-indigo-600 hover:text-indigo-700"
                >
                  <PencilIcon className="w-4 h-4 mr-1" />
                  Edit
                </button>
              ) : (
                <div className="flex items-center space-x-2">
                  <button
                    onClick={handleEditSave}
                    disabled={isLoading}
                    className="inline-flex items-center px-3 py-2 text-sm font-medium text-green-600 hover:text-green-700 disabled:opacity-50"
                  >
                    <CheckIcon className="w-4 h-4 mr-1" />
                    Save
                  </button>
                  <button
                    onClick={handleEditCancel}
                    disabled={isLoading}
                    className="inline-flex items-center px-3 py-2 text-sm font-medium text-gray-600 hover:text-gray-700"
                  >
                    <XMarkIcon className="w-4 h-4 mr-1" />
                    Cancel
                  </button>
                </div>
              )}
            </div>

            <div className="space-y-4">
              <div className="flex items-center">
                <EnvelopeIcon className="w-5 h-5 text-gray-400 mr-3" />
                <div className="flex-1">
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Email Address
                  </label>
                  {editingField === 'contact' ? (
                    <EditableField
                      field="email"
                      value={profile.email}
                      placeholder="Enter email address"
                      type="email"
                    />
                  ) : (
                    <p className="text-gray-900">{profile.email}</p>
                  )}
                </div>
              </div>

              <div className="flex items-center">
                <PhoneIcon className="w-5 h-5 text-gray-400 mr-3" />
                <div className="flex-1">
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Phone Number
                  </label>
                  {editingField === 'contact' ? (
                    <EditableField
                      field="phone"
                      value={profile.phone}
                      placeholder="Enter phone number"
                      type="tel"
                    />
                  ) : (
                    <p className="text-gray-900">{profile.phone || 'Not provided'}</p>
                  )}
                </div>
              </div>

              <div className="flex items-center">
                <MapPinIcon className="w-5 h-5 text-gray-400 mr-3" />
                <div className="flex-1">
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Location
                  </label>
                  {editingField === 'contact' ? (
                    <EditableField
                      field="location"
                      value={profile.location}
                      placeholder="Enter your location"
                    />
                  ) : (
                    <p className="text-gray-900">{profile.location || 'Not specified'}</p>
                  )}
                </div>
              </div>
            </div>
          </div>

          {/* Bio */}
          <div className="bg-white border border-gray-200 rounded-lg p-6">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-lg font-semibold text-gray-900">About Me</h2>
              {editingField !== 'bio' ? (
                <button
                  onClick={() => handleEditStart('bio')}
                  className="inline-flex items-center px-3 py-2 text-sm font-medium text-indigo-600 hover:text-indigo-700"
                >
                  <PencilIcon className="w-4 h-4 mr-1" />
                  Edit
                </button>
              ) : (
                <div className="flex items-center space-x-2">
                  <button
                    onClick={handleEditSave}
                    disabled={isLoading}
                    className="inline-flex items-center px-3 py-2 text-sm font-medium text-green-600 hover:text-green-700 disabled:opacity-50"
                  >
                    <CheckIcon className="w-4 h-4 mr-1" />
                    Save
                  </button>
                  <button
                    onClick={handleEditCancel}
                    disabled={isLoading}
                    className="inline-flex items-center px-3 py-2 text-sm font-medium text-gray-600 hover:text-gray-700"
                  >
                    <XMarkIcon className="w-4 h-4 mr-1" />
                    Cancel
                  </button>
                </div>
              )}
            </div>

            {editingField === 'bio' ? (
              <EditableField
                field="bio"
                value={profile.bio}
                placeholder="Tell us about yourself and your creative interests..."
                multiline
              />
            ) : (
              <p className="text-gray-700">
                {profile.bio || 'No bio provided yet. Tell us about your creative journey!'}
              </p>
            )}
          </div>

          {/* Payment Methods */}
          <div className="bg-white border border-gray-200 rounded-lg p-6">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-lg font-semibold text-gray-900">Payment Methods</h2>
              <button className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700">
                <CreditCardIcon className="w-4 h-4 mr-2" />
                Add New Card
              </button>
            </div>

            {paymentMethods.length === 0 ? (
              <div className="text-center py-6">
                <CreditCardIcon className="w-12 h-12 text-gray-400 mx-auto mb-4" />
                <p className="text-gray-600 mb-4">No payment methods saved</p>
                <button className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700">
                  Add Your First Card
                </button>
              </div>
            ) : (
              <div className="space-y-3">
                {paymentMethods.map((method) => (
                  <div
                    key={method.id}
                    className="flex items-center justify-between p-4 border border-gray-200 rounded-lg"
                  >
                    <div className="flex items-center">
                      <CreditCardIcon className="w-8 h-8 text-gray-400 mr-4" />
                      <div>
                        <p className="font-medium text-gray-900">
                          {method.brand.charAt(0).toUpperCase() + method.brand.slice(1)} •••• {method.last4}
                        </p>
                        <p className="text-sm text-gray-600">
                          Expires {method.expiryMonth.toString().padStart(2, '0')}/{method.expiryYear}
                        </p>
                      </div>
                      {method.isDefault && (
                        <span className="ml-3 inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
                          Default
                        </span>
                      )}
                    </div>
                    <div className="flex items-center space-x-2">
                      {!method.isDefault && (
                        <button
                          onClick={() => handleSetDefaultPayment(method.id)}
                          disabled={isLoading}
                          className="text-sm font-medium text-indigo-600 hover:text-indigo-700 disabled:opacity-50"
                        >
                          Make Default
                        </button>
                      )}
                      <button
                        onClick={() => handleDeletePaymentMethod(method.id)}
                        disabled={isLoading || method.isDefault}
                        className="p-1 text-red-600 hover:text-red-700 disabled:opacity-50 disabled:cursor-not-allowed"
                        title={method.isDefault ? 'Cannot delete default payment method' : 'Delete payment method'}
                      >
                        <TrashIcon className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Right Column - Profile Summary & Quick Actions */}
        <div className="space-y-6">
          {/* Profile Summary */}
          <div className="bg-white border border-gray-200 rounded-lg p-6 text-center">
            <div className="w-24 h-24 bg-indigo-500 rounded-full flex items-center justify-center mx-auto mb-4">
              <span className="text-white font-semibold text-xl">
                {profile.firstName.charAt(0)}{profile.lastName.charAt(0)}
              </span>
            </div>
            <h3 className="text-lg font-semibold text-gray-900 mb-1">
              {profile.firstName} {profile.lastName}
            </h3>
            <p className="text-gray-600 mb-4">{profile.email}</p>
            
            <button className="inline-flex items-center px-3 py-2 text-sm font-medium text-indigo-600 hover:text-indigo-700 mb-4">
              <CameraIcon className="w-4 h-4 mr-2" />
              Change Photo
            </button>

            <div className="grid grid-cols-2 gap-4 text-center">
              <div>
                <div className="text-xl font-bold text-gray-900">{profile.totalBookings}</div>
                <div className="text-xs text-gray-500">Bookings</div>
              </div>
              <div>
                <div className="text-xl font-bold text-green-600">{profile.completedClasses}</div>
                <div className="text-xs text-gray-500">Completed</div>
              </div>
            </div>
          </div>

          {/* Quick Settings */}
          <div className="bg-white border border-gray-200 rounded-lg p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Quick Settings</h3>
            
            <div className="space-y-3">
              <Link
                href="/student/profile/preferences"
                className="flex items-center p-3 text-left w-full rounded-lg hover:bg-gray-50 transition-colors"
              >
                <div className="w-8 h-8 bg-purple-100 rounded-lg flex items-center justify-center mr-3">
                  <UserIcon className="w-4 h-4 text-purple-600" />
                </div>
                <div>
                  <p className="font-medium text-gray-900">Preferences</p>
                  <p className="text-sm text-gray-600">Manage class preferences</p>
                </div>
              </Link>
              
              <Link
                href="/student/settings/notifications"
                className="flex items-center p-3 text-left w-full rounded-lg hover:bg-gray-50 transition-colors"
              >
                <div className="w-8 h-8 bg-blue-100 rounded-lg flex items-center justify-center mr-3">
                  <BellIcon className="w-4 h-4 text-blue-600" />
                </div>
                <div>
                  <p className="font-medium text-gray-900">Notifications</p>
                  <p className="text-sm text-gray-600">Email & push settings</p>
                </div>
              </Link>
              
              <Link
                href="/student/settings/privacy"
                className="flex items-center p-3 text-left w-full rounded-lg hover:bg-gray-50 transition-colors"
              >
                <div className="w-8 h-8 bg-green-100 rounded-lg flex items-center justify-center mr-3">
                  <ShieldCheckIcon className="w-4 h-4 text-green-600" />
                </div>
                <div>
                  <p className="font-medium text-gray-900">Privacy & Security</p>
                  <p className="text-sm text-gray-600">Account security</p>
                </div>
              </Link>
            </div>
          </div>

          {/* Account Stats */}
          <div className="bg-white border border-gray-200 rounded-lg p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Account Stats</h3>
            
            <div className="space-y-4">
              <div className="flex justify-between items-center">
                <span className="text-sm text-gray-600">Average Rating Given</span>
                <span className="font-medium text-gray-900">{profile.averageRating}★</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm text-gray-600">Preferred Categories</span>
                <span className="font-medium text-gray-900">{profile.preferredCategories.length}</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm text-gray-600">Member Since</span>
                <span className="font-medium text-gray-900">{formatJoinDate(profile.joinedDate)}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}