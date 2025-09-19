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
  Upload,
  Download,
  Smartphone,
  MonitorSpeaker
} from 'lucide-react';
// import CalendarIntegrationHub from '@/components/studio/CalendarIntegrationHub'; // Temporarily disabled to fix server-side import issue
import PrivacyPolicyBanner from '@/components/common/PrivacyPolicyBanner';

interface CalendarSetupStepProps {
  onNext: (data: any) => void;
  onPrevious: () => void;
  data: any;
}

export default function CalendarSetupStep({ onNext, onPrevious, data }: CalendarSetupStepProps) {
  const [setupMode, setSetupMode] = useState<'overview' | 'setup' | 'completed'>('overview');
  const [selectedProviders, setSelectedProviders] = useState<string[]>([]);
  const [isSkipping, setIsSkipping] = useState(false);

  const calendarProviders = [
    {
      id: 'google',
      name: 'Google Calendar',
      icon: '📅',
      description: 'Import your Google Calendar events',
      popular: true,
      estimatedTime: '2 minutes'
    },
    {
      id: 'outlook',
      name: 'Outlook Calendar',
      icon: '📆',
      description: 'Connect your Microsoft Outlook calendar',
      popular: false,
      estimatedTime: '3 minutes'
    },
    {
      id: 'apple',
      name: 'Apple Calendar',
      icon: '🍎',
      description: 'Sync with your iCloud calendar',
      popular: false,
      estimatedTime: '3 minutes'
    },
    {
      id: 'mindbody',
      name: 'MindBody',
      icon: '🧘',
      description: 'Import from your MindBody studio management',
      popular: true,
      estimatedTime: '5 minutes'
    },
    {
      id: 'acuity',
      name: 'Acuity Scheduling',
      icon: '⚡',
      description: 'Connect your Acuity booking system',
      popular: false,
      estimatedTime: '4 minutes'
    },
    {
      id: 'square',
      name: 'Square Appointments',
      icon: '⬜',
      description: 'Import from Square booking system',
      popular: false,
      estimatedTime: '4 minutes'
    }
  ];

  const benefits = [
    {
      icon: <Clock className="h-5 w-5" />,
      title: 'Seamless Migration',
      description: 'Import all your existing classes and bookings instantly'
    },
    {
      icon: <TrendingUp className="h-5 w-5" />,
      title: 'Smart Insights',
      description: 'Get AI-powered recommendations to optimize your schedule'
    },
    {
      icon: <Users className="h-5 w-5" />,
      title: 'Student Continuity',
      description: 'Keep all your student data and booking history'
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

  const handleSetupComplete = (integrationData: any) => {
    setSetupMode('completed');
    setTimeout(() => {
      onNext({
        calendarSetup: {
          completed: true,
          providers: selectedProviders,
          integrationData
        }
      });
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
      <div className="space-y-6">
        <div className="text-center">
          <h2 className="text-2xl font-bold text-gray-900 mb-2">
            Connect Your Calendar
          </h2>
          <p className="text-gray-600">
            Choose your calendar provider to import existing classes and bookings
          </p>
        </div>

        {/* Calendar Integration Component - Simplified for Demo */}
        <div className="bg-gray-50 rounded-lg p-6">
          <div className="text-center space-y-4">
            <h3 className="font-semibold text-gray-900">Calendar Providers</h3>
            <div className="grid grid-cols-2 gap-4">
              <button
                onClick={() => handleSetupComplete({ provider: 'google' })}
                className="p-4 border border-gray-300 rounded-lg hover:border-blue-500 transition-colors"
              >
                <Calendar className="h-8 w-8 mx-auto mb-2 text-blue-600" />
                <div className="font-medium">Google Calendar</div>
                <div className="text-sm text-gray-500">Connect Google</div>
              </button>
              <button
                onClick={() => handleSetupComplete({ provider: 'mindbody' })}
                className="p-4 border border-gray-300 rounded-lg hover:border-purple-500 transition-colors"
              >
                <MonitorSpeaker className="h-8 w-8 mx-auto mb-2 text-purple-600" />
                <div className="font-medium">MindBody</div>
                <div className="text-sm text-gray-500">Import bookings</div>
              </button>
            </div>
            <p className="text-xs text-gray-500">Demo mode - Select any option to continue</p>
          </div>
        </div>

        {/* Progress indicator */}
        <div className="text-center">
          <p className="text-sm text-gray-500">
            This usually takes 2-5 minutes depending on your calendar size
          </p>
        </div>

        {/* Navigation */}
        <div className="flex justify-between pt-6">
          <button
            onClick={() => setSetupMode('overview')}
            className="px-4 py-2 text-gray-600 hover:text-gray-800 font-medium"
          >
            ← Back
          </button>
          <button
            onClick={handleSkip}
            className="flex items-center gap-2 px-4 py-2 text-gray-600 hover:text-gray-800 font-medium"
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
      <div className="bg-gray-50 rounded-lg p-6">
        <h3 className="font-semibold text-gray-900 mb-4 text-center">
          Supported Calendar Systems
        </h3>
        <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
          {calendarProviders.map((provider, index) => (
            <motion.div
              key={provider.id}
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ delay: index * 0.05 }}
              className={`relative p-3 border rounded-lg text-center hover:shadow-md transition-all ${
                provider.popular ? 'border-blue-200 bg-blue-50' : 'border-gray-200 bg-white'
              }`}
            >
              {provider.popular && (
                <div className="absolute -top-2 -right-2 bg-blue-600 text-white text-xs px-2 py-1 rounded-full">
                  Popular
                </div>
              )}
              <div className="text-2xl mb-2">{provider.icon}</div>
              <div className="font-medium text-sm text-gray-900">{provider.name}</div>
              <div className="text-xs text-gray-500 mt-1">{provider.estimatedTime}</div>
            </motion.div>
          ))}
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