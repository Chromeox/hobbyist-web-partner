'use client';

import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import BusinessInfoStep from './steps/BusinessInfoStep';
import VerificationStep from './steps/VerificationStep';
import StudioProfileStep from './steps/StudioProfileStep';
import ServicesStep from './steps/ServicesStep';
import PaymentSetupStep from './steps/PaymentSetupStep';
import ReviewStep from './steps/ReviewStep';
import { OnboardingProvider } from './context/OnboardingContext';
import ProgressIndicator from './components/ProgressIndicator';
import { CheckCircle, ArrowRight, ArrowLeft } from 'lucide-react';

const ONBOARDING_STEPS = [
  { id: 'business-info', title: 'Business Information', component: BusinessInfoStep },
  { id: 'verification', title: 'Verification', component: VerificationStep },
  { id: 'studio-profile', title: 'Studio Profile', component: StudioProfileStep },
  { id: 'services', title: 'Services & Classes', component: ServicesStep },
  { id: 'payment', title: 'Payment Setup', component: PaymentSetupStep },
  { id: 'review', title: 'Review & Submit', component: ReviewStep }
];

export default function OnboardingWizard() {
  const [currentStep, setCurrentStep] = useState(0);
  const [completedSteps, setCompletedSteps] = useState<Set<number>>(new Set());
  const [onboardingData, setOnboardingData] = useState({});

  const CurrentStepComponent = ONBOARDING_STEPS[currentStep].component;

  const handleNextStep = (stepData: any) => {
    setOnboardingData(prev => ({ ...prev, ...stepData }));
    setCompletedSteps(prev => new Set(Array.from(prev).concat(currentStep)));
    
    if (currentStep < ONBOARDING_STEPS.length - 1) {
      setCurrentStep(currentStep + 1);
    }
  };

  const handlePreviousStep = () => {
    if (currentStep > 0) {
      setCurrentStep(currentStep - 1);
    }
  };

  const handleSubmitOnboarding = async () => {
    try {
      const response = await fetch('/api/partners/onboarding', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(onboardingData)
      });

      if (response.ok) {
        window.location.href = '/dashboard';
      }
    } catch (error) {
      console.error('Onboarding submission error:', error);
    }
  };

  const progressPercentage = ((currentStep + 1) / ONBOARDING_STEPS.length) * 100;

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

          {/* Progress Indicator */}
          <ProgressIndicator 
            steps={ONBOARDING_STEPS}
            currentStep={currentStep}
            completedSteps={completedSteps}
          />

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

          {/* Step Content */}
          <div className="max-w-4xl mx-auto">
            <div className="bg-white rounded-xl shadow-xl p-8">
              <AnimatePresence mode="wait">
                <motion.div
                  key={currentStep}
                  initial={{ opacity: 0, x: 20 }}
                  animate={{ opacity: 1, x: 0 }}
                  exit={{ opacity: 0, x: -20 }}
                  transition={{ duration: 0.3 }}
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

              {/* Navigation Buttons */}
              <div className="flex justify-between mt-8 pt-6 border-t">
                <button
                  onClick={handlePreviousStep}
                  disabled={currentStep === 0}
                  className={`flex items-center px-6 py-3 rounded-lg font-medium transition-colors ${
                    currentStep === 0
                      ? 'bg-gray-100 text-gray-400 cursor-not-allowed'
                      : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
                  }`}
                >
                  <ArrowLeft className="mr-2 h-5 w-5" />
                  Previous
                </button>

                {currentStep === ONBOARDING_STEPS.length - 1 ? (
                  <button
                    onClick={handleSubmitOnboarding}
                    className="flex items-center px-8 py-3 bg-gradient-to-r from-blue-600 to-indigo-600 text-white rounded-lg font-medium hover:from-blue-700 hover:to-indigo-700 transition-colors"
                  >
                    Complete Setup
                    <CheckCircle className="ml-2 h-5 w-5" />
                  </button>
                ) : (
                  <button
                    onClick={() => handleNextStep({})}
                    className="flex items-center px-8 py-3 bg-gradient-to-r from-blue-600 to-indigo-600 text-white rounded-lg font-medium hover:from-blue-700 hover:to-indigo-700 transition-colors"
                  >
                    Next Step
                    <ArrowRight className="ml-2 h-5 w-5" />
                  </button>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>
    </OnboardingProvider>
  );
}