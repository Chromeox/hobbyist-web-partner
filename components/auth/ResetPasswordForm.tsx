/**
 * Reset Password Form Component (Clerk)
 * Allows users to verify their reset code and set a new password
 *
 * Flow:
 * 1. User receives code via email (from ForgotPasswordForm)
 * 2. User enters code on this page
 * 3. Code is verified, then user sets new password
 */

'use client'

import React, { useState, useCallback, lazy, Suspense } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import Link from 'next/link'
import { useSignIn } from '@clerk/nextjs'
import { Lock, Loader2, CheckCircle, AlertCircle, Eye, EyeOff, Mail, KeyRound } from 'lucide-react'

// Lazy load password strength bar to reduce bundle size
const PasswordStrengthBar = lazy(() => import('react-password-strength-bar'))

type Step = 'code' | 'password' | 'success'

interface FormState {
  code: string
  password: string
  confirmPassword: string
  showPassword: boolean
  showConfirmPassword: boolean
  isLoading: boolean
  error: string | null
  step: Step
}

export function ResetPasswordForm() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const { isLoaded, signIn, setActive } = useSignIn()

  // Get email from URL params (passed from ForgotPasswordForm)
  const emailFromParams = searchParams.get('email') || ''

  const [state, setState] = useState<FormState>({
    code: '',
    password: '',
    confirmPassword: '',
    showPassword: false,
    showConfirmPassword: false,
    isLoading: false,
    error: null,
    step: 'code'
  })

  // Handle code verification
  const handleVerifyCode = useCallback(async (e: React.FormEvent) => {
    e.preventDefault()

    if (!isLoaded || !signIn) return

    if (!state.code || state.code.length !== 6) {
      setState(prev => ({ ...prev, error: 'Please enter the 6-digit code from your email' }))
      return
    }

    setState(prev => ({ ...prev, isLoading: true, error: null }))

    try {
      // Attempt to verify the reset code
      const result = await signIn.attemptFirstFactor({
        strategy: 'reset_password_email_code',
        code: state.code,
      })

      if (result.status === 'needs_new_password') {
        // Code verified, move to password step
        setState(prev => ({
          ...prev,
          isLoading: false,
          step: 'password',
          error: null
        }))
      } else {
        setState(prev => ({
          ...prev,
          isLoading: false,
          error: 'Invalid code. Please check your email and try again.'
        }))
      }
    } catch (error: any) {
      let errorMessage = 'Failed to verify code. Please try again.'

      if (error.errors?.[0]?.code === 'form_code_incorrect') {
        errorMessage = 'Incorrect code. Please check your email and try again.'
      } else if (error.errors?.[0]?.code === 'verification_expired') {
        errorMessage = 'Code has expired. Please request a new reset link.'
      } else if (error.errors?.[0]?.code === 'too_many_requests') {
        errorMessage = 'Too many attempts. Please wait a few minutes.'
      }

      setState(prev => ({
        ...prev,
        isLoading: false,
        error: errorMessage
      }))
    }
  }, [isLoaded, signIn, state.code])

  // Handle password reset
  const handleResetPassword = useCallback(async (e: React.FormEvent) => {
    e.preventDefault()

    if (!isLoaded || !signIn) return

    // Validation
    if (!state.password || !state.confirmPassword) {
      setState(prev => ({ ...prev, error: 'Please fill in all fields' }))
      return
    }

    if (state.password.length < 8) {
      setState(prev => ({ ...prev, error: 'Password must be at least 8 characters long' }))
      return
    }

    if (state.password !== state.confirmPassword) {
      setState(prev => ({ ...prev, error: 'Passwords do not match' }))
      return
    }

    setState(prev => ({ ...prev, isLoading: true, error: null }))

    try {
      const result = await signIn.resetPassword({
        password: state.password,
      })

      if (result.status === 'complete') {
        // Set the active session
        await setActive({ session: result.createdSessionId })

        setState(prev => ({
          ...prev,
          isLoading: false,
          step: 'success',
          error: null
        }))

        // Redirect to dashboard after 2 seconds
        setTimeout(() => {
          router.push('/dashboard')
        }, 2000)
      } else {
        setState(prev => ({
          ...prev,
          isLoading: false,
          error: 'Failed to reset password. Please try again.'
        }))
      }
    } catch (error: any) {
      let errorMessage = 'Failed to reset password. Please try again.'

      if (error.errors?.[0]?.message) {
        errorMessage = error.errors[0].message
      }

      setState(prev => ({
        ...prev,
        isLoading: false,
        error: errorMessage
      }))
    }
  }, [isLoaded, signIn, setActive, state.password, state.confirmPassword, router])

  // Success state
  if (state.step === 'success') {
    return (
      <div className="w-full max-w-md">
        <div className="bg-white rounded-2xl shadow-xl p-8">
          <div className="text-center">
            <div className="mx-auto w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mb-4">
              <CheckCircle className="h-8 w-8 text-green-600" />
            </div>
            <h2 className="text-2xl font-bold text-gray-900 mb-2">Password Reset Successful!</h2>
            <p className="text-gray-600 mb-6">
              Your password has been updated. Redirecting you to the dashboard...
            </p>
            <div className="flex items-center justify-center gap-2 text-blue-600">
              <Loader2 className="h-4 w-4 animate-spin" />
              <span className="text-sm">Redirecting...</span>
            </div>
          </div>
        </div>
      </div>
    )
  }

  // Password entry step
  if (state.step === 'password') {
    return (
      <div className="w-full max-w-md">
        <div className="bg-white rounded-2xl shadow-xl p-8">
          <div className="text-center mb-8">
            <div className="mx-auto w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mb-4">
              <Lock className="h-8 w-8 text-blue-600" />
            </div>
            <h1 className="text-3xl font-bold text-gray-900 mb-2">Set New Password</h1>
            <p className="text-gray-600">
              Enter your new password below
            </p>
          </div>

          <form onSubmit={handleResetPassword} className="space-y-6">
            {state.error && (
              <div className="bg-red-50 border border-red-200 rounded-lg p-4 flex items-start gap-3">
                <AlertCircle className="h-5 w-5 text-red-600 flex-shrink-0 mt-0.5" />
                <p className="text-sm text-red-800">{state.error}</p>
              </div>
            )}

            <div>
              <label htmlFor="password" className="block text-sm font-medium text-gray-700 mb-2">
                New Password
              </label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <Lock className="h-5 w-5 text-gray-400" />
                </div>
                <input
                  id="password"
                  name="password"
                  type={state.showPassword ? 'text' : 'password'}
                  autoComplete="new-password"
                  required
                  value={state.password}
                  onChange={(e) => setState(prev => ({ ...prev, password: e.target.value }))}
                  className="block w-full pl-10 pr-10 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="Enter new password"
                  disabled={state.isLoading || !isLoaded}
                />
                <button
                  type="button"
                  onClick={() => setState(prev => ({ ...prev, showPassword: !prev.showPassword }))}
                  className="absolute inset-y-0 right-0 pr-3 flex items-center"
                >
                  {state.showPassword ? (
                    <EyeOff className="h-5 w-5 text-gray-400 hover:text-gray-600" />
                  ) : (
                    <Eye className="h-5 w-5 text-gray-400 hover:text-gray-600" />
                  )}
                </button>
              </div>
              {state.password && (
                <div className="mt-2">
                  <Suspense fallback={<div className="h-2 bg-gray-200 rounded animate-pulse" />}>
                    <PasswordStrengthBar
                      password={state.password}
                      minLength={8}
                      scoreWords={['very weak', 'weak', 'okay', 'good', 'strong']}
                      shortScoreWord="too short"
                    />
                  </Suspense>
                </div>
              )}
              <p className="mt-1 text-xs text-gray-500">Must be at least 8 characters</p>
            </div>

            <div>
              <label htmlFor="confirmPassword" className="block text-sm font-medium text-gray-700 mb-2">
                Confirm New Password
              </label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <Lock className="h-5 w-5 text-gray-400" />
                </div>
                <input
                  id="confirmPassword"
                  name="confirmPassword"
                  type={state.showConfirmPassword ? 'text' : 'password'}
                  autoComplete="new-password"
                  required
                  value={state.confirmPassword}
                  onChange={(e) => setState(prev => ({ ...prev, confirmPassword: e.target.value }))}
                  className="block w-full pl-10 pr-10 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="Confirm new password"
                  disabled={state.isLoading || !isLoaded}
                />
                <button
                  type="button"
                  onClick={() => setState(prev => ({ ...prev, showConfirmPassword: !prev.showConfirmPassword }))}
                  className="absolute inset-y-0 right-0 pr-3 flex items-center"
                >
                  {state.showConfirmPassword ? (
                    <EyeOff className="h-5 w-5 text-gray-400 hover:text-gray-600" />
                  ) : (
                    <Eye className="h-5 w-5 text-gray-400 hover:text-gray-600" />
                  )}
                </button>
              </div>
            </div>

            <button
              type="submit"
              disabled={state.isLoading || !isLoaded}
              className="w-full flex items-center justify-center gap-2 px-4 py-3 border border-transparent text-base font-medium rounded-lg text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              {state.isLoading ? (
                <>
                  <Loader2 className="h-5 w-5 animate-spin" />
                  Resetting Password...
                </>
              ) : (
                'Reset Password'
              )}
            </button>
          </form>
        </div>

        <p className="mt-4 text-center text-sm text-gray-600">
          Remember your password?{' '}
          <Link href="/auth/signin" className="font-medium text-blue-600 hover:text-blue-700">
            Sign in
          </Link>
        </p>
      </div>
    )
  }

  // Code verification step (default)
  return (
    <div className="w-full max-w-md">
      <div className="bg-white rounded-2xl shadow-xl p-8">
        <div className="text-center mb-8">
          <div className="mx-auto w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mb-4">
            <KeyRound className="h-8 w-8 text-blue-600" />
          </div>
          <h1 className="text-3xl font-bold text-gray-900 mb-2">Enter Reset Code</h1>
          <p className="text-gray-600">
            Enter the 6-digit code sent to{' '}
            {emailFromParams ? (
              <strong>{emailFromParams}</strong>
            ) : (
              'your email'
            )}
          </p>
        </div>

        <form onSubmit={handleVerifyCode} className="space-y-6">
          {state.error && (
            <div className="bg-red-50 border border-red-200 rounded-lg p-4 flex items-start gap-3">
              <AlertCircle className="h-5 w-5 text-red-600 flex-shrink-0 mt-0.5" />
              <p className="text-sm text-red-800">{state.error}</p>
            </div>
          )}

          <div>
            <label htmlFor="code" className="block text-sm font-medium text-gray-700 mb-2">
              Verification Code
            </label>
            <div className="relative">
              <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <Mail className="h-5 w-5 text-gray-400" />
              </div>
              <input
                id="code"
                name="code"
                type="text"
                inputMode="numeric"
                pattern="[0-9]*"
                autoComplete="one-time-code"
                required
                maxLength={6}
                value={state.code}
                onChange={(e) => {
                  const value = e.target.value.replace(/\D/g, '').slice(0, 6)
                  setState(prev => ({ ...prev, code: value }))
                }}
                className="block w-full pl-10 pr-3 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent text-center text-xl tracking-[0.5em] font-mono"
                placeholder="000000"
                disabled={state.isLoading || !isLoaded}
              />
            </div>
            <p className="mt-2 text-xs text-gray-500 text-center">
              Check your email for the 6-digit code
            </p>
          </div>

          <button
            type="submit"
            disabled={state.isLoading || !isLoaded || state.code.length !== 6}
            className="w-full flex items-center justify-center gap-2 px-4 py-3 border border-transparent text-base font-medium rounded-lg text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            {state.isLoading ? (
              <>
                <Loader2 className="h-5 w-5 animate-spin" />
                Verifying...
              </>
            ) : (
              'Verify Code'
            )}
          </button>
        </form>

        <div className="mt-6 text-center">
          <Link
            href="/auth/forgot-password"
            className="text-sm text-gray-600 hover:text-gray-900"
          >
            Didn't receive a code? Request a new one
          </Link>
        </div>
      </div>

      <p className="mt-4 text-center text-sm text-gray-600">
        Remember your password?{' '}
        <Link href="/auth/signin" className="font-medium text-blue-600 hover:text-blue-700">
          Sign in
        </Link>
      </p>
    </div>
  )
}
