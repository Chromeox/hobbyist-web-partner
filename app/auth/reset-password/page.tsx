/**
 * Reset Password Page
 * Allows users to set a new password after clicking email link
 * Note: This is a public page - users access it via magic link from email
 */

import { ResetPasswordForm } from '@/components/auth/ResetPasswordForm'

export default function ResetPasswordPage() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100 px-4 sm:px-6 lg:px-8">
      <ResetPasswordForm />
    </div>
  )
}
