/**
 * Reviews Management Page
 */

'use client'

import { useState } from 'react'
import { motion } from 'framer-motion'
import { ProtectedRoute } from '@/lib/components/ProtectedRoute'
import { useUserProfile } from '@/lib/hooks/useAuth'
import DashboardLayout from '../DashboardLayout'
import ReviewManagement from './ReviewManagement'
import ReviewAnalytics from './ReviewAnalytics'
import { 
  BarChart3, 
  MessageCircle, 
  Settings,
  Eye,
  Filter,
  TrendingUp 
} from 'lucide-react'

type TabType = 'management' | 'analytics'

export default function ReviewsPage() {
  const { profile, isLoading } = useUserProfile()
  const [activeTab, setActiveTab] = useState<TabType>('management')

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
          <p className="mt-4 text-gray-600">Loading reviews...</p>
        </div>
      </div>
    )
  }

  const tabs = [
    {
      id: 'management' as TabType,
      label: 'Review Management',
      icon: MessageCircle,
      description: 'Manage and respond to customer reviews',
      count: '156' // This would come from actual data
    },
    {
      id: 'analytics' as TabType,
      label: 'Analytics & Insights',
      icon: BarChart3,
      description: 'Review performance metrics and trends',
      count: '4.6★' // Average rating
    }
  ]

  return (
    <ProtectedRoute>
      <DashboardLayout 
        studioName={profile?.instructor?.businessName || "Studio"} 
        userName={`${profile?.profile?.firstName || ''} ${profile?.profile?.lastName || ''}`.trim() || 'User'}
      >
        <div className="space-y-6">
          {/* Header */}
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
                Reviews & Ratings
              </h1>
              <p className="mt-2 text-gray-600 dark:text-gray-400">
                Monitor customer feedback and track performance metrics
              </p>
            </div>
            
            {/* Quick Stats */}
            <div className="flex items-center gap-4">
              <div className="text-right">
                <p className="text-sm text-gray-600 dark:text-gray-400">Overall Rating</p>
                <p className="text-2xl font-bold text-gray-900 dark:text-white">4.6★</p>
              </div>
              <div className="text-right">
                <p className="text-sm text-gray-600 dark:text-gray-400">This Month</p>
                <div className="flex items-center gap-1">
                  <TrendingUp className="text-green-500" size={16} />
                  <p className="text-2xl font-bold text-green-600">+12%</p>
                </div>
              </div>
            </div>
          </div>

          {/* Tab Navigation */}
          <div className="border-b border-gray-200 dark:border-gray-700">
            <nav className="flex space-x-8">
              {tabs.map((tab) => {
                const Icon = tab.icon
                const isActive = activeTab === tab.id
                
                return (
                  <button
                    key={tab.id}
                    onClick={() => setActiveTab(tab.id)}
                    className={`relative flex items-center gap-3 py-4 px-1 border-b-2 font-medium text-sm transition-colors ${
                      isActive
                        ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                        : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 dark:text-gray-400 dark:hover:text-gray-300'
                    }`}
                  >
                    <Icon size={20} />
                    <div className="text-left">
                      <div className="flex items-center gap-2">
                        <span>{tab.label}</span>
                        <span className={`px-2 py-1 text-xs rounded-full ${
                          isActive
                            ? 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300'
                            : 'bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-400'
                        }`}>
                          {tab.count}
                        </span>
                      </div>
                      <p className="text-xs text-gray-500 dark:text-gray-400 mt-1 hidden sm:block">
                        {tab.description}
                      </p>
                    </div>

                    {/* Active indicator */}
                    {isActive && (
                      <motion.div
                        className="absolute bottom-0 left-0 right-0 h-0.5 bg-blue-500"
                        layoutId="activeTab"
                        initial={false}
                        transition={{ type: "spring", stiffness: 500, damping: 30 }}
                      />
                    )}
                  </button>
                )
              })}
            </nav>
          </div>

          {/* Tab Content */}
          <motion.div
            key={activeTab}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            transition={{ duration: 0.2 }}
            className="min-h-[600px]"
          >
            {activeTab === 'management' && <ReviewManagement />}
            {activeTab === 'analytics' && <ReviewAnalytics />}
          </motion.div>

          {/* Floating Action Hints */}
          <div className="fixed bottom-6 right-6 z-40">
            <div className="flex flex-col gap-3">
              {/* Review Management Hint */}
              {activeTab === 'management' && (
                <motion.div
                  initial={{ opacity: 0, scale: 0.8 }}
                  animate={{ opacity: 1, scale: 1 }}
                  className="bg-blue-600 text-white p-3 rounded-lg shadow-lg max-w-xs"
                >
                  <div className="flex items-center gap-2 mb-2">
                    <MessageCircle size={16} />
                    <span className="text-sm font-medium">Pro Tip</span>
                  </div>
                  <p className="text-xs leading-relaxed">
                    Respond to reviews within 24 hours to show customers you care. 
                    Use the bulk actions to approve multiple reviews at once.
                  </p>
                </motion.div>
              )}

              {/* Analytics Hint */}
              {activeTab === 'analytics' && (
                <motion.div
                  initial={{ opacity: 0, scale: 0.8 }}
                  animate={{ opacity: 1, scale: 1 }}
                  className="bg-green-600 text-white p-3 rounded-lg shadow-lg max-w-xs"
                >
                  <div className="flex items-center gap-2 mb-2">
                    <BarChart3 size={16} />
                    <span className="text-sm font-medium">Insights</span>
                  </div>
                  <p className="text-xs leading-relaxed">
                    Track trending keywords to understand what customers love most. 
                    Focus on classes with high ratings but low review rates.
                  </p>
                </motion.div>
              )}
            </div>
          </div>
        </div>
      </DashboardLayout>
    </ProtectedRoute>
  )
}