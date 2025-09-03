/**
 * Revenue Reporting Page
 */

'use client'

import { ProtectedRoute } from '@/lib/components/ProtectedRoute'
import { useUserProfile } from '@/lib/hooks/useAuth'
import DashboardLayout from '../DashboardLayout'
import RevenueReporting from './RevenueReporting'

export default function RevenuePage() {
  const { profile, isLoading } = useUserProfile()

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
          <p className="mt-4 text-gray-600">Loading revenue data...</p>
        </div>
      </div>
    )
  }

  return (
    <ProtectedRoute>
      <DashboardLayout 
        studioName={profile?.instructor?.businessName || "Studio"} 
        userName={`${profile?.profile?.firstName || ''} ${profile?.profile?.lastName || ''}`.trim() || 'User'}
      >
        <RevenueReporting />
      </DashboardLayout>
    </ProtectedRoute>
  )
}