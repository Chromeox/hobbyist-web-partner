import Link from 'next/link';
import { ArrowRight, Play, Zap } from 'lucide-react';
import Footer from '@/components/common/Footer';

export default function HomePage() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      <div className="container mx-auto px-4 py-12">
        {/* Hero Section */}
        <div className="text-center mb-12">
          <h1 className="text-4xl font-bold text-gray-900 mb-4">
            Hobbyist Studio Partner Portal
          </h1>
          <p className="text-xl text-gray-600 mb-8">
            Complete studio management with onboarding, calendar integration, and AI-powered insights
          </p>

          {/* Quick Access Buttons */}
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Link
              href="/dashboard"
              className="inline-flex items-center gap-2 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors font-semibold"
            >
              <Play className="h-5 w-5" />
              View Dashboard with Setup Reminders
              <ArrowRight className="h-5 w-5" />
            </Link>

            <Link
              href="/onboarding"
              className="inline-flex items-center gap-2 px-6 py-3 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors font-semibold"
            >
              <Zap className="h-5 w-5" />
              Try Onboarding Flow
              <ArrowRight className="h-5 w-5" />
            </Link>
          </div>
        </div>

        {/* Features Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-12">
          <div className="bg-white p-6 rounded-xl shadow-lg border border-gray-200">
            <h3 className="font-semibold text-gray-900 mb-2">📧 Email Verification Flow</h3>
            <p className="text-gray-600 text-sm">Complete signup → email verification → onboarding pipeline</p>
          </div>

          <div className="bg-white p-6 rounded-xl shadow-lg border border-gray-200">
            <h3 className="font-semibold text-gray-900 mb-2">🎯 8-Step Onboarding</h3>
            <p className="text-gray-600 text-sm">Guided setup with calendar integration and AI intelligence</p>
          </div>

          <div className="bg-white p-6 rounded-xl shadow-lg border border-gray-200">
            <h3 className="font-semibold text-gray-900 mb-2">📅 Calendar Integration</h3>
            <p className="text-gray-600 text-sm">Google, Outlook, MindBody, and Acuity scheduling support</p>
          </div>

          <div className="bg-white p-6 rounded-xl shadow-lg border border-gray-200">
            <h3 className="font-semibold text-gray-900 mb-2">🧠 Studio Intelligence</h3>
            <p className="text-gray-600 text-sm">AI-powered insights and optimization recommendations</p>
          </div>

          <div className="bg-white p-6 rounded-xl shadow-lg border border-gray-200">
            <h3 className="font-semibold text-gray-900 mb-2">🔔 Setup Reminders</h3>
            <p className="text-gray-600 text-sm">Dashboard cards encouraging feature completion</p>
          </div>

          <div className="bg-white p-6 rounded-xl shadow-lg border border-gray-200">
            <h3 className="font-semibold text-gray-900 mb-2">📊 Analytics Dashboard</h3>
            <p className="text-gray-600 text-sm">Complete studio metrics and performance tracking</p>
          </div>
        </div>

        {/* Status */}
        <div className="bg-green-50 p-6 rounded-xl border border-green-200 text-center">
          <p className="text-green-800 font-medium">
            ✅ Enhanced Registration & Onboarding System Complete!
          </p>
          <p className="text-green-700 text-sm mt-2">
            All features are now integrated and ready for testing
          </p>
        </div>
      </div>

      {/* Footer with Privacy Policy */}
      <Footer />
    </div>
  );
}