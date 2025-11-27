import { createBrowserClient } from '@supabase/ssr'
import type { Database } from '../types/supabase'

// Temporarily using untyped client to resolve type mismatches during modernization
// Lazy initialization to avoid build-time evaluation
let _supabaseInstance: ReturnType<typeof createBrowserClient> | null = null

export const getSupabase = () => {
  if (!_supabaseInstance) {
    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || ''
    const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || ''
    _supabaseInstance = createBrowserClient(supabaseUrl, supabaseAnonKey)
  }
  return _supabaseInstance
}

// Backward compatibility - lazy proxy
export const supabase = new Proxy({} as ReturnType<typeof createBrowserClient>, {
  get(_target, prop) {
    return getSupabase()[prop as keyof ReturnType<typeof createBrowserClient>]
  }
})

// Browser client factory (alias for components that need fresh client)
export const createBrowserSupabaseClient = () => {
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || ''
  const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || ''
  return createBrowserClient(supabaseUrl, supabaseAnonKey)
}

// Server-side client for API routes (if needed)
export const createServiceSupabase = () => {
  const { createClient } = require('@supabase/supabase-js')
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL || '',
    process.env.SUPABASE_SERVICE_ROLE_KEY || '',
    {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    }
  )
}