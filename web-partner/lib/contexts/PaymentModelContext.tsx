'use client';

import React, { createContext, useContext, useState, useEffect } from 'react';

type PaymentMode = 'credits' | 'cash' | 'hybrid';

interface PaymentModelSettings {
  mode: PaymentMode;
  creditPacksEnabled: boolean;
  cashPaymentsEnabled: boolean;
  defaultCreditsPerClass: number;
  allowMixedPayments: boolean;
  creditExpiration: number | null;
  commissionRate: number;
}

interface PaymentModelContextType {
  paymentModel: PaymentModelSettings;
  updatePaymentModel: (settings: Partial<PaymentModelSettings>) => void;
  isCreditsEnabled: boolean;
  isCashEnabled: boolean;
  isHybridMode: boolean;
}

const PaymentModelContext = createContext<PaymentModelContextType | undefined>(undefined);

export function PaymentModelProvider({ children }: { children: React.ReactNode }) {
  // Default to hybrid mode for maximum flexibility
  const [paymentModel, setPaymentModel] = useState<PaymentModelSettings>({
    mode: 'hybrid',
    creditPacksEnabled: true,
    cashPaymentsEnabled: true,
    defaultCreditsPerClass: 2,
    allowMixedPayments: true,
    creditExpiration: 365,
    commissionRate: 15
  });

  // Load settings from localStorage on mount
  useEffect(() => {
    const savedSettings = localStorage.getItem('paymentModelSettings');
    if (savedSettings) {
      try {
        setPaymentModel(JSON.parse(savedSettings));
      } catch (error) {
        console.error('Failed to load payment model settings:', error);
      }
    }
  }, []);

  // Save settings to localStorage whenever they change
  useEffect(() => {
    localStorage.setItem('paymentModelSettings', JSON.stringify(paymentModel));
  }, [paymentModel]);

  const updatePaymentModel = (settings: Partial<PaymentModelSettings>) => {
    setPaymentModel(prev => ({ ...prev, ...settings }));
  };

  // Computed properties for easy access
  const isCreditsEnabled = paymentModel.mode === 'credits' || paymentModel.mode === 'hybrid';
  const isCashEnabled = paymentModel.mode === 'cash' || paymentModel.mode === 'hybrid';
  const isHybridMode = paymentModel.mode === 'hybrid';

  return (
    <PaymentModelContext.Provider 
      value={{
        paymentModel,
        updatePaymentModel,
        isCreditsEnabled,
        isCashEnabled,
        isHybridMode
      }}
    >
      {children}
    </PaymentModelContext.Provider>
  );
}

export function usePaymentModel() {
  const context = useContext(PaymentModelContext);
  if (context === undefined) {
    throw new Error('usePaymentModel must be used within a PaymentModelProvider');
  }
  return context;
}