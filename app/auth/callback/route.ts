/**
 * Auth Callback Route Handler
 * Handles both OAuth redirects and password reset recovery tokens
 *
 * OAuth Flow:
 *   - User redirected here with 'code' parameter from OAuth provider
 *   - Exchanges code for session using exchangeCodeForSession()
 *   - Redirects to dashboard or 'next' URL
 *
 * Password Reset Flow:
 *   - User clicks email link with 'token_hash' and 'type=recovery' parameters
 *   - Verifies recovery token using verifyOtp()
 *   - Establishes session and redirects to /auth/reset-password
 */

import { NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

export async function GET(request: Request) {
  const requestUrl = new URL(request.url)
  const code = requestUrl.searchParams.get('code')
  const token_hash = requestUrl.searchParams.get('token_hash')
  const type = requestUrl.searchParams.get('type')
  const next = requestUrl.searchParams.get('next') || '/dashboard'

  console.log('=== AUTH CALLBACK EXECUTED ===', {
    url: requestUrl.href,
    hasCode: !!code,
    hasTokenHash: !!token_hash,
    type,
    nextUrl: next
  })

  try {
    const supabase = await createClient()

    // Password reset / recovery token flow
    if (token_hash && type === 'recovery') {
      console.log('=== ATTEMPTING PASSWORD RESET TOKEN VERIFICATION ===')

      const { data, error } = await supabase.auth.verifyOtp({
        token_hash,
        type: 'recovery'
      })

      console.log('=== TOKEN VERIFICATION RESULT ===', {
        hasError: !!error,
        errorMessage: error?.message,
        hasSession: !!data?.session
      })

      if (error) {
        console.error('=== PASSWORD RESET TOKEN VERIFICATION FAILED ===', error)
        return NextResponse.redirect(
          new URL(`/auth/reset-password?error=invalid_token&message=${encodeURIComponent(error.message)}`, requestUrl.origin)
        )
      }

      if (data.session) {
        console.log('=== PASSWORD RESET TOKEN VERIFIED - SESSION ESTABLISHED ===')
        // Session is automatically established by verifyOtp
        // Redirect to reset password form
        return NextResponse.redirect(new URL('/auth/reset-password', requestUrl.origin))
      }
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
