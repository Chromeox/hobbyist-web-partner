/**
 * Sign Up Form Component
 * V8-optimized with memoization and stable callbacks
 */

'use client'

import React, { useState, useCallback, memo } from 'react'
import { useRouter } from 'next/navigation'
import { useAuthContext } from '@/lib/context/AuthContext'
import { Mail, Lock, User, Building, Loader2, AlertCircle, CheckCircle } from 'lucide-react'

// Stable form state shape
interface FormState {
  email: string
  password: string
  confirmPassword: string
  firstName: string
  lastName: string
  businessName: string
  isLoading: boolean
  error: string | null
  success: boolean
}

export const SignUpForm = memo(function SignUpForm() {
  const router = useRouter()
  const { signUp } = useAuthContext()
  
  const [state, setState] = useState<FormState>({
    email: '',
    password: '',
    confirmPassword: '',
    firstName: '',
    lastName: '',
    businessName: '',
    isLoading: false,
    error: null,
    success: false
  })

  const handleSubmit = useCallback(async (e: React.FormEvent) => {
    e.preventDefault()
    
    // Validate passwords match
    if (state.password !== state.confirmPassword) {
      setState(prev => ({ 
        ...prev, 
        error: 'Passwords do not match' 
      }))
      return
    }

    // Validate password strength
    if (state.password.length < 8) {
      setState(prev => ({
        ...prev,
        error: 'Password must be at least 8 characters'
      }))
      return
    }

    // Validate business name (required for all studio accounts)
    if (!state.businessName) {
      setState(prev => ({
        ...prev,
        error: 'Business Name is required'
      }))
      return
    }

    setState(prev => ({ ...prev, isLoading: true, error: null }))

    try {
      // Prepare metadata for studio account
      const metadata = {
        first_name: state.firstName,
        last_name: state.lastName,
        role: 'studio',
        business_name: state.businessName
      }

      console.log('Attempting signup with:', { email: state.email, metadata })

      const { error } = await signUp(state.email, state.password, metadata)

      console.log('Signup response:', { error })

      if (error) {
        console.error('Signup error:', error)
        setState(prev => ({
          ...prev,
          isLoading: false,
          error: error.message
        }))
      } else {
        setState(prev => ({
          ...prev,
          isLoading: false,
          success: true
        }))

        // Redirect to email verification flow
        setTimeout(() => {
          router.push(`/auth/check-email?email=${encodeURIComponent(state.email)}`)
        }, 2000)
      }
    } catch (err) {
      console.error('Signup exception:', err)
      setState(prev => ({
        ...prev,
        isLoading: false,
        error: err instanceof Error ? err.message : 'An unexpected error occurred. Please try again.'
      }))
    }
  }, [state, signUp, router])

  const handleInputChange = useCallback((field: keyof FormState, value: string) => {
    setState(prev => ({
      ...prev,
      [field]: value,
      error: null // Clear error on input change
    }))
  }, [])

  if (state.success) {
    return (
      <div className="w-full max-w-md">
        <div className="glass-modal rounded-lg p-8">
          <div className="text-center">
            <CheckCircle className="h-12 w-12 text-green-500 mx-auto mb-4" />
            <h2 className="text-2xl font-bold text-gray-900 mb-2">
              Account Created Successfully!
            </h2>
            <p className="text-gray-600">
              Please check your email to verify your account.
            </p>
            <p className="text-sm text-gray-500 mt-4">
              Redirecting to onboarding...
            </p>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="w-full max-w-md">
      <div className="glass-modal rounded-lg p-8">
        <h2 className="text-2xl font-bold text-gray-900 mb-6 text-center">
          Create Partner Account
        </h2>

        {state.error && (
          <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg flex items-start gap-2">
            <AlertCircle className="h-5 w-5 text-red-600 mt-0.5" />
            <p className="text-sm text-red-800">{state.error}</p>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Account Type - Studio Only for Alpha */}
          <div className="mb-4 bg-blue-50 border border-blue-200 rounded-lg p-3">
            <div className="flex items-center">
              <Building className="h-5 w-5 text-blue-600 mr-2" />
              <span className="text-sm font-medium text-blue-900">Creating Studio Account</span>
            </div>
          </div>

          {/* Business Information */}
          <div>
            <label htmlFor="businessName" className="block text-sm font-medium text-gray-700 mb-1">
              Business Name
            </label>
            <div className="relative">
              <Building className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
              <input
                id="businessName"
                type="text"
                value={state.businessName}
                onChange={(e) => handleInputChange('businessName', e.target.value)}
                required
                disabled={state.isLoading}
                className="w-full pl-10 pr-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent disabled:bg-gray-50 disabled:cursor-not-allowed text-gray-900"
                placeholder="Wellness Studio"
              />
            </div>
          </div>

          {/* Owner Information */}
          <div className="pt-2">
            <h3 className="text-sm font-semibold text-gray-700 mb-3">Owner Information</h3>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label htmlFor="firstName" className="block text-sm font-medium text-gray-700 mb-1">
                  First Name
                </label>
                <div className="relative">
                  <User className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
                  <input
                    id="firstName"
                    type="text"
                    value={state.firstName}
                    onChange={(e) => handleInputChange('firstName', e.target.value)}
                    required
                    disabled={state.isLoading}
                    className="w-full pl-10 pr-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent disabled:bg-gray-50 disabled:cursor-not-allowed text-gray-900"
                    placeholder="John"
                  />
                </div>
              </div>

              <div>
                <label htmlFor="lastName" className="block text-sm font-medium text-gray-700 mb-1">
                  Last Name
                </label>
                <div className="relative">
                  <User className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
                  <input
                    id="lastName"
                    type="text"
                    value={state.lastName}
                    onChange={(e) => handleInputChange('lastName', e.target.value)}
                    required
                    disabled={state.isLoading}
                    className="w-full pl-10 pr-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent disabled:bg-gray-50 disabled:cursor-not-allowed text-gray-900"
                    placeholder="Doe"
                  />
                </div>
              </div>
            </div>
          </div>

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
                onChange={(e) => handleInputChange('email', e.target.value)}
                required
                disabled={state.isLoading}
                className="w-full pl-10 pr-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent disabled:bg-gray-50 disabled:cursor-not-allowed"
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
                onChange={(e) => handleInputChange('password', e.target.value)}
                required
                disabled={state.isLoading}
                className="w-full pl-10 pr-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent disabled:bg-gray-50 disabled:cursor-not-allowed"
                placeholder="••••••••"
              />
            </div>
            <p className="mt-1 text-xs text-gray-500">
              At least 8 characters
            </p>
          </div>

          <div>
            <label htmlFor="confirmPassword" className="block text-sm font-medium text-gray-700 mb-1">
              Confirm Password
            </label>
            <div className="relative">
              <Lock className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
              <input
                id="confirmPassword"
                type="password"
                value={state.confirmPassword}
                onChange={(e) => handleInputChange('confirmPassword', e.target.value)}
                required
                disabled={state.isLoading}
                className="w-full pl-10 pr-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent disabled:bg-gray-50 disabled:cursor-not-allowed"
                placeholder="••••••••"
              />
            </div>
          </div>

          <div className="flex items-start">
            <input
              id="terms"
              type="checkbox"
              required
              className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded mt-0.5"
            />
            <label htmlFor="terms" className="ml-2 text-sm text-gray-600">
              I agree to the{' '}
              <a href="/legal/terms" className="text-blue-600 hover:text-blue-500">
                Terms and Conditions
              </a>
              {' '}
              and{' '}
              <a href="/legal/privacy" className="text-blue-600 hover:text-blue-500">
                Privacy Policy
              </a>
            </label>
          </div>

          <button
            type="submit"
            disabled={state.isLoading}
            className="w-full py-2 px-4 bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-lg transition-colors disabled:bg-gray-400 disabled:cursor-not-allowed flex items-center justify-center"
          >
            {state.isLoading ? (
              <>
                <Loader2 className="h-5 w-5 animate-spin mr-2" />
                Creating account...
              </>
            ) : (
              'Create Account'
            )}
          </button>
        </form>

        <p className="mt-6 text-center text-sm text-gray-600">
          Already have an account?{' '}
          <button
            type="button"
            onClick={() => router.push('/auth/signin')}
            className="font-medium text-blue-600 hover:text-blue-500"
          >
            Sign in
          </button>
        </p>
      </div>
    </div>
  )
})