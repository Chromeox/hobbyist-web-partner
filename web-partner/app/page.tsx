'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import OnboardingWizard from './onboarding/OnboardingWizard';
import DashboardLayout from './dashboard/DashboardLayout';
import DashboardOverview from './dashboard/DashboardOverview';
import { ProtectedRoute } from '@/lib/components/ProtectedRoute';
import { useAuthContext } from '@/lib/context/AuthContext';
import { useUserProfile } from '@/lib/hooks/useAuth';

export default function HomePage() {
  const router = useRouter();
  const { isAuthenticated, isLoading: authLoading } = useAuthContext();
  const { profile, isLoading: profileLoading } = useUserProfile();
  const [isOnboarded, setIsOnboarded] = useState(false);

  useEffect(() => {
    // Redirect to sign in if not authenticated
    if (!authLoading && !isAuthenticated) {
      router.push('/auth/signin');
      return;
    }

    // Check onboarding status from profile
    if (!profileLoading && profile) {
      const onboarded = profile.instructor?.businessName ? true : false;
      setIsOnboarded(onboarded);
    }
  }, [authLoading, isAuthenticated, profileLoading, profile, router]);

  // Show loading while checking auth
  if (authLoading || profileLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
          <p className="mt-4 text-gray-600">Loading...</p>
        </div>
      </div>
    );
  }

  // Show onboarding if not completed
  if (isAuthenticated && !isOnboarded) {
    return (
      <ProtectedRoute>
        <OnboardingWizard />
      </ProtectedRoute>
    );
  }

  // Show dashboard if onboarded
  return (
    <ProtectedRoute>
      <DashboardLayout 
        studioName={profile?.instructor?.businessName || "Studio"} 
        userName={`${profile?.profile?.firstName || ''} ${profile?.profile?.lastName || ''}`.trim() || profile?.email || 'User'}
      >
        <DashboardOverview />
      </DashboardLayout>
    </ProtectedRoute>
  );
}

// Demo navigation component to switch between views
function DemoNavigation() {
  const [currentView, setCurrentView] = useState<'onboarding' | 'dashboard'>('dashboard');

  if (currentView === 'onboarding') {
    return <OnboardingWizard />;
  }

  return (
    <DashboardLayout studioName="Zenith Wellness Studio" userName="Studio Owner">
      <div className="mb-6">
        <div className="flex items-center gap-4 p-4 bg-blue-50 rounded-lg border border-blue-200">
          <div className="flex-1">
            <h3 className="font-medium text-blue-900">Demo Mode</h3>
            <p className="text-sm text-blue-700">
              Switch between onboarding and dashboard views
            </p>
          </div>
          <div className="flex gap-2">
            <button
              onClick={() => setCurrentView('onboarding')}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
            >
              View Onboarding
            </button>
            <button
              onClick={() => setCurrentView('dashboard')}
              className="px-4 py-2 border border-blue-300 text-blue-700 rounded-lg hover:bg-blue-100 transition-colors"
            >
              View Dashboard
            </button>
          </div>
        </div>
      </div>
      <DashboardOverview />
    </DashboardLayout>
  );
}