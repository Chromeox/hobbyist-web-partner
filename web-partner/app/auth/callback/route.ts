/**
 * OAuth Callback Route Handler
 * Handles OAuth redirects and password reset links
 */

import { NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'
import { cookies } from 'next/headers'

export async function GET(request: Request) {
  const requestUrl = new URL(request.url)
  const token_hash = requestUrl.searchParams.get('token_hash')
  const type = requestUrl.searchParams.get('type')
  const code = requestUrl.searchParams.get('code')
  const next = requestUrl.searchParams.get('next') || '/dashboard'

  // CRITICAL: This log MUST appear in production console
  console.log('=== AUTH CALLBACK EXECUTED ===', {
    url: requestUrl.href,
    hasTokenHash: !!token_hash,
    hasCode: !!code,
    type,
    nextUrl: next
  })

  try {
    const supabase = await createClient()

    // Password reset flow (token_hash + type=recovery)
    if (token_hash && type === 'recovery') {
      console.log('=== ATTEMPTING PASSWORD RESET VERIFICATION ===')

      const { data, error } = await supabase.auth.verifyOtp({
        token_hash,
        type: 'recovery'
      })

      console.log('=== VERIFY OTP RESULT ===', {
        hasError: !!error,
        errorMessage: error?.message,
        errorCode: error?.code,
        hasSession: !!data?.session,
        hasUser: !!data?.user
      })

      if (error) {
        console.error('=== PASSWORD RESET FAILED ===', error)
        return NextResponse.redirect(
          new URL(`/auth/signin?error=${error.code || 'verification_failed'}&message=${encodeURIComponent(error.message)}`, requestUrl.origin)
        )
      }

      if (data.session) {
        console.log('=== PASSWORD RESET SUCCESS ===', {
          userId: data.user?.id,
          email: data.user?.email,
          redirectTo: next
        })

        // Create response with redirect
        const response = NextResponse.redirect(new URL(next, requestUrl.origin))

        // Ensure cookies are properly set by refreshing the session
        // The createClient() function should have already set the cookies,
        // but we verify the session is accessible
        const { data: { session: verifySession } } = await supabase.auth.getSession()
        console.log('=== SESSION VERIFICATION BEFORE REDIRECT ===', {
          hasSession: !!verifySession,
          sessionId: verifySession?.access_token?.substring(0, 10) + '...'
        })

        return response
      }

      console.error('=== NO SESSION CREATED ===')
      return NextResponse.redirect(
        new URL('/auth/signin?error=no_session&message=Could not establish reset session', requestUrl.origin)
      )
    }

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
