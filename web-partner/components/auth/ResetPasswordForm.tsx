/**
 * Reset Password Form Component
 * Allows users to set a new password after receiving reset email
 */

'use client'

import React, { useState, useCallback } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { Lock, Loader2, CheckCircle, AlertCircle, Eye, EyeOff } from 'lucide-react'
import { supabase } from '@/lib/supabase'

interface FormState {
  password: string
  confirmPassword: string
  showPassword: boolean
  showConfirmPassword: boolean
  isLoading: boolean
  error: string | null
  success: boolean
}

export function ResetPasswordForm() {
  const router = useRouter()
  const [state, setState] = useState<FormState>({
    password: '',
    confirmPassword: '',
    showPassword: false,
    showConfirmPassword: false,
    isLoading: false,
    error: null,
    success: false
  })

  // No need to check session beforehand - Supabase will validate when user submits
  // The callback route already exchanged the code for a session

  const handleSubmit = useCallback(async (e: React.FormEvent) => {
    e.preventDefault()

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
      const { error } = await supabase.auth.updateUser({
        password: state.password
      })

      if (error) {
        setState(prev => ({
          ...prev,
          isLoading: false,
          error: error.message
        }))
      } else {
        setState(prev => ({
          ...prev,
          isLoading: false,
          success: true,
          error: null
        }))

        // Redirect to dashboard after 2 seconds
        setTimeout(() => {
          router.push('/dashboard')
        }, 2000)
      }
    } catch (error: any) {
      setState(prev => ({
        ...prev,
        isLoading: false,
        error: error.message || 'Failed to reset password'
      }))
    }
  }, [state.password, state.confirmPassword, router])

  // Success state
  if (state.success) {
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

  // Reset password form
  return (
    <div className="w-full max-w-md">
      <div className="bg-white rounded-2xl shadow-xl p-8">
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">Set New Password</h1>
          <p className="text-gray-600">
            Enter your new password below
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
                disabled={state.isLoading}
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
                disabled={state.isLoading}
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
            disabled={state.isLoading}
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
