/**
 * Sign In Page
 * Public route with auth form
 */

import { SignInForm } from '@/components/auth/SignInForm'
import { PublicRoute } from '@/lib/components/ProtectedRoute'

export default function SignInPage() {
  return (
    <PublicRoute>
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100 px-4 sm:px-6 lg:px-8">
        <SignInForm />
      </div>
    </PublicRoute>
  )
}