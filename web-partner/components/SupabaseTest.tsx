'use client'

import { useEffect, useState } from 'react'
import { DataService, AuthService } from '../lib/services/data'
import { supabase } from '../lib/supabase'

export function SupabaseTest() {
  const [connected, setConnected] = useState<boolean | null>(null)
  const [stats, setStats] = useState<any>(null)
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    testConnection()
  }, [])

  const testConnection = async () => {
    try {
      setLoading(true)
      setError(null)

      // Always try real connection first, fall back to mock if needed
        // Test basic connection to real Supabase
        const { data, error: connectionError } = await supabase
          .from('categories')
          .select('count')
          .limit(1)

        if (connectionError) {
          throw connectionError
        }

        setConnected(true)

        // Try to get dashboard stats
        try {
          const dashboardStats = await DataService.getDashboardStats()
          setStats(dashboardStats)
        } catch (statsError) {
          console.warn('Could not fetch dashboard stats (tables may not exist yet):', statsError)
          setStats({ message: 'Connection successful, but tables may need to be created' })
        }
      }

    } catch (err: any) {
      console.error('Supabase connection test failed:', err)
      setConnected(false)
      setError(err.message || 'Connection failed')
    } finally {
      setLoading(false)
    }
  }

  const getStatusColor = () => {
    if (loading) return 'text-yellow-600'
    if (connected) return 'text-green-600'
    return 'text-red-600'
  }

  const getStatusText = () => {
    if (loading) return 'Testing connection...'
    if (connected) return 'Connected to Supabase ✓'
    return 'Connection failed ✗'
  }

  return (
    <div className="bg-white p-6 rounded-lg shadow-md border">
      <h3 className="text-lg font-semibold mb-4">Supabase Connection Test</h3>
      
      <div className={`font-medium ${getStatusColor()}`}>
        {getStatusText()}
      </div>

      {error && (
        <div className="mt-3 p-3 bg-red-50 border border-red-200 rounded">
          <p className="text-red-700 text-sm">
            <strong>Error:</strong> {error}
          </p>
          <p className="text-red-600 text-xs mt-1">
            Make sure to update your .env.local file with actual Supabase credentials
          </p>
        </div>
      )}

      {connected && stats && (
        <div className="mt-4 p-3 bg-green-50 border border-green-200 rounded">
          <p className="text-green-700 text-sm mb-2">
            <strong>Connection Details:</strong>
          </p>
          {stats.message ? (
            <p className="text-green-600 text-xs">{stats.message}</p>
          ) : (
            <div className="grid grid-cols-2 gap-2 text-xs">
              <div>Total Users: {stats.totalUsers}</div>
              <div>Total Instructors: {stats.totalInstructors}</div>
              <div>Total Classes: {stats.totalClasses}</div>
              <div>Total Bookings: {stats.totalBookings}</div>
              <div>Total Revenue: ${(stats.totalRevenue / 100).toFixed(2)}</div>
            </div>
          )}
        </div>
      )}

      <div className="mt-4 text-xs text-gray-500">
        <p><strong>Next steps:</strong></p>
        <ol className="list-decimal list-inside mt-1 space-y-1">
          <li>Update .env.local with your Supabase project URL and keys</li>
          <li>Run database migrations in your main Supabase project</li>
          <li>Deploy to Vercel with environment variables configured</li>
        </ol>
      </div>

      <button
        onClick={testConnection}
        disabled={loading}
        className="mt-3 px-4 py-2 bg-blue-600 text-white text-sm rounded hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
      >
        {loading ? 'Testing...' : 'Test Connection'}
      </button>
    </div>
  )
}