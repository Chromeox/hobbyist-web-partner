/**
 * Sign Up Page
 * Public route with registration form
 */

import { SignUpForm } from '@/components/auth/SignUpForm'
import { PublicRoute } from '@/lib/components/ProtectedRoute'

export default function SignUpPage() {
  return (
    <PublicRoute>
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100 px-4 sm:px-6 lg:px-8">
        <SignUpForm />
      </div>
    </PublicRoute>
  )
}