'use client';

import React, { useState } from 'react';
import { motion } from 'framer-motion';
import {
  Calendar,
  Clock,
  CheckCircle,
  ArrowRight,
  Zap,
  TrendingUp,
  Users,
  SkipForward,
  Upload
} from 'lucide-react';
import PrivacyPolicyBanner from '@/components/common/PrivacyPolicyBanner';

interface CalendarSetupStepProps {
  onNext: (data: any) => void;
  onPrevious: () => void;
  data: any;
}

// Google Calendar Logo Component
const GoogleCalendarLogo = () => (
  <svg viewBox="0 0 48 48" className="h-8 w-8">
    <path fill="#1976d2" d="M37 5H11c-3.3 0-6 2.7-6 6v26c0 3.3 2.7 6 6 6h26c3.3 0 6-2.7 6-6V11c0-3.3-2.7-6-6-6z"/>
    <path fill="#fff" d="M37 5H11c-3.3 0-6 2.7-6 6v26c0 3.3 2.7 6 6 6h26c3.3 0 6-2.7 6-6V11c0-3.3-2.7-6-6-6zm-1 34H12c-2.2 0-4-1.8-4-4V13c0-2.2 1.8-4 4-4h24c2.2 0 4 1.8 4 4v22c0 2.2-1.8 4-4 4z"/>
    <path fill="#1976d2" d="M24 16h8v3h-8v-3zm-8 7h16v3H16v-3zm0 7h12v3H16v-3z"/>
    <path fill="#e53935" d="M20 12h8v7h-8z"/>
    <path fill="#fff" d="M22 14h4v3h-4z"/>
  </svg>
);

// Apple Calendar Logo Component
const AppleCalendarLogo = () => (
  <svg viewBox="0 0 48 48" className="h-8 w-8">
    <defs>
      <linearGradient id="appleGradient" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stopColor="#ff6b6b"/>
        <stop offset="100%" stopColor="#ee5a52"/>
      </linearGradient>
    </defs>
    <rect x="6" y="8" width="36" height="32" rx="6" ry="6" fill="url(#appleGradient)"/>
    <rect x="6" y="8" width="36" height="10" rx="6" ry="6" fill="#fff"/>
    <circle cx="16" cy="13" r="1.5" fill="#666"/>
    <circle cx="32" cy="13" r="1.5" fill="#666"/>
    <rect x="10" y="4" width="2" height="8" rx="1" ry="1" fill="#666"/>
    <rect x="36" y="4" width="2" height="8" rx="1" ry="1" fill="#666"/>
    <text x="24" y="32" textAnchor="middle" fill="#fff" fontSize="14" fontWeight="bold" fontFamily="Arial">23</text>
  </svg>
);

export default function CalendarSetupStep({ onNext, onPrevious, data }: CalendarSetupStepProps) {
  const [setupMode, setSetupMode] = useState<'overview' | 'setup' | 'completed'>('overview');
  const [selectedProvider, setSelectedProvider] = useState<string | null>(null);
  const [isConnecting, setIsConnecting] = useState(false);
  const [isSkipping, setIsSkipping] = useState(false);

  const calendarProviders = [
    {
      id: 'google',
      name: 'Google Calendar',
      logo: <GoogleCalendarLogo />,
      description: 'Sync with your Google Calendar events and schedule',
      popular: true,
      estimatedTime: '2 minutes',
      benefits: ['Automatic event sync', 'Real-time updates', 'Cross-platform access']
    },
    {
      id: 'apple',
      name: 'Apple Calendar',
      logo: <AppleCalendarLogo />,
      description: 'Connect with your iCloud calendar and Apple devices',
      popular: true,
      estimatedTime: '2 minutes',
      benefits: ['iCloud sync', 'Apple ecosystem integration', 'Privacy focused']
    }
  ];

  const benefits = [
    {
      icon: <Clock className="h-5 w-5" />,
      title: 'Seamless Migration',
      description: 'Import all your existing events and schedules instantly'
    },
    {
      icon: <TrendingUp className="h-5 w-5" />,
      title: 'Smart Insights',
      description: 'Get AI-powered recommendations to optimize your schedule'
    },
    {
      icon: <Users className="h-5 w-5" />,
      title: 'Student Continuity',
      description: 'Keep all your existing calendar data and relationships'
    }
  ];

  const handleSkip = () => {
    setIsSkipping(true);
    setTimeout(() => {
      onNext({ calendarSetup: { skipped: true, reason: 'user_choice' } });
    }, 1000);
  };

  const handleContinueWithSetup = () => {
    setSetupMode('setup');
  };

  const handleConnectProvider = async (providerId: string) => {
    setSelectedProvider(providerId);
    setIsConnecting(true);

    // Simulate connection process
    setTimeout(() => {
      setSetupMode('completed');
      setTimeout(() => {
        onNext({
          calendarSetup: {
            completed: true,
            provider: providerId,
            connectedAt: new Date().toISOString()
          }
        });
      }, 2000);
    }, 2000);
  };

  if (setupMode === 'completed') {
    return (
      <div className="text-center">
        <motion.div
          initial={{ scale: 0 }}
          animate={{ scale: 1 }}
          transition={{ type: "spring", stiffness: 200 }}
          className="w-20 h-20 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-6"
        >
          <CheckCircle className="h-10 w-10 text-green-600" />
        </motion.div>

        <h2 className="text-2xl font-bold text-gray-900 mb-4">
          Calendar Setup Complete! 🎉
        </h2>
        <p className="text-gray-600 mb-6">
          Your calendar data has been imported successfully. You'll now get intelligent
          recommendations based on your actual booking patterns.
        </p>

        <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-6">
          <div className="flex items-center gap-2 text-blue-800 font-medium mb-2">
            <Zap className="h-5 w-5" />
            Next: Smart Studio Intelligence
          </div>
          <p className="text-sm text-blue-700">
            Now that we have your calendar data, we can show you powerful insights
            to optimize your studio operations and increase revenue.
          </p>
        </div>

        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 1 }}
          className="text-sm text-gray-500"
        >
          Proceeding to intelligence setup...
        </motion.div>
      </div>
    );
  }

  if (setupMode === 'setup') {
    return (
      <div className="space-y-8">
        <div className="text-center">
          <motion.div
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            transition={{ type: "spring", stiffness: 200 }}
            className="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-4"
          >
            <Calendar className="h-8 w-8 text-blue-600" />
          </motion.div>

          <h2 className="text-2xl font-bold text-gray-900 mb-2">
            Connect Your Calendar
          </h2>
          <p className="text-gray-600 max-w-lg mx-auto">
            Choose your preferred calendar to sync your existing events and schedules
          </p>
        </div>

        {/* Calendar Providers */}
        <div className="max-w-2xl mx-auto">
          <div className="grid md:grid-cols-2 gap-6">
            {calendarProviders.map((provider, index) => (
              <motion.div
                key={provider.id}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: index * 0.1 }}
                className="group"
              >
                <button
                  onClick={() => handleConnectProvider(provider.id)}
                  disabled={isConnecting && selectedProvider !== provider.id}
                  className={`w-full p-6 border-2 rounded-xl transition-all duration-200 text-left ${
                    isConnecting && selectedProvider === provider.id
                      ? 'border-blue-500 bg-blue-50'
                      : isConnecting
                      ? 'border-gray-200 bg-gray-50 opacity-50'
                      : 'border-gray-200 hover:border-blue-300 hover:shadow-lg group-hover:scale-105'
                  }`}
                >
                  <div className="flex items-start gap-4">
                    <div className="flex-shrink-0">
                      {isConnecting && selectedProvider === provider.id ? (
                        <motion.div
                          animate={{ rotate: 360 }}
                          transition={{ duration: 1, repeat: Infinity, ease: "linear" }}
                          className="w-8 h-8 border-2 border-blue-500 border-t-transparent rounded-full"
                        />
                      ) : (
                        provider.logo
                      )}
                    </div>

                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-1">
                        <h3 className="font-semibold text-gray-900">{provider.name}</h3>
                        {provider.popular && (
                          <span className="px-2 py-1 bg-blue-100 text-blue-800 text-xs font-medium rounded-full">
                            Popular
                          </span>
                        )}
                      </div>

                      <p className="text-sm text-gray-600 mb-3">{provider.description}</p>

                      <div className="space-y-1">
                        {provider.benefits.map((benefit, idx) => (
                          <div key={idx} className="flex items-center gap-2 text-xs text-gray-500">
                            <CheckCircle className="h-3 w-3 text-green-500" />
                            {benefit}
                          </div>
                        ))}
                      </div>

                      <div className="mt-3 text-xs text-gray-500">
                        ⏱️ Setup time: {provider.estimatedTime}
                      </div>
                    </div>
                  </div>

                  {isConnecting && selectedProvider === provider.id ? (
                    <div className="mt-4 text-sm text-blue-600 font-medium">
                      Connecting to {provider.name}...
                    </div>
                  ) : (
                    <div className="mt-4 text-sm text-blue-600 font-medium group-hover:text-blue-700">
                      Connect {provider.name} →
                    </div>
                  )}
                </button>
              </motion.div>
            ))}
          </div>
        </div>

        {/* Navigation */}
        <div className="flex justify-between pt-6">
          <button
            onClick={() => setSetupMode('overview')}
            disabled={isConnecting}
            className="px-4 py-2 text-gray-600 hover:text-gray-800 font-medium disabled:opacity-50"
          >
            ← Back
          </button>
          <button
            onClick={handleSkip}
            disabled={isConnecting}
            className="flex items-center gap-2 px-4 py-2 text-gray-600 hover:text-gray-800 font-medium disabled:opacity-50"
          >
            Skip for now
            <SkipForward className="h-4 w-4" />
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="text-center">
        <motion.div
          initial={{ scale: 0 }}
          animate={{ scale: 1 }}
          transition={{ type: "spring", stiffness: 200 }}
          className="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-4"
        >
          <Calendar className="h-8 w-8 text-blue-600" />
        </motion.div>

        <h2 className="text-2xl font-bold text-gray-900 mb-2">
          Import Your Existing Schedule
        </h2>
        <p className="text-gray-600 max-w-2xl mx-auto">
          Seamlessly migrate from your current booking system. We'll import your classes,
          students, and booking history to get you started immediately.
        </p>
      </div>

      {/* Benefits Grid */}
      <div className="grid md:grid-cols-3 gap-6">
        {benefits.map((benefit, index) => (
          <motion.div
            key={benefit.title}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: index * 0.1 }}
            className="text-center p-4"
          >
            <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center mx-auto mb-3 text-blue-600">
              {benefit.icon}
            </div>
            <h3 className="font-semibold text-gray-900 mb-2">{benefit.title}</h3>
            <p className="text-sm text-gray-600">{benefit.description}</p>
          </motion.div>
        ))}
      </div>

      {/* Calendar Providers Preview */}
      <div className="bg-gradient-to-br from-gray-50 to-gray-100 rounded-xl p-8">
        <h3 className="font-semibold text-gray-900 mb-6 text-center text-lg">
          Supported Calendar Systems
        </h3>
        <div className="max-w-md mx-auto">
          <div className="grid grid-cols-2 gap-6">
            {calendarProviders.map((provider, index) => (
              <motion.div
                key={provider.id}
                initial={{ opacity: 0, scale: 0.9 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ delay: index * 0.1 }}
                className="relative p-4 border-2 border-blue-200 bg-white rounded-xl text-center hover:shadow-lg hover:scale-105 transition-all duration-200"
              >
                <div className="absolute -top-2 -right-2 bg-blue-600 text-white text-xs px-2 py-1 rounded-full">
                  Popular
                </div>

                <div className="flex justify-center mb-3">
                  {provider.logo}
                </div>

                <div className="font-semibold text-gray-900 mb-1">{provider.name}</div>
                <div className="text-xs text-gray-500 mb-2">{provider.estimatedTime}</div>

                <div className="space-y-1">
                  {provider.benefits.slice(0, 2).map((benefit, idx) => (
                    <div key={idx} className="text-xs text-gray-600 flex items-center justify-center gap-1">
                      <CheckCircle className="h-3 w-3 text-green-500" />
                      {benefit}
                    </div>
                  ))}
                </div>
              </motion.div>
            ))}
          </div>
        </div>

        <div className="mt-6 text-center">
          <p className="text-sm text-gray-600">
            ✨ Connect in under 2 minutes with one-click authorization
          </p>
        </div>
      </div>

      {/* Value Proposition */}
      <div className="bg-gradient-to-r from-blue-50 to-indigo-50 border border-blue-200 rounded-lg p-6">
        <div className="flex items-start gap-4">
          <div className="w-12 h-12 bg-blue-600 rounded-lg flex items-center justify-center flex-shrink-0">
            <Zap className="h-6 w-6 text-white" />
          </div>
          <div>
            <h3 className="font-semibold text-gray-900 mb-2">
              Why Import Your Calendar?
            </h3>
            <ul className="text-sm text-gray-700 space-y-1">
              <li>• Get intelligent scheduling recommendations immediately</li>
              <li>• Keep all your existing student relationships and booking history</li>
              <li>• See which time slots and classes perform best</li>
              <li>• Identify revenue optimization opportunities</li>
            </ul>
          </div>
        </div>
      </div>

      {/* Action Buttons */}
      <div className="flex flex-col sm:flex-row gap-4 justify-center">
        <button
          onClick={handleContinueWithSetup}
          className="flex items-center justify-center gap-2 px-6 py-3 bg-blue-600 text-white font-medium rounded-lg hover:bg-blue-700 transition-colors shadow-md hover:shadow-lg"
        >
          <Upload className="h-4 w-4" />
          Import My Calendar
          <ArrowRight className="h-4 w-4" />
        </button>

        <button
          onClick={handleSkip}
          disabled={isSkipping}
          className="flex items-center justify-center gap-2 px-6 py-3 border border-gray-300 text-gray-700 font-medium rounded-lg hover:bg-gray-50 transition-colors disabled:opacity-50"
        >
          {isSkipping ? (
            <>
              <motion.div
                animate={{ rotate: 360 }}
                transition={{ duration: 1, repeat: Infinity, ease: "linear" }}
              >
                <Clock className="h-4 w-4" />
              </motion.div>
              Skipping...
            </>
          ) : (
            <>
              <SkipForward className="h-4 w-4" />
              Set Up Later
            </>
          )}
        </button>
      </div>

      {/* Skip Information */}
      <div className="text-center">
        <p className="text-sm text-gray-500">
          You can always import your calendar later from the dashboard.
          <br />
          <span className="text-blue-600">Importing now gives you immediate insights!</span>
        </p>
      </div>

      {/* Calendar Privacy Notice */}
      <div className="mt-8 pt-6 border-t border-gray-200">
        <PrivacyPolicyBanner
          variant="inline"
          context="calendar"
        />
      </div>
    </div>
  );
}