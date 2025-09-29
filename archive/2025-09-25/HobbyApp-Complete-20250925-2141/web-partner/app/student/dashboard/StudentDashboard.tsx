/**
 * Student Dashboard Component
 * Main dashboard showing overview of student's activity and quick actions
 */

'use client'

import React, { useState, useEffect } from 'react'
import Link from 'next/link'
import { useAuthContext } from '@/lib/context/AuthContext'
import { 
  CalendarDaysIcon,
  BookmarkIcon,
  HeartIcon,
  StarIcon,
  MapPinIcon,
  ClockIcon,
  SparklesIcon,
  ArrowRightIcon,
  BellIcon,
  CreditCardIcon
} from '@heroicons/react/24/outline'
import {
  CalendarDaysIcon as CalendarDaysIconSolid,
  HeartIcon as HeartIconSolid,
  BookmarkIcon as BookmarkIconSolid
} from '@heroicons/react/24/solid'

// Mock data for dashboard
const mockDashboardData = {
  upcomingBookings: [
    {
      id: 'booking_1',
      title: 'Advanced Ceramics Workshop',
      instructor: 'Sarah Chen',
      date: '2024-01-20T14:00:00Z',
      timeSlot: '2:00 PM - 4:00 PM',
      location: 'Downtown Studio',
      price: 65,
      status: 'confirmed'
    },
    {
      id: 'booking_2',
      title: 'Watercolor Landscapes',
      instructor: 'Michael Torres',
      date: '2024-01-25T10:00:00Z',
      timeSlot: '10:00 AM - 12:30 PM',
      location: 'Art Center',
      price: 45,
      status: 'confirmed'
    }
  ],
  recentActivity: [
    {
      id: 'activity_1',
      type: 'booking_completed',
      message: 'You completed "Jewelry Making Workshop" with Emma Rodriguez',
      timestamp: '2024-01-10T16:30:00Z',
      icon: '✅'
    },
    {
      id: 'activity_2',
      type: 'instructor_followed',
      message: 'You started following Sarah Chen',
      timestamp: '2024-01-08T11:20:00Z',
      icon: '❤️'
    },
    {
      id: 'activity_3',
      type: 'class_saved',
      message: 'You saved "Advanced Pottery Workshop"',
      timestamp: '2024-01-07T14:15:00Z',
      icon: '🔖'
    }
  ],
  quickRecommendations: [
    {
      id: 'rec_1',
      title: 'Advanced Glazing Techniques',
      instructor: 'Sarah Chen',
      category: 'Pottery',
      price: 75,
      rating: 4.9,
      reason: 'New from an instructor you follow',
      isNew: true
    },
    {
      id: 'rec_2',
      title: 'Abstract Acrylic Painting',
      instructor: 'Lisa Park',
      category: 'Painting',
      price: 50,
      rating: 4.7,
      reason: 'Similar to classes you\'ve enjoyed'
    }
  ],
  stats: {
    totalBookings: 12,
    completedClasses: 8,
    instructorsFollowed: 3,
    classesSaved: 5,
    totalSpent: 540,
    averageRating: 4.8
  },
  notifications: [
    {
      id: 'notif_1',
      type: 'reminder',
      title: 'Class Tomorrow',
      message: 'Advanced Ceramics Workshop with Sarah Chen starts at 2:00 PM',
      timestamp: '2024-01-19T09:00:00Z',
      isRead: false
    },
    {
      id: 'notif_2',
      type: 'new_class',
      title: 'New Class Available',
      message: 'Sarah Chen just posted a new Advanced Glazing workshop',
      timestamp: '2024-01-18T15:30:00Z',
      isRead: false
    }
  ]
}

export default function StudentDashboard() {
  const { user } = useAuthContext()
  const [dashboardData] = useState(mockDashboardData)
  const [notifications, setNotifications] = useState(mockDashboardData.notifications)

  const formatDate = (dateString: string) => {
    const date = new Date(dateString)
    const now = new Date()
    const diffTime = date.getTime() - now.getTime()
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
    
    if (diffDays === 0) return 'Today'
    if (diffDays === 1) return 'Tomorrow'
    if (diffDays > 0 && diffDays <= 7) return `In ${diffDays} days`
    
    return date.toLocaleDateString('en-US', { 
      weekday: 'short',
      month: 'short', 
      day: 'numeric' 
    })
  }

  const formatTimeAgo = (dateString: string) => {
    const date = new Date(dateString)
    const now = new Date()
    const diffTime = now.getTime() - date.getTime()
    const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24))
    const diffHours = Math.floor(diffTime / (1000 * 60 * 60))
    
    if (diffDays > 0) return `${diffDays} day${diffDays === 1 ? '' : 's'} ago`
    if (diffHours > 0) return `${diffHours} hour${diffHours === 1 ? '' : 's'} ago`
    return 'Just now'
  }

  const markNotificationRead = (notificationId: string) => {
    setNotifications(prev => prev.map(notif => 
      notif.id === notificationId ? { ...notif, isRead: true } : notif
    ))
  }

  const unreadCount = notifications.filter(n => !n.isRead).length

  return (
    <div className="space-y-8">
      {/* Welcome Header */}
      <div className="bg-gradient-to-r from-indigo-500 to-purple-600 rounded-lg text-white p-6">
        <h1 className="text-2xl font-bold mb-2">
          Welcome back, {user?.user_metadata?.first_name || user?.email?.split('@')[0] || 'there'}! 👋
        </h1>
        <p className="text-indigo-100 mb-4">
          Ready to continue your creative journey? You have {dashboardData.upcomingBookings.length} upcoming class{dashboardData.upcomingBookings.length === 1 ? '' : 'es'}.
        </p>
        <div className="flex items-center space-x-4">
          <Link
            href="/student/discovery"
            className="inline-flex items-center px-4 py-2 bg-white text-indigo-600 rounded-md hover:bg-gray-100 transition-colors font-medium"
          >
            Explore Classes
            <ArrowRightIcon className="w-4 h-4 ml-2" />
          </Link>
          <Link
            href="/student/dashboard/bookings"
            className="inline-flex items-center px-4 py-2 bg-indigo-400 bg-opacity-50 text-white rounded-md hover:bg-opacity-70 transition-colors font-medium"
          >
            <CalendarDaysIconSolid className="w-4 h-4 mr-2" />
            My Bookings
          </Link>
        </div>
      </div>

      {/* Quick Stats */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
        <div className="bg-white border border-gray-200 rounded-lg p-4 text-center">
          <div className="text-2xl font-bold text-gray-900">{dashboardData.stats.totalBookings}</div>
          <div className="text-sm text-gray-500">Total Bookings</div>
        </div>
        <div className="bg-white border border-gray-200 rounded-lg p-4 text-center">
          <div className="text-2xl font-bold text-green-600">{dashboardData.stats.completedClasses}</div>
          <div className="text-sm text-gray-500">Completed</div>
        </div>
        <div className="bg-white border border-gray-200 rounded-lg p-4 text-center">
          <div className="text-2xl font-bold text-pink-600">{dashboardData.stats.instructorsFollowed}</div>
          <div className="text-sm text-gray-500">Following</div>
        </div>
        <div className="bg-white border border-gray-200 rounded-lg p-4 text-center">
          <div className="text-2xl font-bold text-purple-600">{dashboardData.stats.classesSaved}</div>
          <div className="text-sm text-gray-500">Saved</div>
        </div>
        <div className="bg-white border border-gray-200 rounded-lg p-4 text-center">
          <div className="text-2xl font-bold text-blue-600">${dashboardData.stats.totalSpent}</div>
          <div className="text-sm text-gray-500">Total Spent</div>
        </div>
        <div className="bg-white border border-gray-200 rounded-lg p-4 text-center">
          <div className="text-2xl font-bold text-yellow-600">{dashboardData.stats.averageRating}</div>
          <div className="text-sm text-gray-500">Avg Rating</div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Left Column */}
        <div className="lg:col-span-2 space-y-6">
          {/* Upcoming Bookings */}
          <div className="bg-white border border-gray-200 rounded-lg p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold text-gray-900 flex items-center">
                <CalendarDaysIconSolid className="w-5 h-5 text-blue-600 mr-2" />
                Upcoming Classes
              </h2>
              <Link
                href="/student/dashboard/bookings"
                className="text-indigo-600 hover:text-indigo-700 text-sm font-medium flex items-center"
              >
                View all
                <ArrowRightIcon className="w-4 h-4 ml-1" />
              </Link>
            </div>
            
            {dashboardData.upcomingBookings.length === 0 ? (
              <div className="text-center py-8">
                <CalendarDaysIcon className="w-12 h-12 text-gray-400 mx-auto mb-4" />
                <p className="text-gray-600 mb-4">No upcoming classes scheduled</p>
                <Link
                  href="/student/discovery"
                  className="inline-flex items-center px-4 py-2 bg-indigo-600 text-white rounded-md hover:bg-indigo-700 transition-colors"
                >
                  Book Your First Class
                </Link>
              </div>
            ) : (
              <div className="space-y-4">
                {dashboardData.upcomingBookings.slice(0, 3).map((booking) => (
                  <div
                    key={booking.id}
                    className="flex items-center p-4 bg-blue-50 rounded-lg border border-blue-200"
                  >
                    <div className="flex-1">
                      <h3 className="font-semibold text-gray-900">{booking.title}</h3>
                      <p className="text-sm text-gray-600">with {booking.instructor}</p>
                      <div className="flex items-center mt-1 text-sm text-gray-600">
                        <ClockIcon className="w-4 h-4 mr-1" />
                        {formatDate(booking.date)} • {booking.timeSlot}
                        <MapPinIcon className="w-4 h-4 ml-3 mr-1" />
                        {booking.location}
                      </div>
                    </div>
                    <div className="text-right">
                      <p className="font-semibold text-gray-900">${booking.price}</p>
                      <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
                        Confirmed
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Quick Recommendations */}
          <div className="bg-white border border-gray-200 rounded-lg p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold text-gray-900 flex items-center">
                <SparklesIcon className="w-5 h-5 text-indigo-600 mr-2" />
                Recommended for You
              </h2>
              <Link
                href="/student/dashboard/recommendations"
                className="text-indigo-600 hover:text-indigo-700 text-sm font-medium flex items-center"
              >
                View all
                <ArrowRightIcon className="w-4 h-4 ml-1" />
              </Link>
            </div>
            
            <div className="space-y-4">
              {dashboardData.quickRecommendations.map((rec) => (
                <div
                  key={rec.id}
                  className="flex items-center p-4 bg-gradient-to-r from-purple-50 to-indigo-50 rounded-lg border border-purple-200"
                >
                  <div className="flex-1">
                    <div className="flex items-center mb-1">
                      <h3 className="font-semibold text-gray-900">{rec.title}</h3>
                      {rec.isNew && (
                        <span className="ml-2 inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                          New!
                        </span>
                      )}
                    </div>
                    <p className="text-sm text-gray-600">by {rec.instructor} • {rec.category}</p>
                    <p className="text-xs text-purple-700 mt-1 italic">{rec.reason}</p>
                  </div>
                  <div className="text-right">
                    <div className="flex items-center mb-2">
                      <StarIcon className="w-4 h-4 text-yellow-400 fill-current mr-1" />
                      <span className="text-sm text-gray-600">{rec.rating}</span>
                    </div>
                    <p className="font-semibold text-gray-900 mb-2">${rec.price}</p>
                    <Link
                      href={`/student/booking/${rec.id}`}
                      className="inline-flex items-center px-3 py-1 bg-indigo-600 text-white text-sm rounded-md hover:bg-indigo-700 transition-colors"
                    >
                      Book
                    </Link>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Right Column */}
        <div className="space-y-6">
          {/* Notifications */}
          <div className="bg-white border border-gray-200 rounded-lg p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold text-gray-900 flex items-center">
                <BellIcon className="w-5 h-5 text-gray-600 mr-2" />
                Notifications
                {unreadCount > 0 && (
                  <span className="ml-2 inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-red-100 text-red-800">
                    {unreadCount}
                  </span>
                )}
              </h2>
            </div>
            
            {notifications.length === 0 ? (
              <div className="text-center py-4">
                <BellIcon className="w-8 h-8 text-gray-400 mx-auto mb-2" />
                <p className="text-sm text-gray-600">No notifications</p>
              </div>
            ) : (
              <div className="space-y-3">
                {notifications.slice(0, 3).map((notification) => (
                  <div
                    key={notification.id}
                    className={`p-3 rounded-lg cursor-pointer transition-colors ${
                      notification.isRead
                        ? 'bg-gray-50'
                        : 'bg-blue-50 border border-blue-200'
                    }`}
                    onClick={() => markNotificationRead(notification.id)}
                  >
                    <div className="flex justify-between items-start mb-1">
                      <h4 className="text-sm font-medium text-gray-900">
                        {notification.title}
                      </h4>
                      {!notification.isRead && (
                        <div className="w-2 h-2 bg-blue-600 rounded-full flex-shrink-0 ml-2 mt-1" />
                      )}
                    </div>
                    <p className="text-xs text-gray-600 mb-1">
                      {notification.message}
                    </p>
                    <p className="text-xs text-gray-500">
                      {formatTimeAgo(notification.timestamp)}
                    </p>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Recent Activity */}
          <div className="bg-white border border-gray-200 rounded-lg p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">Recent Activity</h2>
            
            <div className="space-y-3">
              {dashboardData.recentActivity.map((activity) => (
                <div key={activity.id} className="flex items-start space-x-3">
                  <span className="text-lg">{activity.icon}</span>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm text-gray-700">{activity.message}</p>
                    <p className="text-xs text-gray-500">
                      {formatTimeAgo(activity.timestamp)}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Quick Actions */}
          <div className="bg-white border border-gray-200 rounded-lg p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">Quick Actions</h2>
            
            <div className="space-y-3">
              <Link
                href="/student/discovery"
                className="flex items-center p-3 text-left w-full rounded-lg hover:bg-gray-50 transition-colors"
              >
                <div className="w-8 h-8 bg-indigo-100 rounded-lg flex items-center justify-center mr-3">
                  <CalendarDaysIcon className="w-4 h-4 text-indigo-600" />
                </div>
                <div>
                  <p className="font-medium text-gray-900">Book a Class</p>
                  <p className="text-sm text-gray-600">Explore available classes</p>
                </div>
              </Link>
              
              <Link
                href="/student/dashboard/following"
                className="flex items-center p-3 text-left w-full rounded-lg hover:bg-gray-50 transition-colors"
              >
                <div className="w-8 h-8 bg-pink-100 rounded-lg flex items-center justify-center mr-3">
                  <HeartIconSolid className="w-4 h-4 text-pink-600" />
                </div>
                <div>
                  <p className="font-medium text-gray-900">Following</p>
                  <p className="text-sm text-gray-600">Check instructor updates</p>
                </div>
              </Link>
              
              <Link
                href="/student/dashboard/saved"
                className="flex items-center p-3 text-left w-full rounded-lg hover:bg-gray-50 transition-colors"
              >
                <div className="w-8 h-8 bg-purple-100 rounded-lg flex items-center justify-center mr-3">
                  <BookmarkIconSolid className="w-4 h-4 text-purple-600" />
                </div>
                <div>
                  <p className="font-medium text-gray-900">Saved Classes</p>
                  <p className="text-sm text-gray-600">Review your saved list</p>
                </div>
              </Link>
              
              <Link
                href="/student/profile"
                className="flex items-center p-3 text-left w-full rounded-lg hover:bg-gray-50 transition-colors"
              >
                <div className="w-8 h-8 bg-gray-100 rounded-lg flex items-center justify-center mr-3">
                  <CreditCardIcon className="w-4 h-4 text-gray-600" />
                </div>
                <div>
                  <p className="font-medium text-gray-900">Manage Profile</p>
                  <p className="text-sm text-gray-600">Update preferences & payment</p>
                </div>
              </Link>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}