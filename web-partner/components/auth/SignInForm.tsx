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
    provider: 'google' | 'apple' | 'facebook'
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

        {/* Demo credentials info */}
        <div className="mb-4 p-3 bg-blue-50 border border-blue-200 rounded-lg">
          <p className="text-sm font-medium text-blue-900 mb-1">Demo Account Available:</p>
          <p className="text-xs text-blue-700">Email: demo@hobbyist.com</p>
          <p className="text-xs text-blue-700">Password: demo123456</p>
        </div>

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

        <div className="mt-6">
          <div className="relative">
            <div className="absolute inset-0 flex items-center">
              <div className="w-full border-t border-gray-300" />
            </div>
            <div className="relative flex justify-center text-sm">
              <span className="px-2 bg-white text-gray-500">Or continue with</span>
            </div>
          </div>

          <div className="mt-6 grid grid-cols-3 gap-3">
            <button
              type="button"
              onClick={() => handleOAuthSignIn('google')}
              disabled={state.isLoading}
              className="w-full py-2 px-3 border border-gray-300 rounded-lg bg-white hover:bg-gray-50 transition-colors disabled:bg-gray-50 disabled:cursor-not-allowed"
            >
              <svg className="h-5 w-5 mx-auto" viewBox="0 0 24 24">
                <path
                  fill="#4285F4"
                  d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                />
                <path
                  fill="#34A853"
                  d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                />
                <path
                  fill="#FBBC05"
                  d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
                />
                <path
                  fill="#EA4335"
                  d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
                />
              </svg>
            </button>

            <button
              type="button"
              onClick={() => handleOAuthSignIn('apple')}
              disabled={state.isLoading}
              className="w-full py-2 px-3 border border-gray-300 rounded-lg bg-white hover:bg-gray-50 transition-colors disabled:bg-gray-50 disabled:cursor-not-allowed"
            >
              <svg className="h-5 w-5 mx-auto" fill="currentColor" viewBox="0 0 24 24">
                <path d="M17.569 12.382c-.04-1.29.444-2.342 1.451-3.159-.542-.774-1.355-1.213-2.437-1.317-.981-.094-2.064.585-2.605.585-.541 0-1.396-.57-2.165-.554-1.165.015-2.179.668-2.724 1.677-1.159 2.024-.295 4.981.798 6.616.572.802 1.217 1.683 2.059 1.652.847-.031 1.158-.528 2.179-.528 1.021 0 1.311.528 2.179.513.905-.016 1.456-.795 1.997-1.611.638-.893.883-1.788.898-1.835-.02-.005-1.695-.635-1.73-2.539zm-1.591-4.645c.444-.558.754-1.301.662-2.072-.695.031-1.532.476-2.007 1.034-.428.496-.816 1.301-.719 2.057.76.061 1.545-.381 2.064-1.019z"/>
              </svg>
            </button>

            <button
              type="button"
              onClick={() => handleOAuthSignIn('facebook')}
              disabled={state.isLoading}
              className="w-full py-2 px-3 border border-gray-300 rounded-lg bg-white hover:bg-gray-50 transition-colors disabled:bg-gray-50 disabled:cursor-not-allowed"
            >
              <svg className="h-5 w-5 mx-auto" fill="#1877F2" viewBox="0 0 24 24">
                <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/>
              </svg>
            </button>
          </div>
        </div>

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