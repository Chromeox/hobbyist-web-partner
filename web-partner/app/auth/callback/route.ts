/**
 * OAuth Callback Route Handler
 * Handles OAuth redirects from providers
 */

import { NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'
import type { Database } from '@/types/supabase'

export async function GET(request: Request) {
  const requestUrl = new URL(request.url)
  const code = requestUrl.searchParams.get('code')
  const next = requestUrl.searchParams.get('next') || '/dashboard'

  if (code) {
    const supabase = createClient<Database>(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    )

    const { error } = await supabase.auth.exchangeCodeForSession(code)

    if (!error) {
      // Redirect to the specified next URL or dashboard
      return NextResponse.redirect(new URL(next, requestUrl.origin))
    }
  }

  // Return to sign in page on error
  return NextResponse.redirect(
    new URL('/auth/signin?error=auth_callback_error', requestUrl.origin)
  )
}