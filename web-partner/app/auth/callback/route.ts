/**
 * OAuth Callback Route Handler
 * Handles OAuth redirects from providers
 */

import { NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'
import type { Database } from '@/types/supabase'

export async function GET(request: Request) {
  const requestUrl = new URL(request.url)
  const code = requestUrl.searchParams.get('code')
  const error = requestUrl.searchParams.get('error')
  const error_code = requestUrl.searchParams.get('error_code')
  const error_description = requestUrl.searchParams.get('error_description')
  const token_hash = requestUrl.searchParams.get('token_hash')
  const type = requestUrl.searchParams.get('type')
  const next = requestUrl.searchParams.get('next') || '/dashboard'

  console.log('Auth callback received:', {
    code: code ? `${code.substring(0, 10)}...` : null,
    token_hash: token_hash ? `${token_hash.substring(0, 10)}...` : null,
    type,
    error,
    error_code,
    url: requestUrl.href
  })

  // Handle OAuth errors from provider
  if (error || error_code) {
    console.error('Auth provider error:', { error, error_code, error_description })

    // Handle specific error codes
    if (error_code === 'otp_expired') {
      return NextResponse.redirect(
        new URL(`/auth/signin?error=link_expired&message=${encodeURIComponent('This link has expired. Please request a new one.')}`, requestUrl.origin)
      )
    }

    return NextResponse.redirect(
      new URL(`/auth/signin?error=${error || error_code}&message=${encodeURIComponent(error_description || 'Authentication failed')}`, requestUrl.origin)
    )
  }

  // Use server client that properly sets cookies
  const supabase = await createClient()

  // Handle email magic link verification (token_hash flow)
  if (token_hash && type) {
    console.log('Processing email magic link:', { type })

    try {
      const { data, error: verifyError } = await supabase.auth.verifyOtp({
        token_hash,
        type: type as any
      })

      console.log('Email magic link verification result:', {
        success: !verifyError,
        error: verifyError?.message,
        hasSession: !!data.session
      })

      if (!verifyError && data.session) {
        console.log('Email verification successful, redirecting to:', next)
        return NextResponse.redirect(new URL(next, requestUrl.origin))
      } else {
        console.error('Email verification failed:', verifyError)
        return NextResponse.redirect(
          new URL(`/auth/signin?error=verification_failed&message=${encodeURIComponent(verifyError?.message || 'Email verification failed')}`, requestUrl.origin)
        )
      }
    } catch (err) {
      console.error('Unexpected error during email verification:', err)
      return NextResponse.redirect(
        new URL('/auth/signin?error=verification_error&message=Unexpected error during verification', requestUrl.origin)
      )
    }
  }

  // Handle OAuth code exchange
  if (code) {
    try {
      const { data, error: exchangeError } = await supabase.auth.exchangeCodeForSession(code)

      console.log('Code exchange result:', {
        success: !exchangeError,
        error: exchangeError?.message,
        hasSession: !!data.session
      })

      if (!exchangeError && data.session) {
        // Successful authentication - cookies are automatically set by server client
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

  // No code or token_hash provided - this might be an implicit flow (tokens in fragment)
  // For implicit flow, the client should handle the tokens
  console.log('No authorization code or token hash found, checking for implicit flow')

  // Create a redirect to a client-side handler
  return NextResponse.redirect(
    new URL('/auth/callback-handler', requestUrl.origin)
  )
}