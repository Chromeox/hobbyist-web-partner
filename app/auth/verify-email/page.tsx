/**
 * Email Verification Page
 * Handles email verification token and redirects to onboarding
 */

'use client'

import React, { useState, useEffect, Suspense } from 'react'
import { motion } from 'framer-motion'
import { CheckCircle, XCircle, Loader2, ArrowRight } from 'lucide-react'
import { useRouter, useSearchParams } from 'next/navigation'
import { PublicRoute } from '@/lib/components/ProtectedRoute'

type VerificationStatus = 'loading' | 'success' | 'error' | 'expired'

function VerifyEmailContent() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const [status, setStatus] = useState<VerificationStatus>('loading')
  const [error, setError] = useState<string>('')

  const token = searchParams.get('token')
  const email = searchParams.get('email')

  useEffect(() => {
    if (!token) {
      setStatus('error')
      setError('Invalid verification link')
      return
    }

    // Simulate verification process
    const verifyEmail = async () => {
      try {
        // In production, this would call your verification API
        await new Promise(resolve => setTimeout(resolve, 2000))

        // Simulate different outcomes for demo
        const random = Math.random()
        if (random > 0.8) {
          setStatus('expired')
        } else if (random > 0.9) {
          setStatus('error')
          setError('Verification failed')
        } else {
          setStatus('success')
          // Redirect to onboarding after success
          setTimeout(() => {
            router.push('/onboarding')
          }, 3000)
        }
      } catch (err) {
        setStatus('error')
        setError('Verification failed. Please try again.')
      }
    }

    verifyEmail()
  }, [token, router])

  const handleResendVerification = async () => {
    setStatus('loading')
    // In production, resend verification email
    console.log('Resending verification email')

    // Simulate resend
    setTimeout(() => {
      router.push(`/auth/check-email?email=${email}`)
    }, 1000)
  }

  const getStatusContent = () => {
    switch (status) {
      case 'loading':
        return {
          icon: <Loader2 className="h-12 w-12 text-blue-600 animate-spin" />,
          title: 'Verifying Your Email',
          message: 'Please wait while we verify your account...',
          bgColor: 'bg-blue-100',
          action: null
        }

      case 'success':
        return {
          icon: <CheckCircle className="h-12 w-12 text-green-600" />,
          title: 'Email Verified Successfully!',
          message: 'Your account has been verified. Redirecting to onboarding...',
          bgColor: 'bg-green-100',
          action: (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 1 }}
              className="flex items-center justify-center text-sm text-green-700"
            >
              <span>Redirecting in 3 seconds...</span>
              <ArrowRight className="ml-2 h-4 w-4" />
            </motion.div>
          )
        }

      case 'expired':
        return {
          icon: <XCircle className="h-12 w-12 text-orange-600" />,
          title: 'Verification Link Expired',
          message: 'This verification link has expired. Please request a new one.',
          bgColor: 'bg-orange-100',
          action: (
            <button
              onClick={handleResendVerification}
              className="w-full mt-4 px-4 py-3 bg-orange-600 text-white font-medium rounded-lg hover:bg-orange-700 transition-colors"
            >
              Send New Verification Email
            </button>
          )
        }

      case 'error':
        return {
          icon: <XCircle className="h-12 w-12 text-red-600" />,
          title: 'Verification Failed',
          message: error || 'Something went wrong. Please try again.',
          bgColor: 'bg-red-100',
          action: (
            <div className="space-y-3 mt-4">
              <button
                onClick={handleResendVerification}
                className="w-full px-4 py-3 bg-red-600 text-white font-medium rounded-lg hover:bg-red-700 transition-colors"
              >
                Send New Verification Email
              </button>
              <button
                onClick={() => router.push('/auth/signup')}
                className="w-full px-4 py-3 border border-gray-300 text-gray-700 font-medium rounded-lg hover:bg-gray-50 transition-colors"
              >
                Back to Sign Up
              </button>
            </div>
          )
        }

      default:
        return null
    }
  }

  const content = getStatusContent()
  if (!content) return null

  return (
    <PublicRoute>
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100 px-4 sm:px-6 lg:px-8">
        <div className="w-full max-w-md">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
            className="glass-modal rounded-lg p-8 text-center"
          >
            {/* Status Icon */}
            <motion.div
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              transition={{ delay: 0.2, type: "spring", stiffness: 200 }}
              className="mx-auto mb-6"
            >
              <div className={`w-20 h-20 ${content.bgColor} rounded-full flex items-center justify-center mx-auto`}>
                {content.icon}
              </div>
            </motion.div>

            {/* Content */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.4 }}
            >
              <h1 className="text-2xl font-bold text-gray-900 mb-2">
                {content.title}
              </h1>
              <p className="text-gray-600 mb-6">
                {content.message}
              </p>

              {content.action}

              {/* Help Section */}
              {status !== 'loading' && (
                <div className="mt-6 pt-6 border-t border-gray-200">
                  <p className="text-sm text-gray-600">
                    Need help?{' '}
                    <a
                      href="mailto:support@hobbyist.com"
                      className="text-blue-600 hover:text-blue-500 font-medium"
                    >
                      Contact Support
                    </a>
                  </p>
                </div>
              )}
            </motion.div>
          </motion.div>
        </div>
      </div>
    </PublicRoute>
  )
}

export default function VerifyEmailPage() {
  return (
    <Suspense fallback={
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100">
        <div className="flex items-center space-x-2">
          <Loader2 className="h-6 w-6 animate-spin text-blue-600" />
          <span className="text-gray-600">Loading...</span>
        </div>
      </div>
    }>
      <VerifyEmailContent />
    </Suspense>
  )
}