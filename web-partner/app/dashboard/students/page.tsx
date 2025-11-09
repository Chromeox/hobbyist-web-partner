/**
 * Students Management Page
 */

'use client'

import { ProtectedRoute } from '@/lib/components/ProtectedRoute'
import { useUserProfile } from '@/lib/hooks/useAuth'
import DashboardLayout from '../DashboardLayout'
import StudentManagement from './StudentManagement'
import LoadingState, { LoadingStates } from '@/components/ui/LoadingState'

export default function StudentsPage() {
  const { profile, isLoading } = useUserProfile()

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <LoadingState 
          message={LoadingStates.students.message}
          description={LoadingStates.students.description}
          size="lg"
        />
      </div>
    )
  }

  return (
    <ProtectedRoute>
      <DashboardLayout 
        studioName={profile?.instructor?.businessName || "Studio"} 
        userName={`${profile?.profile?.firstName || ''} ${profile?.profile?.lastName || ''}`.trim() || 'User'}
      >
        <StudentManagement />
      </DashboardLayout>
    </ProtectedRoute>
  )
}