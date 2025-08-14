'use client';

import { useState } from 'react';
import OnboardingWizard from './onboarding/OnboardingWizard';
import DashboardLayout from './dashboard/DashboardLayout';
import DashboardOverview from './dashboard/DashboardOverview';

export default function HomePage() {
  // In a real app, this would check authentication and onboarding status
  const [isOnboarded, setIsOnboarded] = useState(false);
  const [showOnboarding, setShowOnboarding] = useState(false);

  if (showOnboarding || !isOnboarded) {
    return <OnboardingWizard />;
  }

  return (
    <DashboardLayout studioName="Zenith Wellness Studio" userName="Studio Owner">
      <DashboardOverview />
    </DashboardLayout>
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