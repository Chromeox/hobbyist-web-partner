/**
 * Check Email Page
 * Intermediate page shown after signup before email verification
 */

'use client'

import React from 'react'
import { motion } from 'framer-motion'
import { Mail, ArrowRight, RefreshCw } from 'lucide-react'
import { useRouter, useSearchParams } from 'next/navigation'
import { PublicRoute } from '@/lib/components/ProtectedRoute'

export default function CheckEmailPage() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const email = searchParams.get('email') || 'your email'

  const handleResendEmail = async () => {
    // In production, this would call your resend verification email API
    console.log('Resending verification email to:', email)
    // Show success message
  }

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
            {/* Email Icon Animation */}
            <motion.div
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              transition={{ delay: 0.2, type: "spring", stiffness: 200 }}
              className="mx-auto mb-6"
            >
              <div className="relative">
                <div className="w-20 h-20 bg-blue-100 rounded-full flex items-center justify-center mx-auto">
                  <Mail className="h-10 w-10 text-blue-600" />
                </div>
                {/* Animated pulse ring */}
                <motion.div
                  animate={{ scale: [1, 1.2, 1], opacity: [0.3, 0.1, 0.3] }}
                  transition={{ duration: 2, repeat: Infinity }}
                  className="absolute inset-0 bg-blue-200 rounded-full"
                />
              </div>
            </motion.div>

            {/* Content */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.4 }}
            >
              <h1 className="text-2xl font-bold text-gray-900 mb-2">
                Check Your Email
              </h1>
              <p className="text-gray-600 mb-6">
                We've sent a verification link to{' '}
                <span className="font-medium text-gray-900">{email}</span>
              </p>

              <div className="space-y-4">
                <p className="text-sm text-gray-500">
                  Click the link in your email to verify your account and continue with onboarding.
                </p>

                {/* Action Buttons */}
                <div className="space-y-3">
                  <button
                    onClick={() => window.open('https://mail.google.com', '_blank')}
                    className="w-full flex items-center justify-center px-4 py-3 bg-blue-600 text-white font-medium rounded-lg hover:bg-blue-700 transition-colors"
                  >
                    Open Gmail
                    <ArrowRight className="ml-2 h-4 w-4" />
                  </button>

                  <button
                    onClick={handleResendEmail}
                    className="w-full flex items-center justify-center px-4 py-3 border border-gray-300 text-gray-700 font-medium rounded-lg hover:bg-gray-50 transition-colors"
                  >
                    <RefreshCw className="mr-2 h-4 w-4" />
                    Resend Email
                  </button>
                </div>

                {/* Help Section */}
                <div className="mt-6 pt-6 border-t border-gray-200">
                  <p className="text-xs text-gray-500 mb-3">
                    Didn't receive the email? Check your spam folder or try a different email provider.
                  </p>

                  <button
                    onClick={() => router.push('/auth/signup')}
                    className="text-sm text-blue-600 hover:text-blue-500 font-medium"
                  >
                    Use a different email address
                  </button>
                </div>
              </div>
            </motion.div>
          </motion.div>

          {/* Additional Help */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.6 }}
            className="mt-6 text-center"
          >
            <p className="text-sm text-gray-600">
              Need help?{' '}
              <a
                href="mailto:support@hobbyist.com"
                className="text-blue-600 hover:text-blue-500 font-medium"
              >
                Contact Support
              </a>
            </p>
          </motion.div>
        </div>
      </div>
    </PublicRoute>
  )
}