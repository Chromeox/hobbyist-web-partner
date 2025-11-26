/**
 * Sign Up Page
 * Public route with registration form
 * Using Clerk for authentication
 */

import { SignUpForm } from '@/components/auth/SignUpForm'

export default function SignUpPage() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100 px-4 sm:px-6 lg:px-8">
      <SignUpForm />
    </div>
  )
}