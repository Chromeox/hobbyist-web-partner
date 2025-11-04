/**
 * Dashboard Main Page
 * Authenticated route showing studio overview
 */

'use client'

import { ProtectedRoute } from '@/lib/components/ProtectedRoute'
import { useUserProfile } from '@/lib/hooks/useAuth'
import DashboardLayout from './DashboardLayout'
import DashboardOverview from './DashboardOverview'

export default function DashboardPage() {
  const { profile, isLoading } = useUserProfile()

  const studioId =
    profile?.instructor?.studioId ||
    profile?.instructor?.studio_id ||
    profile?.instructor?.id ||
    'demo-studio-id'

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
          <p className="mt-4 text-gray-600">Loading dashboard...</p>
        </div>
      </div>
    )
  }

  return (
    <ProtectedRoute>
      <DashboardLayout 
        studioName={profile?.instructor?.businessName || profile?.profile?.business_name || "Studio"} 
        userName={`${profile?.profile?.firstName || profile?.profile?.first_name || ''} ${profile?.profile?.lastName || profile?.profile?.last_name || ''}`.trim() || profile?.email || 'User'}
      >
        <DashboardOverview studioId={studioId} />
      </DashboardLayout>
    </ProtectedRoute>
  )
}