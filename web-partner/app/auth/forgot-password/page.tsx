/**
 * Forgot Password Page
 * Allows users to reset their password via email
 */

import { ForgotPasswordForm } from '@/components/auth/ForgotPasswordForm'
import { PublicRoute } from '@/lib/components/ProtectedRoute'

export default function ForgotPasswordPage() {
  return (
    <PublicRoute>
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100 px-4 sm:px-6 lg:px-8">
        <ForgotPasswordForm />
      </div>
    </PublicRoute>
  )
}
