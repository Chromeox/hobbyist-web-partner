'use client';

import React from 'react';
import { CheckCircle } from 'lucide-react';

interface ReviewStepProps {
  onSubmit: () => void;
  onPrevious: () => void;
  data: any;
}

export default function ReviewStep({ onSubmit, onPrevious, data }: ReviewStepProps) {
  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold text-gray-900 mb-2">Review & Submit</h2>
        <p className="text-gray-600">Review your information before submitting</p>
      </div>

      <div className="bg-white border rounded-lg p-6">
        <div className="flex items-center mb-4">
          <CheckCircle className="h-6 w-6 text-green-600 mr-3" />
          <h3 className="text-lg font-semibold text-gray-900">Setup Complete!</h3>
        </div>
        
        <p className="text-gray-600 mb-4">
          Your studio profile is ready to go live. Click submit to complete the onboarding process.
        </p>

        <div className="space-y-2 text-sm">
          <p><strong>Business:</strong> {data.businessInfo?.businessName}</p>
          <p><strong>Email:</strong> {data.businessInfo?.businessEmail}</p>
          <p><strong>Location:</strong> {data.businessInfo?.address?.city}, {data.businessInfo?.address?.state}</p>
        </div>
      </div>

      <button
        onClick={onSubmit}
        className="w-full py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors font-medium"
      >
        Complete Setup & Launch Studio
      </button>
    </div>
  );
}