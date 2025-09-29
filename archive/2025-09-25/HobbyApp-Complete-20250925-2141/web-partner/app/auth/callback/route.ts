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
  const error = requestUrl.searchParams.get('error')
  const next = requestUrl.searchParams.get('next') || '/dashboard'

  console.log('OAuth callback received:', {
    code: code ? `${code.substring(0, 10)}...` : null,
    error,
    url: requestUrl.href
  })

  // Handle OAuth errors from provider
  if (error) {
    console.error('OAuth provider error:', error)
    return NextResponse.redirect(
      new URL(`/auth/signin?error=oauth_provider_error&message=${encodeURIComponent(error)}`, requestUrl.origin)
    )
  }

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

    try {
      const { data, error: exchangeError } = await supabase.auth.exchangeCodeForSession(code)

      console.log('Code exchange result:', {
        success: !exchangeError,
        error: exchangeError?.message,
        hasSession: !!data.session
      })

      if (!exchangeError && data.session) {
        // Successful authentication
        console.log('OAuth callback successful, redirecting to:', next)
        return NextResponse.redirect(new URL(next, requestUrl.origin))
      } else {
        console.error('Code exchange failed:', exchangeError)
        return NextResponse.redirect(
          new URL(`/auth/signin?error=session_exchange_failed&message=${encodeURIComponent(exchangeError?.message || 'Unknown error')}`, requestUrl.origin)
        )
      }
    } catch (err) {
      console.error('Unexpected error during code exchange:', err)
      return NextResponse.redirect(
        new URL('/auth/signin?error=auth_callback_error&message=Unexpected error', requestUrl.origin)
      )
    }
  }

  // No code provided - this might be an implicit flow (tokens in fragment)
  // For implicit flow, the client should handle the tokens
  console.log('No authorization code found, checking for implicit flow')

  // Create a redirect to a client-side handler
  return NextResponse.redirect(
    new URL('/auth/callback-handler', requestUrl.origin)
  )
}