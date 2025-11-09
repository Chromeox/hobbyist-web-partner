/**
 * Studio Approval Admin Page
 * Admin-only access for approving new studio applications
 */

'use client'

import { ProtectedRoute } from '@/lib/components/ProtectedRoute'
import { useUserProfile } from '@/lib/hooks/useAuth'
import DashboardLayout from '../../DashboardLayout'
import StudioApprovalDashboard from '@/components/admin/StudioApprovalDashboard'
import { useAuthContext } from '@/lib/context/AuthContext'
import { isAdmin } from '@/lib/utils/roleUtils'
import { useRouter } from 'next/navigation'
import { useEffect } from 'react'

export default function StudioApprovalPage() {
  const { profile, isLoading } = useUserProfile()
  const { user } = useAuthContext()
  const router = useRouter()

  // Redirect non-admin users
  useEffect(() => {
    if (!isLoading && !isAdmin(user)) {
      router.push('/dashboard')
    }
  }, [user, isLoading, router])

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
          <p className="mt-4 text-gray-600">Loading studio approval dashboard...</p>
        </div>
      </div>
    )
  }

  // Show access denied for non-admin users
  if (!isAdmin(user)) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="text-center">
          <div className="text-6xl text-gray-400 mb-4">🔒</div>
          <h1 className="text-2xl font-bold text-gray-900 mb-2">Access Denied</h1>
          <p className="text-gray-600 mb-4">You need administrator privileges to access this page.</p>
          <button
            onClick={() => router.push('/dashboard')}
            className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
          >
            Return to Dashboard
          </button>
        </div>
      </div>
    )
  }

  return (
    <ProtectedRoute>
      <DashboardLayout
        studioName={profile?.instructor?.businessName || "Hobbyist Admin"}
        userName={`${profile?.profile?.firstName || ''} ${profile?.profile?.lastName || ''}`.trim() || profile?.email || 'Admin'}
      >
        <div className="space-y-6">
          <div className="flex justify-between items-center">
            <div>
              <h1 className="text-2xl font-bold text-gray-900">Studio Approval</h1>
              <p className="text-gray-600 mt-1">
                Review and approve new studio applications for the Hobbyist platform
              </p>
            </div>
            <div className="bg-purple-100 text-purple-800 px-3 py-1 rounded-full text-sm font-medium">
              Admin Only
            </div>
          </div>

          <StudioApprovalDashboard />
        </div>
      </DashboardLayout>
    </ProtectedRoute>
  )
}