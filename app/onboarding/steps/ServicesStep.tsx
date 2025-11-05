'use client';

import React, { useState } from 'react';

interface ServicesStepProps {
  onNext: (data: any) => void;
  onPrevious: () => void;
  data: any;
}

export default function ServicesStep({ onNext, onPrevious, data }: ServicesStepProps) {
  const [services, setServices] = useState(data.services || {});

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onNext({ services });
  };

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold text-gray-900 mb-2">Services & Classes</h2>
        <p className="text-gray-600">Configure your class offerings and pricing</p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        <div className="bg-blue-50 p-6 rounded-lg">
          <p className="text-blue-800">You can configure your classes and services after completing onboarding.</p>
        </div>

        {/* Navigation Buttons */}
        <div className="mt-8 flex justify-between">
          <button
            type="button"
            onClick={onPrevious}
            className="px-6 py-3 border border-gray-300 text-gray-700 rounded-lg font-medium hover:bg-gray-50 transition-all"
          >
            Back
          </button>
          <button
            type="submit"
            className="px-8 py-3 bg-gradient-to-r from-blue-600 to-indigo-600 text-white rounded-lg font-medium hover:from-blue-700 hover:to-indigo-700 transition-all shadow-md hover:shadow-lg"
          >
            Continue
          </button>
        </div>
      </form>
    </div>
  );
}