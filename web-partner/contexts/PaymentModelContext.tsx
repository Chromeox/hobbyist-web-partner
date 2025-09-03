'use client';

import React, { createContext, useContext, useState } from 'react';

type PaymentModel = 'credit-based' | 'subscription' | 'hybrid';

interface PaymentModelContextType {
  paymentModel: PaymentModel;
  setPaymentModel: (model: PaymentModel) => void;
  creditPrice: number;
  setCreditPrice: (price: number) => void;
  subscriptionPrice: number;
  setSubscriptionPrice: (price: number) => void;
}

const PaymentModelContext = createContext<PaymentModelContextType | undefined>(undefined);

export function PaymentModelProvider({ children }: { children: React.ReactNode }) {
  const [paymentModel, setPaymentModel] = useState<PaymentModel>('credit-based');
  const [creditPrice, setCreditPrice] = useState(5);
  const [subscriptionPrice, setSubscriptionPrice] = useState(29.99);

  return (
    <PaymentModelContext.Provider
      value={{
        paymentModel,
        setPaymentModel,
        creditPrice,
        setCreditPrice,
        subscriptionPrice,
        setSubscriptionPrice,
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