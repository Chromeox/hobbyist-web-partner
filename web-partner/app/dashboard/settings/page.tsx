/**
 * Settings Management Page
 */

'use client'

import { ProtectedRoute } from '@/lib/components/ProtectedRoute'
import { useUserProfile } from '@/lib/hooks/useAuth'
import DashboardLayout from '../DashboardLayout'
// import SettingsManagement from './SettingsManagement'

export default function SettingsPage() {
  const { profile, isLoading } = useUserProfile()

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
          <p className="mt-4 text-gray-600">Loading settings...</p>
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
        <div className="p-6">
          <h1 className="text-2xl font-bold">Settings</h1>
          <p className="text-gray-600 mt-2">Settings management coming soon...</p>
        </div>
      </DashboardLayout>
    </ProtectedRoute>
  )
}