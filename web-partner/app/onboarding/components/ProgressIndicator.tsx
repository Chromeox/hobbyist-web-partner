'use client';

import React, { useEffect, useState } from 'react';
import { CheckCircle } from 'lucide-react';
import { motion } from 'framer-motion';

interface Step {
  id: string;
  title: string;
  description?: string;
  estimatedTime?: string;
}

interface ProgressIndicatorProps {
  steps: Step[];
  currentStep: number;
  completedSteps: Set<number>;
  showDetails?: boolean;
}

export default function ProgressIndicator({ 
  steps, 
  currentStep, 
  completedSteps,
  showDetails = true 
}: ProgressIndicatorProps) {
  const [animatedProgress, setAnimatedProgress] = useState(0);
  
  // Calculate overall progress percentage
  const progressPercentage = Math.round(((completedSteps.size) / steps.length) * 100);
  
  // Animate progress bar
  useEffect(() => {
    const timer = setTimeout(() => {
      setAnimatedProgress(progressPercentage);
    }, 100);
    return () => clearTimeout(timer);
  }, [progressPercentage]);
  
  return (
    <div className="max-w-4xl mx-auto mb-8">
      {/* Progress Bar Header */}
      <div className="mb-6">
        <div className="flex items-center justify-between mb-2">
          <div>
            <h3 className="text-lg font-semibold text-gray-900">
              Step {currentStep + 1} of {steps.length}: {steps[currentStep]?.title}
            </h3>
            {steps[currentStep]?.description && (
              <p className="text-sm text-gray-600 mt-1">{steps[currentStep].description}</p>
            )}
          </div>
          <div className="text-right">
            <p className="text-2xl font-bold text-blue-600">{animatedProgress}%</p>
            <p className="text-sm text-gray-500">Complete</p>
          </div>
        </div>
        
        {/* Animated Progress Bar */}
        <div className="relative h-2 bg-gray-200 rounded-full overflow-hidden">
          <motion.div
            className="absolute inset-y-0 left-0 bg-gradient-to-r from-blue-500 to-blue-600 rounded-full"
            initial={{ width: 0 }}
            animate={{ width: `${animatedProgress}%` }}
            transition={{ duration: 0.5, ease: "easeOut" }}
          />
        </div>
      </div>
      
      {/* Desktop Steps Indicator - Restructured */}
      <div className="hidden md:block">
        {/* Circles and Lines Container */}
        <div className="relative">
          <div className="flex items-center justify-between">
            {steps.map((step, index) => (
              <React.Fragment key={step.id}>
                {/* Step Circle */}
                <div className="relative z-10">
                  <motion.div 
                    className="flex items-center justify-center"
                    initial={{ scale: 0.8, opacity: 0 }}
                    animate={{ scale: 1, opacity: 1 }}
                    transition={{ delay: index * 0.1 }}
                  >
                    <div
                      className={`w-12 h-12 rounded-full border-2 flex items-center justify-center transition-all duration-300 ${
                        completedSteps.has(index)
                          ? 'bg-green-600 border-green-600 text-white shadow-lg shadow-green-200'
                          : currentStep === index
                          ? 'bg-blue-600 border-blue-600 text-white shadow-lg shadow-blue-200 animate-pulse'
                          : 'bg-white border-gray-300 text-gray-500'
                      }`}
                    >
                      {completedSteps.has(index) ? (
                        <motion.div
                          initial={{ scale: 0 }}
                          animate={{ scale: 1 }}
                          transition={{ type: "spring", stiffness: 500, damping: 15 }}
                        >
                          <CheckCircle className="w-6 h-6" />
                        </motion.div>
                      ) : (
                        <span className="text-sm font-semibold">{index + 1}</span>
                      )}
                    </div>
                  </motion.div>
                </div>

                {/* Connecting Line - Positioned Absolutely */}
                {index < steps.length - 1 && (
                  <div 
                    className="absolute top-6 h-0.5"
                    style={{
                      left: `calc(${(100 / steps.length) * index}% + 30px)`,
                      width: `calc(${100 / steps.length}% - 60px)`
                    }}
                  >
                    <div className="relative h-full">
                      <div className="absolute inset-0 bg-gray-200" />
                      <motion.div
                        className="absolute inset-0 bg-gradient-to-r from-green-500 to-green-600"
                        initial={{ width: 0 }}
                        animate={{ 
                          width: completedSteps.has(index) ? '100%' : '0%'
                        }}
                        transition={{ 
                          duration: 0.5, 
                          delay: completedSteps.has(index) ? 0.3 : 0,
                          ease: "easeInOut"
                        }}
                      />
                      {/* Active pulse animation */}
                      {currentStep === index + 1 && !completedSteps.has(index) && (
                        <motion.div
                          className="absolute inset-0 bg-blue-400 opacity-50"
                          animate={{ 
                            width: ['0%', '100%'],
                            opacity: [0.5, 0]
                          }}
                          transition={{ 
                            duration: 2,
                            repeat: Infinity,
                            ease: "easeOut"
                          }}
                        />
                      )}
                    </div>
                  </div>
                )}
              </React.Fragment>
            ))}
          </div>
        </div>

        {/* Labels Container - Separate Row */}
        <div className="flex justify-between mt-4">
          {steps.map((step, index) => (
            <div 
              key={`label-${step.id}`} 
              className="text-center"
              style={{ width: `${100 / steps.length}%` }}
            >
              <p
                className={`text-xs font-medium transition-colors duration-300 px-1 ${
                  completedSteps.has(index) 
                    ? 'text-green-700'
                    : currentStep === index
                    ? 'text-blue-700 font-semibold'
                    : 'text-gray-500'
                }`}
              >
                {step.title}
              </p>
              {showDetails && step.estimatedTime && currentStep === index && (
                <p className="text-xs text-gray-500 mt-1">{step.estimatedTime}</p>
              )}
            </div>
          ))}
        </div>
      </div>
      
      {/* Mobile-Optimized Compact View */}
      <div className="md:hidden">
        <div className="bg-gray-50 rounded-lg p-4">
          <div className="flex items-center justify-between mb-2">
            <span className="text-sm font-medium text-gray-600">Progress</span>
            <span className="text-sm font-bold text-blue-600">
              {completedSteps.size}/{steps.length} steps
            </span>
          </div>
          <div className="space-y-2">
            {steps.map((step, index) => (
              <div key={step.id} className="flex items-center gap-2">
                <div className={`w-5 h-5 rounded-full flex items-center justify-center ${
                  completedSteps.has(index)
                    ? 'bg-green-600'
                    : currentStep === index
                    ? 'bg-blue-600 animate-pulse'
                    : 'bg-gray-300'
                }`}>
                  {completedSteps.has(index) && (
                    <CheckCircle className="w-3 h-3 text-white" />
                  )}
                </div>
                <span className={`text-sm ${
                  currentStep === index ? 'font-semibold text-gray-900' : 'text-gray-600'
                }`}>
                  {step.title}
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}