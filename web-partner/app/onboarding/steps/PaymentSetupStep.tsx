'use client';

import React, { useState } from 'react';

interface PaymentSetupStepProps {
  onNext: (data: any) => void;
  onPrevious: () => void;
  data: any;
}

export default function PaymentSetupStep({ onNext, onPrevious, data }: PaymentSetupStepProps) {
  const [payment, setPayment] = useState(data.payment || {});

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onNext({ payment });
  };

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold text-gray-900 mb-2">Payment Setup</h2>
        <p className="text-gray-600">Configure payment processing for your studio</p>
      </div>

      <form onSubmit={handleSubmit}>
        <div className="bg-green-50 p-6 rounded-lg">
          <p className="text-green-800">Payment setup will be completed after onboarding with Stripe integration.</p>
        </div>
      </form>
    </div>
  );
}