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

      <form onSubmit={handleSubmit}>
        <div className="bg-blue-50 p-6 rounded-lg">
          <p className="text-blue-800">You can configure your classes and services after completing onboarding.</p>
        </div>
      </form>
    </div>
  );
}