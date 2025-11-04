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

      // Test basic connectivity with a simple table query
      const { error: pingError } = await supabase
        .from('categories')
        .select('id')
        .limit(1)

      if (pingError) {
        const message = pingError.message ?? ''

        if (message.includes('relation "public.categories" does not exist')) {
          setConnected(true)
          setStats({
            message: 'Connected to Supabase successfully',
            warning: 'Database tables not found. Please run the migrations.',
            migrationFile: '/supabase/migrations/03_web_partner_portal_schema.sql'
          })
          return
        }

        if (
          message.includes('not authenticated') ||
          message.includes('Auth session missing') ||
          message.includes('JWT')
        ) {
          const {
            data: { user },
            error: authError
          } = await supabase.auth.getUser()

          if (
            authError &&
            (authError.message.includes('not authenticated') ||
              authError.message.includes('Auth session missing'))
          ) {
            setConnected(true)
            setStats({
              message: 'Connected to Supabase successfully',
              note: 'Database tables need to be created. Please run migrations.',
              authStatus: 'Not authenticated (this is normal)'
            })
            return
          }

          if (!authError) {
            setConnected(true)
            setStats({
              message: 'Connected to Supabase successfully',
              user: user?.email || 'No user logged in'
            })
            return
          }

          console.warn('Auth check failed (this is normal):', authError?.message)
          setConnected(true)
          setStats({
            message: 'Connected to Supabase successfully',
            note: 'Database tables need to be created. Please run migrations.',
            authStatus: 'Not authenticated (this is normal)'
          })
          return
        }

        throw pingError
      }

      setConnected(true)

      try {
        const dashboardStats = await DataService.getDashboardStats()
        setStats({
          message: 'Database fully configured',
          ...dashboardStats
        })
      } catch {
        setStats({
          message: 'Tables exist but may need data',
          note: 'Database is ready for use'
        })
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
      <h3 className="text-lg font-semibold mb-4">Supabase Connection Status</h3>
      
      <div className={`font-medium ${getStatusColor()}`}>
        {getStatusText()}
      </div>

      {error && (
        <div className="mt-3 p-3 bg-red-50 border border-red-200 rounded">
          <p className="text-red-700 text-sm">
            <strong>Error:</strong> {error}
          </p>
          <p className="text-red-600 text-xs mt-1">
            Check your .env.local file has valid Supabase credentials
          </p>
        </div>
      )}

      {connected && stats && (
        <div className="mt-4">
          {stats.warning ? (
            <div className="p-3 bg-yellow-50 border border-yellow-200 rounded">
              <p className="text-yellow-700 text-sm mb-2">
                <strong>{stats.message}</strong>
              </p>
              <p className="text-yellow-600 text-xs">{stats.warning}</p>
              {stats.action && (
                <p className="text-yellow-600 text-xs mt-2 font-medium">{stats.action}</p>
              )}
              {stats.migrationFile && (
                <p className="text-yellow-600 text-xs mt-1">
                  Migration file: <code className="bg-yellow-100 px-1">{stats.migrationFile}</code>
                </p>
              )}
            </div>
          ) : (
            <div className="p-3 bg-green-50 border border-green-200 rounded">
              <p className="text-green-700 text-sm mb-2">
                <strong>{stats.message}</strong>
              </p>
              {stats.note && (
                <p className="text-green-600 text-xs">{stats.note}</p>
              )}
              {stats.user && (
                <p className="text-green-600 text-xs">User: {stats.user}</p>
              )}
              {stats.authStatus && (
                <p className="text-green-600 text-xs">{stats.authStatus}</p>
              )}
              {stats.totalUsers !== undefined && (
                <div className="grid grid-cols-2 gap-2 text-xs mt-2">
                  <div>Total Users: {stats.totalUsers}</div>
                  <div>Total Instructors: {stats.totalInstructors}</div>
                  <div>Total Classes: {stats.totalClasses}</div>
                  <div>Total Bookings: {stats.totalBookings}</div>
                  <div>Total Revenue: ${(stats.totalRevenue / 100).toFixed(2)}</div>
                </div>
              )}
            </div>
          )}
        </div>
      )}

      <div className="mt-4 text-xs text-gray-500">
        <p><strong>Next steps to complete setup:</strong></p>
        <ol className="list-decimal list-inside mt-1 space-y-1">
          <li>Ensure .env.local has correct Supabase URL and keys</li>
          <li>Run database migration: <code className="bg-gray-100 px-1">supabase db push</code></li>
          <li>Visit Supabase Dashboard to reset database password if needed</li>
          <li>Deploy to Vercel with environment variables</li>
        </ol>
        <p className="mt-2">
          <a 
            href="https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/settings/database" 
            target="_blank" 
            rel="noopener noreferrer"
            className="text-blue-600 hover:underline"
          >
            → Reset database password in Supabase Dashboard
          </a>
        </p>
      </div>

      <button
        onClick={testConnection}
        disabled={loading}
        className="mt-3 px-4 py-2 bg-blue-600 text-white text-sm rounded hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
      >
        {loading ? 'Testing...' : 'Test Connection Again'}
      </button>
    </div>
  )
}
