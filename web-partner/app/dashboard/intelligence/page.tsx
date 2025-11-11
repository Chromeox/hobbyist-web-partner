/**
 * Studio Intelligence Dashboard Page
 * Smart recommendations based on imported calendar data
 */

'use client'

import { ProtectedRoute } from '@/lib/components/ProtectedRoute'
import { useUserProfile } from '@/lib/hooks/useAuth'
import DashboardLayout from '../DashboardLayout'
import StudioIntelligenceDashboard from '@/components/studio/StudioIntelligenceDashboard'
import CalendarImportWidget from '@/components/studio/CalendarImportWidget'
import SetupReminders from '@/components/dashboard/SetupReminders'
import { useState, useEffect } from 'react'
import { toast } from 'sonner'

export default function IntelligencePage() {
  const { profile, isLoading } = useUserProfile()
  const [actionInProgress, setActionInProgress] = useState(false)
  const [showImportWidget, setShowImportWidget] = useState(false)
  const [hasCalendarData, setHasCalendarData] = useState(false)

  // Check URL params for setup mode
  useEffect(() => {
    const urlParams = new URLSearchParams(window.location.search)
    const setupMode = urlParams.get('setup')
    if (setupMode === 'calendar') {
      setShowImportWidget(true)
    }
  }, [])

  const handleIntelligenceAction = async (actionType: string, data: any) => {
    setActionInProgress(true)

    try {
      switch (actionType) {
        case 'optimize_time_slot':
          // In production, this would integrate with the WorkshopScheduler
          toast.success(`Time slot optimization applied: ${data.day_of_week} at ${data.hour}:00`)
          console.log('Time slot action:', data)
          break

        case 'optimize_room':
          // In production, this would update room scheduling
          toast.success(`Room optimization scheduled for ${data.room_name}`)
          console.log('Room optimization:', data)
          break

        case 'optimize_instructor':
          // In production, this would suggest instructor schedule changes
          toast.success(`Instructor optimization plan created for ${data.instructor_name}`)
          console.log('Instructor optimization:', data)
          break

        case 'adjust_capacity':
          // In production, this would update class templates
          toast.success(`Capacity adjustment applied to ${data.category} classes`)
          console.log('Capacity adjustment:', data)
          break

        default:
          toast.info('Action recorded for review')
          console.log('Unknown action:', actionType, data)
      }
    } catch (error) {
      toast.error('Failed to apply optimization. Please try again.')
      console.error('Action error:', error)
    } finally {
      setActionInProgress(false)
    }
  }

  const handleImportComplete = (provider: string) => {
    setHasCalendarData(true)
    setShowImportWidget(false)
    toast.success(`${provider} calendar connected! Generating insights...`)
    // Clean up URL params
    window.history.replaceState({}, '', window.location.pathname)
  }

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
          <p className="mt-4 text-gray-600">Loading Smart Calendar...</p>
        </div>
      </div>
    )
  }

  const studioId = profile?.studio?.id || 'demo-studio-id'

  return (
    <ProtectedRoute>
      <DashboardLayout
        studioName={profile?.instructor?.businessName || profile?.profile?.business_name || "Studio"}
        userName={`${profile?.profile?.firstName || profile?.profile?.first_name || ''} ${profile?.profile?.lastName || profile?.profile?.last_name || ''}`.trim() || profile?.email || 'User'}
      >
        <div className="space-y-6">
          <div className="flex justify-between items-center">
            <div>
              <h1 className="text-2xl font-bold text-gray-900">Smart Calendar</h1>
              <p className="text-gray-600 mt-1">
                Google Calendar integration with smart recommendations to optimize your studio operations
              </p>
            </div>
          </div>

          {/* Setup Reminders - Calendar Integration Prompt */}
          <SetupReminders className="mb-6" />

          {/* Calendar Import Widget - Show if no data or setup mode */}
          {(showImportWidget || !hasCalendarData) && (
            <CalendarImportWidget
              onImportComplete={handleImportComplete}
              highlightSetup={showImportWidget}
              className="mb-6"
            />
          )}

          <StudioIntelligenceDashboard
            studioId={studioId}
            onActionClick={handleIntelligenceAction}
            refreshInterval={3600} // Refresh every hour
            className="w-full"
          />

          {/* Help Section */}
          <div className="bg-blue-50 border border-blue-200 rounded-lg p-6">
            <h2 className="text-lg font-semibold text-blue-900 mb-2">How Smart Calendar Works</h2>
            <div className="grid md:grid-cols-2 gap-4 text-sm text-blue-800">
              <div>
                <h3 className="font-medium mb-1">📊 Data Analysis</h3>
                <p>We analyze your imported calendar data to identify patterns in booking success, room utilization, and instructor performance.</p>
              </div>
              <div>
                <h3 className="font-medium mb-1">🎯 Smart Recommendations</h3>
                <p>Get actionable insights like optimal time slots, room efficiency improvements, and capacity adjustments.</p>
              </div>
              <div>
                <h3 className="font-medium mb-1">💡 One-Click Actions</h3>
                <p>Apply recommendations directly to your workshop scheduler and class templates with confidence scoring.</p>
              </div>
              <div>
                <h3 className="font-medium mb-1">📈 Revenue Optimization</h3>
                <p>Focus on changes that have the highest potential for increasing weekly revenue and studio efficiency.</p>
              </div>
            </div>
          </div>
        </div>
      </DashboardLayout>
    </ProtectedRoute>
  )
}