/**
 * Sign In Form Component
 * V8-optimized with memoization and stable callbacks
 */

'use client'

import React, { useState, useCallback, memo } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import { useAuthContext } from '@/lib/context/AuthContext'
import { Mail, Lock, Loader2, AlertCircle } from 'lucide-react'

// Stable form state shape
interface FormState {
  email: string
  password: string
  rememberMe: boolean
  isLoading: boolean
  error: string | null
}

export const SignInForm = memo(function SignInForm() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const { signIn, signInWithOAuth } = useAuthContext()

  const [state, setState] = useState<FormState>(() => {
    // Check if we should remember credentials
    const savedEmail = typeof window !== 'undefined' ? localStorage.getItem('hobbyist_remember_email') : null
    const rememberMe = typeof window !== 'undefined' ? localStorage.getItem('hobbyist_remember_me') === 'true' : false

    return {
      email: savedEmail || '',
      password: '',
      rememberMe,
      isLoading: false,
      error: null
    }
  })

  // Check for error messages in URL
  React.useEffect(() => {
    const urlError = searchParams.get('error')
    const urlMessage = searchParams.get('message')

    if (urlError || urlMessage) {
      let errorMessage = urlMessage || 'Authentication failed'

      // User-friendly error messages
      if (urlError === 'link_expired') {
        errorMessage = 'This link has expired. Please request a new one.'
      } else if (urlError === 'otp_expired') {
        errorMessage = 'Your email link has expired. Please sign in again or request a new link.'
      } else if (urlError === 'access_denied') {
        errorMessage = 'Access was denied. Please try again.'
      }

      setState(prev => ({ ...prev, error: errorMessage }))
    }
  }, [searchParams])

  const returnUrl = searchParams.get('returnUrl') || '/dashboard'

  const handleSubmit = useCallback(async (e: React.FormEvent) => {
    e.preventDefault()

    setState(prev => ({ ...prev, isLoading: true, error: null }))

    const { error } = await signIn(state.email, state.password)

    if (error) {
      setState(prev => ({
        ...prev,
        isLoading: false,
        error: error.message
      }))
    } else {
      // Save remember me preferences
      if (state.rememberMe) {
        localStorage.setItem('hobbyist_remember_email', state.email)
        localStorage.setItem('hobbyist_remember_me', 'true')
      } else {
        localStorage.removeItem('hobbyist_remember_email')
        localStorage.removeItem('hobbyist_remember_me')
      }

      // Redirect to return URL or dashboard
      router.push(decodeURIComponent(returnUrl))
    }
  }, [state.email, state.password, state.rememberMe, signIn, router, returnUrl])

  const handleOAuthSignIn = useCallback(async (
    provider: 'google' | 'apple'
  ) => {
    setState(prev => ({ ...prev, isLoading: true, error: null }))

    const { error } = await signInWithOAuth(provider)

    if (error) {
      setState(prev => ({
        ...prev,
        isLoading: false,
        error: error.message
      }))
    }
    // OAuth will redirect automatically
  }, [signInWithOAuth])

  const handleEmailChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    setState(prev => ({
      ...prev,
      email: e.target.value,
      error: null
    }))
  }, [])

  const handlePasswordChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    setState(prev => ({
      ...prev,
      password: e.target.value,
      error: null
    }))
  }, [])

  const handleRememberMeChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    setState(prev => ({
      ...prev,
      rememberMe: e.target.checked
    }))
  }, [])

  return (
    <div className="w-full max-w-md">
      <div className="glass-modal rounded-lg p-8">
        <h2 className="text-2xl font-bold text-gray-900 mb-6 text-center">
          Sign In to Partner Portal
        </h2>

        {state.error && (
          <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg flex items-start gap-2">
            <AlertCircle className="h-5 w-5 text-red-600 mt-0.5" />
            <p className="text-sm text-red-800">{state.error}</p>
          </div>
        )}
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-1">
              Email Address
            </label>
            <div className="relative">
              <Mail className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
              <input
                id="email"
                type="email"
                value={state.email}
                onChange={handleEmailChange}
                required
                disabled={state.isLoading}
                className="w-full pl-10 pr-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent disabled:bg-gray-50 disabled:cursor-not-allowed text-gray-900"
                placeholder="studio@example.com"
              />
            </div>
          </div>

          <div>
            <label htmlFor="password" className="block text-sm font-medium text-gray-700 mb-1">
              Password
            </label>
            <div className="relative">
              <Lock className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
              <input
                id="password"
                type="password"
                value={state.password}
                onChange={handlePasswordChange}
                required
                disabled={state.isLoading}
                className="w-full pl-10 pr-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent disabled:bg-gray-50 disabled:cursor-not-allowed text-gray-900"
                placeholder="••••••••"
              />
            </div>
          </div>

          <div className="flex items-center justify-between">
            <label className="flex items-center">
              <input
                type="checkbox"
                checked={state.rememberMe}
                onChange={handleRememberMeChange}
                disabled={state.isLoading}
                className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded disabled:opacity-50"
              />
              <span className="ml-2 text-sm text-gray-600">Keep me signed in</span>
            </label>
            <button
              type="button"
              onClick={() => router.push('/auth/forgot-password')}
              className="text-sm text-blue-600 hover:text-blue-500"
            >
              Forgot password?
            </button>
          </div>

          <button
            type="submit"
            disabled={state.isLoading || !state.email || !state.password}
            className="w-full py-2 px-4 bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-lg transition-colors disabled:bg-gray-400 disabled:cursor-not-allowed flex items-center justify-center"
          >
            {state.isLoading ? (
              <>
                <Loader2 className="h-5 w-5 animate-spin mr-2" />
                Signing in...
              </>
            ) : (
              'Sign In'
            )}
          </button>
        </form>



        <p className="mt-6 text-center text-sm text-gray-600">
          Don't have an account?{' '}
          <button
            type="button"
            onClick={() => router.push('/auth/signup')}
            className="font-medium text-blue-600 hover:text-blue-500"
          >
            Sign up
          </button>
        </p>
      </div>
    </div>
  )
})