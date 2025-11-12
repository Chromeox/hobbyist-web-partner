/**
 * OAuth Callback Route Handler
 * Handles OAuth redirects (Google, etc.)
 *
 * Note: Password reset now uses Supabase's native {{ .ConfirmationURL }} flow
 * and goes directly to /auth/reset-password (not through this route)
 */

import { NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

export async function GET(request: Request) {
  const requestUrl = new URL(request.url)
  const code = requestUrl.searchParams.get('code')
  const next = requestUrl.searchParams.get('next') || '/dashboard'

  console.log('=== AUTH CALLBACK EXECUTED ===', {
    url: requestUrl.href,
    hasCode: !!code,
    nextUrl: next
  })

  try {
    const supabase = await createClient()

    // OAuth code exchange flow
    if (code) {
      console.log('=== ATTEMPTING OAUTH CODE EXCHANGE ===')

      const { data, error } = await supabase.auth.exchangeCodeForSession(code)

      console.log('=== CODE EXCHANGE RESULT ===', {
        hasError: !!error,
        errorMessage: error?.message,
        hasSession: !!data?.session
      })

      if (error) {
        return NextResponse.redirect(
          new URL(`/auth/signin?error=oauth_failed&message=${encodeURIComponent(error.message)}`, requestUrl.origin)
        )
      }

      if (data.session) {
        console.log('=== OAUTH SUCCESS ===')
        return NextResponse.redirect(new URL(next, requestUrl.origin))
      }
    }

    // No valid parameters - fallback to client-side handler
    console.log('=== NO VALID PARAMETERS - REDIRECTING TO CLIENT HANDLER ===')
    return NextResponse.redirect(new URL('/auth/callback-handler', requestUrl.origin))

  } catch (err) {
    console.error('=== UNEXPECTED ERROR IN CALLBACK ===', err)
    return NextResponse.redirect(
      new URL('/auth/signin?error=callback_error&message=Unexpected error occurred', requestUrl.origin)
    )
  }
}
