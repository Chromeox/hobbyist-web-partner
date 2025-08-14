'use client';

import React from 'react';
import { CheckCircle } from 'lucide-react';

interface Step {
  id: string;
  title: string;
}

interface ProgressIndicatorProps {
  steps: Step[];
  currentStep: number;
  completedSteps: Set<number>;
}

export default function ProgressIndicator({ steps, currentStep, completedSteps }: ProgressIndicatorProps) {
  return (
    <div className="max-w-4xl mx-auto mb-8">
      <div className="flex items-center justify-between">
        {steps.map((step, index) => (
          <div key={step.id} className="flex items-center flex-1">
            {/* Step Circle */}
            <div className="relative flex items-center justify-center">
              <div
                className={`w-10 h-10 rounded-full border-2 flex items-center justify-center transition-all duration-300 ${
                  completedSteps.has(index)
                    ? 'bg-green-600 border-green-600 text-white'
                    : currentStep === index
                    ? 'bg-blue-600 border-blue-600 text-white'
                    : 'bg-white border-gray-300 text-gray-500'
                }`}
              >
                {completedSteps.has(index) ? (
                  <CheckCircle className="w-5 h-5" />
                ) : (
                  <span className="text-sm font-semibold">{index + 1}</span>
                )}
              </div>
              
              {/* Step Label */}
              <div className="absolute top-12 left-1/2 transform -translate-x-1/2 w-32 text-center">
                <p
                  className={`text-xs font-medium ${
                    completedSteps.has(index) || currentStep === index
                      ? 'text-gray-900'
                      : 'text-gray-500'
                  }`}
                >
                  {step.title}
                </p>
              </div>
            </div>

            {/* Connecting Line */}
            {index < steps.length - 1 && (
              <div className="flex-1 h-0.5 mx-4 relative">
                <div className="absolute inset-0 bg-gray-200" />
                <div
                  className={`absolute inset-0 transition-all duration-300 ${
                    completedSteps.has(index) ? 'bg-green-600' : 'bg-gray-200'
                  }`}
                  style={{
                    width: completedSteps.has(index) ? '100%' : '0%',
                  }}
                />
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}