'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/lib/hooks/useAuth';
import BusinessInfoStep from './steps/BusinessInfoStep';
import VerificationStep from './steps/VerificationStep';
import StudioProfileStep from './steps/StudioProfileStep';
import ServicesStep from './steps/ServicesStep';
import PaymentSetupStep from './steps/PaymentSetupStep';
import CalendarSetupStep from './steps/CalendarSetupStep';
import ReviewStep from './steps/ReviewStep';
import { OnboardingProvider, type OnboardingData } from './context/OnboardingContext';
import ProgressIndicator from './components/ProgressIndicator';
import OnboardingWelcome from './OnboardingWelcome';
import { CheckCircle, ArrowRight, ArrowLeft, ChevronLeft, ChevronRight, Save, AlertCircle } from 'lucide-react';

const ONBOARDING_STEPS = [
  { id: 'business-info', title: 'Business Information', component: BusinessInfoStep, description: 'Basic studio details', estimatedTime: '2 min' },
  { id: 'verification', title: 'Verification', component: VerificationStep, description: 'Verify your identity', estimatedTime: '1 min' },
  { id: 'studio-profile', title: 'Studio Profile', component: StudioProfileStep, description: 'Studio description & photos', estimatedTime: '3 min' },
  { id: 'services', title: 'Services & Classes', component: ServicesStep, description: 'Define your offerings', estimatedTime: '3 min' },
  { id: 'payment', title: 'Payment Setup', component: PaymentSetupStep, description: 'Connect payment methods', estimatedTime: '2 min' },
  { id: 'review', title: 'Review & Complete', component: ReviewStep, description: 'Final review & launch', estimatedTime: '1 min' },
  { id: 'calendar-setup', title: 'Calendar Integration', component: CalendarSetupStep, description: 'Import existing schedules (optional)', estimatedTime: '3 min', optional: true }
];

export default function OnboardingWizard() {
  const router = useRouter();
  const { user, isAuthenticated, isLoading } = useAuth();
  const [showWelcome, setShowWelcome] = useState(true);
  const [currentStep, setCurrentStep] = useState(0);
  const [completedSteps, setCompletedSteps] = useState<Set<number>>(new Set());
  const [onboardingData, setOnboardingData] = useState<OnboardingData>({});
  const [unsavedChanges, setUnsavedChanges] = useState(false);
  const [showNavigationWarning, setShowNavigationWarning] = useState(false);

  // Redirect if not authenticated
  useEffect(() => {
    if (!isLoading && !isAuthenticated) {
      router.push('/auth/signin?redirect=/onboarding');
    }
  }, [isAuthenticated, isLoading, router]);

  // Get real user data from auth
  const userData = user ? {
    userId: user.id,
    accountType: (user.user_metadata?.role || 'studio') as 'studio' | 'instructor',
    businessName: user.user_metadata?.business_name || '',
    userName: user.user_metadata?.full_name || user.email?.split('@')[0] || '',
    email: user.email || ''
  } : null;

  const CurrentStepComponent = ONBOARDING_STEPS[currentStep].component;

  const handleNextStep = (stepData: any) => {
    setOnboardingData(prev => ({ ...prev, ...stepData }));
    setCompletedSteps(prev => new Set(Array.from(prev).concat(currentStep)));

    if (currentStep < ONBOARDING_STEPS.length - 1) {
      setCurrentStep(currentStep + 1);
    }
  };

  const handlePreviousStep = useCallback(() => {
    if (currentStep > 0) {
      if (unsavedChanges) {
        setShowNavigationWarning(true);
      } else {
        setCurrentStep(currentStep - 1);
      }
    }
  }, [currentStep, unsavedChanges]);

  const handleStepJump = (stepIndex: number) => {
    // Allow jumping to completed steps or the next sequential step
    if (completedSteps.has(stepIndex) || stepIndex === completedSteps.size) {
      if (unsavedChanges) {
        setShowNavigationWarning(true);
      } else {
        setCurrentStep(stepIndex);
      }
    }
  };

  // Keyboard navigation
  useEffect(() => {
    const handleKeyPress = (e: KeyboardEvent) => {
      if (e.key === 'ArrowLeft' && !e.metaKey && !e.ctrlKey) {
        e.preventDefault();
        handlePreviousStep();
      } else if (e.key === 'ArrowRight' && !e.metaKey && !e.ctrlKey) {
        e.preventDefault();
        if (currentStep < ONBOARDING_STEPS.length - 1) {
          handleNextStep({});
        }
      } else if (e.key === 's' && (e.metaKey || e.ctrlKey)) {
        e.preventDefault();
        // Save current progress (implement autosave)
        console.log('Saving progress...', onboardingData);
      }
    };

    window.addEventListener('keydown', handleKeyPress);
    return () => window.removeEventListener('keydown', handleKeyPress);
  }, [currentStep, handlePreviousStep, onboardingData]);

  const handleSubmitOnboarding = async () => {
    if (!user || !userData) {
      console.error('No authenticated user');
      router.push('/auth/signin?redirect=/onboarding');
      return;
    }

    try {
      const payload = {
        owner: {
          userId: user.id,
          name: user.user_metadata?.full_name || userData.userName,
          email: user.email!,
          accountType: userData.accountType,
          businessName: userData.businessName
        },
        businessInfo: onboardingData.businessInfo,
        studioProfile: onboardingData.studioProfile,
        verification: onboardingData.verification,
        services: onboardingData.services,
        payment: onboardingData.payment,
        calendar: onboardingData.calendar
      };

      const response = await fetch('/api/partners/onboarding', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
      });

      if (response.ok) {
        console.log('Onboarding submitted successfully!');
        // Redirect to dashboard
        router.push('/dashboard');
      } else {
        const error = await response.json();
        console.error('Onboarding submission failed:', error);
      }
    } catch (error) {
      console.error('Onboarding submission error:', error);
    }
  };

  const progressPercentage = ((currentStep + 1) / ONBOARDING_STEPS.length) * 100;

  // Show loading while checking auth
  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-purple-50 via-white to-blue-50">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Loading...</p>
        </div>
      </div>
    );
  }

  // Don't render if not authenticated (will redirect)
  if (!isAuthenticated || !user || !userData) {
    return null;
  }

  // Show welcome screen first
  if (showWelcome) {
    return (
      <OnboardingWelcome
        accountType={userData.accountType}
        businessName={userData.businessName}
        userName={userData.userName}
        onStart={() => setShowWelcome(false)}
      />
    );
  }

  return (
    <OnboardingProvider value={{ onboardingData, setOnboardingData }}>
      <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
        <div className="container mx-auto px-4 py-8">
          {/* Header */}
          <div className="text-center mb-8">
            <h1 className="text-4xl font-bold text-gray-900 mb-2">
              Welcome to Hobbyist Partner Portal
            </h1>
            <p className="text-gray-600">
              Complete your studio setup in just a few steps
            </p>
          </div>

          {/* Enhanced Progress Indicator with Click Navigation */}
          <div className="relative">
            <ProgressIndicator
              steps={ONBOARDING_STEPS}
              currentStep={currentStep}
              completedSteps={completedSteps}
            />
            {/* Clickable Step Navigation Overlay */}
            <div className="absolute inset-0 flex items-start justify-between max-w-4xl mx-auto pointer-events-none">
              {ONBOARDING_STEPS.map((step, index) => (
                <button
                  key={step.id}
                  onClick={() => handleStepJump(index)}
                  disabled={!completedSteps.has(index) && index !== completedSteps.size}
                  className={`pointer-events-auto w-12 h-12 rounded-full transition-transform hover:scale-110 ${completedSteps.has(index) || index === completedSteps.size
                      ? 'cursor-pointer'
                      : 'cursor-not-allowed opacity-50'
                    }`}
                  title={`${step.title}: ${step.description}`}
                />
              ))}
            </div>
          </div>

          {/* Progress Bar */}
          <div className="max-w-4xl mx-auto mb-8">
            <div className="bg-gray-200 rounded-full h-2 overflow-hidden">
              <motion.div
                className="bg-gradient-to-r from-blue-500 to-indigo-600 h-full"
                initial={{ width: 0 }}
                animate={{ width: `${progressPercentage}%` }}
                transition={{ duration: 0.3 }}
              />
            </div>
          </div>

          {/* Step Content with Enhanced Navigation */}
          <div className="max-w-4xl mx-auto">
            {/* Floating Navigation Bar */}
            <div className="glass-card rounded-t-xl p-4 flex items-center justify-between mb-0">
              <div className="flex items-center gap-4">
                <button
                  onClick={handlePreviousStep}
                  disabled={currentStep === 0}
                  className={`flex items-center gap-2 px-4 py-2 rounded-lg font-medium transition-all ${currentStep === 0
                      ? 'bg-gray-100 text-gray-400 cursor-not-allowed'
                      : 'glass-button hover:shadow-md'
                    }`}
                >
                  <ChevronLeft className="h-5 w-5" />
                  <span className="hidden sm:inline">Back</span>
                </button>

                <div className="flex items-center gap-2">
                  <span className="text-sm text-gray-500">Step</span>
                  <span className="text-lg font-bold text-blue-600">
                    {currentStep + 1} / {ONBOARDING_STEPS.length}
                  </span>
                </div>
              </div>

              <div className="flex items-center gap-4">
                {/* Auto-save indicator */}
                <div className="flex items-center gap-2 text-sm text-gray-600">
                  <Save className="h-4 w-4" />
                  <span className="hidden sm:inline">Progress saved</span>
                </div>

                <button
                  onClick={() => currentStep === ONBOARDING_STEPS.length - 1 ? handleSubmitOnboarding() : handleNextStep({})}
                  className={`flex items-center gap-2 px-4 py-2 rounded-lg font-medium transition-all ${currentStep === ONBOARDING_STEPS.length - 1
                      ? 'bg-gradient-to-r from-green-600 to-green-700 text-white hover:from-green-700 hover:to-green-800'
                      : 'bg-gradient-to-r from-blue-600 to-indigo-600 text-white hover:from-blue-700 hover:to-indigo-700'
                    } shadow-md hover:shadow-lg`}
                >
                  <span className="hidden sm:inline">
                    {currentStep === ONBOARDING_STEPS.length - 1 ? 'Complete' : 'Next'}
                  </span>
                  <ChevronRight className="h-5 w-5" />
                </button>
              </div>
            </div>

            <div className="bg-white rounded-b-xl shadow-xl p-8">
              <AnimatePresence mode="wait">
                <motion.div
                  key={currentStep}
                  initial={{ opacity: 0, x: 20 }}
                  animate={{ opacity: 1, x: 0 }}
                  exit={{ opacity: 0, x: -20 }}
                  transition={{ duration: 0.3 }}
                  drag="x"
                  dragConstraints={{ left: 0, right: 0 }}
                  dragElastic={0.2}
                  onDragEnd={(e, { offset, velocity }) => {
                    const swipeThreshold = 100;
                    const swipeVelocityThreshold = 500;

                    // Swipe left to go forward
                    if (offset.x < -swipeThreshold || velocity.x < -swipeVelocityThreshold) {
                      if (currentStep < ONBOARDING_STEPS.length - 1) {
                        handleNextStep({});
                      }
                    }
                    // Swipe right to go back
                    else if (offset.x > swipeThreshold || velocity.x > swipeVelocityThreshold) {
                      handlePreviousStep();
                    }
                  }}
                  className="touch-pan-y"
                >
                  {currentStep === ONBOARDING_STEPS.length - 1 ? (
                    <CurrentStepComponent
                      onSubmit={handleSubmitOnboarding}
                      onPrevious={handlePreviousStep}
                      data={onboardingData}
                      {...({} as any)}
                    />
                  ) : (
                    <CurrentStepComponent
                      onNext={handleNextStep}
                      onPrevious={handlePreviousStep}
                      data={onboardingData}
                      {...({} as any)}
                    />
                  )}
                </motion.div>
              </AnimatePresence>

              {/* Enhanced Navigation Footer */}
              <div className="mt-8 pt-6 border-t">
                <div className="flex justify-between items-center">
                  {/* Quick Navigation */}
                  <div className="flex items-center gap-2">
                    <span className="text-sm text-gray-500">Quick jump:</span>
                    <div className="flex gap-1">
                      {ONBOARDING_STEPS.map((step, index) => (
                        <button
                          key={step.id}
                          onClick={() => handleStepJump(index)}
                          disabled={!completedSteps.has(index) && index !== completedSteps.size}
                          className={`w-8 h-8 rounded-full text-xs font-medium transition-all ${index === currentStep
                              ? 'bg-blue-600 text-white'
                              : completedSteps.has(index)
                                ? 'bg-green-100 text-green-700 hover:bg-green-200'
                                : 'bg-gray-100 text-gray-400 cursor-not-allowed'
                            }`}
                          title={step.title}
                        >
                          {index + 1}
                        </button>
                      ))}
                    </div>
                  </div>

                  {/* Primary Navigation Buttons */}
                  <div className="flex gap-3">
                    <button
                      onClick={handlePreviousStep}
                      disabled={currentStep === 0}
                      className={`flex items-center px-6 py-3 rounded-lg font-medium transition-all ${currentStep === 0
                          ? 'bg-gray-100 text-gray-400 cursor-not-allowed'
                          : 'glass-button hover:shadow-md'
                        }`}
                    >
                      <ArrowLeft className="mr-2 h-5 w-5" />
                      Previous
                    </button>

                    {currentStep === ONBOARDING_STEPS.length - 1 ? (
                      <button
                        onClick={handleSubmitOnboarding}
                        className="flex items-center px-8 py-3 bg-gradient-to-r from-green-600 to-green-700 text-white rounded-lg font-medium hover:from-green-700 hover:to-green-800 transition-all shadow-md hover:shadow-lg"
                      >
                        Complete Setup
                        <CheckCircle className="ml-2 h-5 w-5" />
                      </button>
                    ) : (
                      <button
                        onClick={() => handleNextStep({})}
                        className="flex items-center px-8 py-3 bg-gradient-to-r from-blue-600 to-indigo-600 text-white rounded-lg font-medium hover:from-blue-700 hover:to-indigo-700 transition-all shadow-md hover:shadow-lg"
                      >
                        Next Step
                        <ArrowRight className="ml-2 h-5 w-5" />
                      </button>
                    )}
                  </div>
                </div>

                {/* Navigation hints */}
                <div className="mt-4 flex flex-col items-center gap-2">
                  {/* Desktop keyboard shortcuts */}
                  <div className="hidden sm:flex items-center justify-center gap-4 text-xs text-gray-500">
                    <span className="flex items-center gap-1">
                      <kbd className="px-2 py-1 bg-gray-100 rounded">←</kbd>
                      Previous
                    </span>
                    <span className="flex items-center gap-1">
                      <kbd className="px-2 py-1 bg-gray-100 rounded">→</kbd>
                      Next
                    </span>
                    <span className="flex items-center gap-1">
                      <kbd className="px-2 py-1 bg-gray-100 rounded">⌘S</kbd>
                      Save
                    </span>
                  </div>

                  {/* Mobile swipe hint */}
                  <div className="sm:hidden flex items-center gap-2 text-xs text-gray-500">
                    <motion.div
                      animate={{ x: [-5, 5, -5] }}
                      transition={{ repeat: Infinity, duration: 2 }}
                      className="flex items-center gap-1"
                    >
                      <ChevronLeft className="h-3 w-3" />
                      <span>Swipe to navigate</span>
                      <ChevronRight className="h-3 w-3" />
                    </motion.div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Navigation Warning Modal */}
          <AnimatePresence>
            {showNavigationWarning && (
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 glass-overlay"
                onClick={() => setShowNavigationWarning(false)}
              >
                <motion.div
                  initial={{ scale: 0.9, opacity: 0 }}
                  animate={{ scale: 1, opacity: 1 }}
                  exit={{ scale: 0.9, opacity: 0 }}
                  className="glass-modal rounded-xl p-6 max-w-md mx-4"
                  onClick={(e) => e.stopPropagation()}
                >
                  <div className="flex items-start gap-3">
                    <AlertCircle className="h-6 w-6 text-yellow-600 flex-shrink-0 mt-1" />
                    <div className="flex-1">
                      <h3 className="text-lg font-semibold text-gray-900 mb-2">
                        Unsaved Changes
                      </h3>
                      <p className="text-sm text-gray-600 mb-4">
                        You have unsaved changes on this step. Would you like to save them before navigating away?
                      </p>
                      <div className="flex gap-3 justify-end">
                        <button
                          onClick={() => {
                            setShowNavigationWarning(false);
                            setUnsavedChanges(false);
                            setCurrentStep(currentStep - 1);
                          }}
                          className="px-4 py-2 text-sm font-medium text-gray-700 glass-button rounded-lg"
                        >
                          Discard Changes
                        </button>
                        <button
                          onClick={() => {
                            // Save and navigate
                            handleNextStep({});
                            setShowNavigationWarning(false);
                          }}
                          className="px-4 py-2 text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 rounded-lg"
                        >
                          Save & Continue
                        </button>
                      </div>
                    </div>
                  </div>
                </motion.div>
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      </div>
    </OnboardingProvider>
  );
}
