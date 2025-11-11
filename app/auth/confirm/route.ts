/**
 * Password Reset Confirmation Route
 * Handles password reset links from Supabase emails
 * This is the standard Supabase pattern for recovery flows
 */

import { NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

export async function GET(request: Request) {
  const requestUrl = new URL(request.url)
  const token_hash = requestUrl.searchParams.get('token_hash')
  const type = requestUrl.searchParams.get('type')
  const next = '/auth/reset-password'

  console.log('Password reset confirmation received:', {
    hasTokenHash: !!token_hash,
    type,
    url: requestUrl.href
  })

  // Verify this is a recovery request
  if (token_hash && type === 'recovery') {
    const supabase = await createClient()

    try {
      // Exchange the token_hash for a session
      const { error } = await supabase.auth.verifyOtp({
        token_hash,
        type: 'recovery',
      })

      if (!error) {
        console.log('Recovery token verified successfully')
        // Redirect to reset password page - user now has valid session
        return NextResponse.redirect(new URL(next, requestUrl.origin))
      } else {
        console.error('Recovery token verification failed:', error)
        return NextResponse.redirect(
          new URL(`/auth/signin?error=recovery_failed&message=${encodeURIComponent(error.message)}`, requestUrl.origin)
        )
      }
    } catch (err) {
      console.error('Unexpected error during recovery:', err)
      return NextResponse.redirect(
        new URL('/auth/signin?error=recovery_error&message=Unexpected error', requestUrl.origin)
      )
    }
  }

  // Invalid request
  console.error('Invalid recovery request - missing token_hash or wrong type')
  return NextResponse.redirect(
    new URL('/auth/signin?error=invalid_recovery_link', requestUrl.origin)
  )
}
