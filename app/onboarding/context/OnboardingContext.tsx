'use client';

import React, { createContext, useContext, useState, ReactNode } from 'react';

export interface OnboardingData {
  businessInfo?: any;
  verification?: any;
  studioProfile?: any;
  services?: any;
  payment?: any;
  calendar?: any;
  [key: string]: any;
}

interface OnboardingContextType {
  onboardingData: OnboardingData;
  setOnboardingData: React.Dispatch<React.SetStateAction<OnboardingData>>;
  updateOnboardingData: (section: string, data: any) => void;
}

const OnboardingContext = createContext<OnboardingContextType | undefined>(undefined);

export function OnboardingProvider({ 
  children, 
  value 
}: { 
  children: ReactNode;
  value?: Partial<OnboardingContextType>;
}) {
  const [onboardingData, setOnboardingData] = useState<OnboardingData>({});

  const updateOnboardingData = (section: string, data: any) => {
    setOnboardingData(prev => ({
      ...prev,
      [section]: data
    }));
  };

  const contextValue: OnboardingContextType = {
    onboardingData,
    setOnboardingData,
    updateOnboardingData,
    ...value
  };

  return (
    <OnboardingContext.Provider value={contextValue}>
      {children}
    </OnboardingContext.Provider>
  );
}

export function useOnboarding() {
  const context = useContext(OnboardingContext);
  if (context === undefined) {
    throw new Error('useOnboarding must be used within an OnboardingProvider');
  }
  return context;
}