/**
 * Reset Password Page
 * Allows users to set a new password after clicking email link
 */

import { ResetPasswordForm } from '@/components/auth/ResetPasswordForm'
import { PublicRoute } from '@/lib/components/ProtectedRoute'

export default function ResetPasswordPage() {
  return (
    <PublicRoute>
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100 px-4 sm:px-6 lg:px-8">
        <ResetPasswordForm />
      </div>
    </PublicRoute>
  )
}
