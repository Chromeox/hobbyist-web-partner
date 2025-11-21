/**
 * Forgot Password Form Component
 * Sends password reset email to user
 *
 * Security Features:
 * - Rate limiting (3 attempts per 15 minutes, 1 hour block)
 * - Email enumeration prevention (always shows success)
 * - Resend functionality with 60s cooldown
 */

'use client'

import React, { useState, useCallback, useEffect } from 'react'
import Link from 'next/link'
import { Mail, ArrowLeft, Loader2, CheckCircle, AlertCircle, Clock } from 'lucide-react'
import { supabase } from '@/lib/supabase'
import { passwordResetRateLimiter } from '@/lib/utils/rate-limit'

interface FormState {
  email: string
  isLoading: boolean
  error: string | null
  success: boolean
  canResend: boolean
  resendCooldown: number
}

export function ForgotPasswordForm() {
  const [state, setState] = useState<FormState>({
    email: '',
    isLoading: false,
    error: null,
    success: false,
    canResend: false,
    resendCooldown: 0
  })

  // Cooldown timer for resend button
  useEffect(() => {
    if (state.resendCooldown > 0) {
      const timer = setTimeout(() => {
        setState(prev => ({
          ...prev,
          resendCooldown: prev.resendCooldown - 1,
          canResend: prev.resendCooldown - 1 === 0
        }))
      }, 1000)
      return () => clearTimeout(timer)
    }
  }, [state.resendCooldown])

  const sendResetEmail = useCallback(async (email: string) => {
    // Check rate limit first
    const rateLimitResult = await passwordResetRateLimiter.check(email)

    if (!rateLimitResult.allowed) {
      const minutes = Math.ceil(rateLimitResult.retryAfter! / 60)
      setState(prev => ({
        ...prev,
        isLoading: false,
        error: `Too many attempts. Please try again in ${minutes} minute${minutes > 1 ? 's' : ''}.`
      }))
      return
    }

    // Send reset email - ALWAYS return success for security
    try {
      await supabase.auth.resetPasswordForEmail(email, {
        redirectTo: `${window.location.origin}/auth/callback?next=/auth/reset-password`
      })

      // Always show success - don't reveal if email exists
      setState(prev => ({
        ...prev,
        isLoading: false,
        success: true,
        error: null,
        canResend: false,
        resendCooldown: 60
      }))
    } catch (error: any) {
      // Even on error, show success to prevent email enumeration
      setState(prev => ({
        ...prev,
        isLoading: false,
        success: true,
        error: null,
        canResend: false,
        resendCooldown: 60
      }))
    }
  }, [])

  const handleSubmit = useCallback(async (e: React.FormEvent) => {
    e.preventDefault()

    if (!state.email) {
      setState(prev => ({ ...prev, error: 'Please enter your email address' }))
      return
    }

    setState(prev => ({ ...prev, isLoading: true, error: null }))
    await sendResetEmail(state.email)
  }, [state.email, sendResetEmail])

  const handleResend = useCallback(async () => {
    if (!state.canResend || state.isLoading) return

    setState(prev => ({ ...prev, isLoading: true, error: null }))
    await sendResetEmail(state.email)
  }, [state.canResend, state.email, state.isLoading, sendResetEmail])

  if (state.success) {
    return (
      <div className="w-full max-w-md">
        <div className="bg-white rounded-2xl shadow-xl p-8">
          <div className="text-center">
            <div className="mx-auto w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mb-4">
              <CheckCircle className="h-8 w-8 text-green-600" />
            </div>
            <h2 className="text-2xl font-bold text-gray-900 mb-2">Check Your Email</h2>
            <p className="text-gray-600 mb-6">
              We've sent a password reset link to <strong>{state.email}</strong>
            </p>
            <p className="text-sm text-gray-500 mb-6">
              Click the link in the email to reset your password. The link will expire in 1 hour.
            </p>

            {/* Resend button with cooldown */}
            <div className="mb-6">
              <button
                onClick={handleResend}
                disabled={!state.canResend || state.isLoading}
                className="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium text-blue-600 hover:text-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                {state.isLoading ? (
                  <>
                    <Loader2 className="h-4 w-4 animate-spin" />
                    Sending...
                  </>
                ) : !state.canResend && state.resendCooldown > 0 ? (
                  <>
                    <Clock className="h-4 w-4" />
                    Resend in {state.resendCooldown}s
                  </>
                ) : (
                  <>
                    <Mail className="h-4 w-4" />
                    Resend Email
                  </>
                )}
              </button>
              <p className="text-xs text-gray-400 mt-2">
                Didn't receive the email? Check your spam folder or click resend.
              </p>
            </div>

            <Link
              href="/auth/signin"
              className="inline-flex items-center gap-2 text-blue-600 hover:text-blue-700 font-medium"
            >
              <ArrowLeft className="h-4 w-4" />
              Back to Sign In
            </Link>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="w-full max-w-md">
      <div className="bg-white rounded-2xl shadow-xl p-8">
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">Reset Password</h1>
          <p className="text-gray-600">
            Enter your email address and we'll send you a link to reset your password
          </p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-6">
          {state.error && (
            <div className="bg-red-50 border border-red-200 rounded-lg p-4 flex items-start gap-3">
              <AlertCircle className="h-5 w-5 text-red-600 flex-shrink-0 mt-0.5" />
              <p className="text-sm text-red-800">{state.error}</p>
            </div>
          )}

          <div>
            <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-2">
              Email Address
            </label>
            <div className="relative">
              <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <Mail className="h-5 w-5 text-gray-400" />
              </div>
              <input
                id="email"
                name="email"
                type="email"
                autoComplete="email"
                required
                value={state.email}
                onChange={(e) => setState(prev => ({ ...prev, email: e.target.value }))}
                className="block w-full pl-10 pr-3 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="you@example.com"
                disabled={state.isLoading}
              />
            </div>
          </div>

          <button
            type="submit"
            disabled={state.isLoading}
            className="w-full flex items-center justify-center gap-2 px-4 py-3 border border-transparent text-base font-medium rounded-lg text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            {state.isLoading ? (
              <>
                <Loader2 className="h-5 w-5 animate-spin" />
                Sending...
              </>
            ) : (
              'Send Reset Link'
            )}
          </button>
        </form>

        <div className="mt-6 text-center">
          <Link
            href="/auth/signin"
            className="inline-flex items-center gap-2 text-sm text-gray-600 hover:text-gray-900"
          >
            <ArrowLeft className="h-4 w-4" />
            Back to Sign In
          </Link>
        </div>
      </div>

      <p className="mt-4 text-center text-sm text-gray-600">
        Don't have an account?{' '}
        <Link href="/auth/signup" className="font-medium text-blue-600 hover:text-blue-700">
          Sign up
        </Link>
      </p>
    </div>
  )
}
