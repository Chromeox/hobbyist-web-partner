/**
 * Student Layout Component
 * Provides navigation and layout wrapper for all student pages
 */

'use client'

import React from 'react'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { useAuthContext } from '@/lib/context/AuthContext'
import { PaymentModelProvider } from '@/lib/contexts/PaymentModelContext'
import { 
  HomeIcon, 
  MagnifyingGlassIcon, 
  BookmarkIcon,
  CalendarDaysIcon,
  UserIcon,
  HeartIcon,
  BellIcon
} from '@heroicons/react/24/outline'
import {
  HomeIcon as HomeIconSolid,
  MagnifyingGlassIcon as MagnifyingGlassIconSolid,
  BookmarkIcon as BookmarkIconSolid,
  CalendarDaysIcon as CalendarDaysIconSolid,
  UserIcon as UserIconSolid,
  HeartIcon as HeartIconSolid,
  BellIcon as BellIconSolid
} from '@heroicons/react/24/solid'

interface StudentLayoutProps {
  children: React.ReactNode
}

const navigation = [
  {
    name: 'Home',
    href: '/student',
    icon: HomeIcon,
    activeIcon: HomeIconSolid,
  },
  {
    name: 'Discover',
    href: '/student/discovery',
    icon: MagnifyingGlassIcon,
    activeIcon: MagnifyingGlassIconSolid,
  },
  {
    name: 'My Bookings',
    href: '/student/dashboard/bookings',
    icon: CalendarDaysIcon,
    activeIcon: CalendarDaysIconSolid,
  },
  {
    name: 'Following',
    href: '/student/dashboard/following',
    icon: HeartIcon,
    activeIcon: HeartIconSolid,
  },
  {
    name: 'Saved',
    href: '/student/dashboard/saved',
    icon: BookmarkIcon,
    activeIcon: BookmarkIconSolid,
  },
  {
    name: 'Profile',
    href: '/student/profile',
    icon: UserIcon,
    activeIcon: UserIconSolid,
  },
]

export default function StudentLayout({ children }: StudentLayoutProps) {
  const pathname = usePathname()
  const { user, isLoading } = useAuthContext()

  // Loading state
  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
      </div>
    )
  }

  return (
    <PaymentModelProvider>
      <div className="min-h-screen bg-gray-50">
        {/* Mobile header */}
        <div className="lg:hidden">
          <div className="flex items-center justify-between p-4 bg-white shadow-sm">
            <div className="flex items-center">
              <h1 className="text-xl font-semibold text-gray-900">HobbyistSwiftUI</h1>
            </div>
            <button
              type="button"
              className="relative inline-flex items-center justify-center rounded-md p-2 text-gray-600 hover:bg-gray-100 hover:text-gray-900"
              aria-label="Notifications"
            >
              <BellIcon className="h-6 w-6" />
              <span className="absolute -top-1 -right-1 h-4 w-4 bg-red-500 rounded-full text-xs text-white flex items-center justify-center">
                3
              </span>
            </button>
          </div>
        </div>

        {/* Desktop sidebar */}
        <div className="hidden lg:fixed lg:inset-y-0 lg:flex lg:w-64 lg:flex-col">
          <div className="flex min-h-0 flex-1 flex-col bg-white shadow-lg">
            <div className="flex flex-1 flex-col overflow-y-auto pt-5 pb-4">
              <div className="flex flex-shrink-0 items-center px-4">
                <h1 className="text-xl font-semibold text-gray-900">HobbyistSwiftUI</h1>
              </div>
              <nav className="mt-8 flex-1 space-y-1 px-2" aria-label="Sidebar">
                {navigation.map((item) => {
                  const isActive = pathname === item.href || 
                    (item.href !== '/student' && pathname.startsWith(item.href))
                  const Icon = isActive ? item.activeIcon : item.icon
                  
                  return (
                    <Link
                      key={item.name}
                      href={item.href}
                      className={`${
                        isActive
                          ? 'bg-indigo-50 border-r-4 border-indigo-600 text-indigo-700'
                          : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
                      } group flex items-center px-2 py-3 text-sm font-medium rounded-md transition-colors duration-200`}
                      aria-current={isActive ? 'page' : undefined}
                    >
                      <Icon
                        className={`${
                          isActive ? 'text-indigo-500' : 'text-gray-400 group-hover:text-gray-500'
                        } mr-3 h-6 w-6 flex-shrink-0`}
                        aria-hidden="true"
                      />
                      {item.name}
                    </Link>
                  )
                })}
              </nav>
            </div>
            
            {/* User profile section */}
            <div className="flex flex-shrink-0 border-t border-gray-200 p-4">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <div className="h-8 w-8 rounded-full bg-indigo-500 flex items-center justify-center">
                    <span className="text-sm font-medium text-white">
                      {user?.email?.[0]?.toUpperCase() || 'U'}
                    </span>
                  </div>
                </div>
                <div className="ml-3">
                  <p className="text-sm font-medium text-gray-700 truncate">
                    {user?.user_metadata?.first_name || user?.email?.split('@')[0] || 'Student'}
                  </p>
                  <p className="text-xs text-gray-500 truncate">
                    {user?.email}
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Main content */}
        <div className="lg:pl-64 flex flex-col flex-1">
          <main className="flex-1 pb-20 lg:pb-8">
            <div className="py-6">
              <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                {children}
              </div>
            </div>
          </main>
        </div>

        {/* Mobile bottom navigation */}
        <div className="lg:hidden">
          <div className="fixed inset-x-0 bottom-0 bg-white border-t border-gray-200">
            <div className="flex justify-around">
              {navigation.slice(0, 5).map((item) => {
                const isActive = pathname === item.href || 
                  (item.href !== '/student' && pathname.startsWith(item.href))
                const Icon = isActive ? item.activeIcon : item.icon
                
                return (
                  <Link
                    key={item.name}
                    href={item.href}
                    className={`${
                      isActive
                        ? 'text-indigo-600'
                        : 'text-gray-400'
                    } flex-1 flex flex-col items-center px-2 py-2 text-xs font-medium`}
                  >
                    <Icon className="h-6 w-6 mb-1" aria-hidden="true" />
                    <span className="truncate">{item.name}</span>
                  </Link>
                )
              })}
            </div>
          </div>
        </div>
      </div>
    </PaymentModelProvider>
  )
}
