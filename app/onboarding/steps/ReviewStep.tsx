'use client';

import React, { useState } from 'react';
import { motion } from 'framer-motion';
import {
  CheckCircle,
  AlertCircle,
  Clock,
  Calendar,
  Brain,
  Building2,
  CreditCard,
  User,
  ArrowRight,
  Sparkles,
  Target,
  Zap
} from 'lucide-react';

interface ReviewStepProps {
  onSubmit: () => void;
  onPrevious: () => void;
  data: any;
}

export default function ReviewStep({ onSubmit, onPrevious, data }: ReviewStepProps) {
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Calculate setup completion
  const setupItems = [
    {
      id: 'business',
      title: 'Business Information',
      icon: <Building2 className="h-5 w-5" />,
      completed: !!data.businessInfo,
      required: true,
      description: 'Studio details and contact information'
    },
    {
      id: 'verification',
      title: 'Identity Verification',
      icon: <User className="h-5 w-5" />,
      completed: !!data.verification,
      required: true,
      description: 'Government ID verification'
    },
    {
      id: 'profile',
      title: 'Studio Profile',
      icon: <Building2 className="h-5 w-5" />,
      completed: !!data.studioProfile,
      required: true,
      description: 'Photos, description, and amenities'
    },
    {
      id: 'services',
      title: 'Classes & Services',
      icon: <Target className="h-5 w-5" />,
      completed: !!data.services,
      required: true,
      description: 'Workshop offerings and pricing'
    },
    {
      id: 'payment',
      title: 'Payment Setup',
      icon: <CreditCard className="h-5 w-5" />,
      completed: !!data.payment,
      required: true,
      description: 'Stripe integration and commission'
    },
    {
      id: 'calendar',
      title: 'Calendar Integration',
      icon: <Calendar className="h-5 w-5" />,
      completed: !!data.calendarSetup?.completed,
      required: false,
      skipped: !!data.calendarSetup?.skipped,
      description: 'Import existing schedules and bookings'
    },
    {
      id: 'intelligence',
      title: 'Studio Intelligence',
      icon: <Brain className="h-5 w-5" />,
      completed: !!data.studioIntelligence?.activated,
      required: false,
      skipped: !!data.studioIntelligence?.skipped,
      description: 'AI-powered operational insights'
    }
  ];

  const requiredItems = setupItems.filter(item => item.required);
  const optionalItems = setupItems.filter(item => !item.required);
  const completedRequired = requiredItems.filter(item => item.completed).length;
  const completedOptional = optionalItems.filter(item => item.completed).length;
  const skippedOptional = optionalItems.filter(item => item.skipped).length;

  const isReadyToLaunch = completedRequired === requiredItems.length;
  const setupScore = Math.round(((completedRequired + completedOptional) / setupItems.length) * 100);

  const handleSubmit = async () => {
    setIsSubmitting(true);
    // Simulate submission delay
    setTimeout(() => {
      onSubmit();
    }, 2000);
  };

  if (isSubmitting) {
    return (
      <div className="text-center space-y-6">
        <motion.div
          initial={{ scale: 0 }}
          animate={{ scale: 1 }}
          transition={{ type: "spring", stiffness: 200 }}
          className="w-20 h-20 bg-blue-100 rounded-full flex items-center justify-center mx-auto"
        >
          <motion.div
            animate={{ rotate: 360 }}
            transition={{ duration: 2, repeat: Infinity, ease: "linear" }}
          >
            <Sparkles className="h-10 w-10 text-blue-600" />
          </motion.div>
        </motion.div>

        <div>
          <h2 className="text-2xl font-bold text-gray-900 mb-2">
            Launching Your Studio! 🚀
          </h2>
          <p className="text-gray-600">
            Creating your studio profile and setting up your dashboard...
          </p>
        </div>

        <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 max-w-md mx-auto">
          <div className="flex items-center justify-center gap-2 text-blue-800">
            <Clock className="h-4 w-4" />
            <span className="text-sm font-medium">This may take a few moments</span>
          </div>
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
          className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4"
        >
          <CheckCircle className="h-8 w-8 text-green-600" />
        </motion.div>

        <h2 className="text-2xl font-bold text-gray-900 mb-2">
          Studio Setup Complete!
        </h2>
        <p className="text-gray-600">
          Review your setup before launching your studio on Hobbyist
        </p>
      </div>

      {/* Setup Score */}
      <div className="bg-gradient-to-r from-green-50 to-emerald-50 border border-green-200 rounded-xl p-6">
        <div className="text-center">
          <div className="text-3xl font-bold text-green-600 mb-2">{setupScore}%</div>
          <div className="text-sm text-green-700 font-medium mb-3">Setup Complete</div>
          <div className="w-full bg-green-200 rounded-full h-2">
            <motion.div
              initial={{ width: 0 }}
              animate={{ width: `${setupScore}%` }}
              transition={{ duration: 1, delay: 0.5 }}
              className="bg-green-600 h-2 rounded-full"
            />
          </div>
        </div>
      </div>

      {/* Required Setup Items */}
      <div>
        <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
          <CheckCircle className="h-5 w-5 text-green-600" />
          Required Setup ({completedRequired}/{requiredItems.length})
        </h3>
        <div className="space-y-3">
          {requiredItems.map((item, index) => (
            <motion.div
              key={item.id}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: index * 0.1 }}
              className="flex items-center gap-3 p-3 bg-white border border-gray-200 rounded-lg"
            >
              <div className="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center text-green-600">
                {item.icon}
              </div>
              <div className="flex-1">
                <div className="font-medium text-gray-900">{item.title}</div>
                <div className="text-sm text-gray-600">{item.description}</div>
              </div>
              <CheckCircle className="h-5 w-5 text-green-600" />
            </motion.div>
          ))}
        </div>
      </div>

      {/* Optional Setup Items */}
      <div>
        <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
          <Zap className="h-5 w-5 text-blue-600" />
          Advanced Features ({completedOptional}/{optionalItems.length})
        </h3>
        <div className="space-y-3">
          {optionalItems.map((item, index) => (
            <motion.div
              key={item.id}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: (requiredItems.length + index) * 0.1 }}
              className={`flex items-center gap-3 p-3 border rounded-lg ${
                item.completed
                  ? 'bg-blue-50 border-blue-200'
                  : item.skipped
                  ? 'bg-gray-50 border-gray-200'
                  : 'bg-orange-50 border-orange-200'
              }`}
            >
              <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${
                item.completed
                  ? 'bg-blue-100 text-blue-600'
                  : item.skipped
                  ? 'bg-gray-100 text-gray-500'
                  : 'bg-orange-100 text-orange-600'
              }`}>
                {item.icon}
              </div>
              <div className="flex-1">
                <div className="font-medium text-gray-900">{item.title}</div>
                <div className="text-sm text-gray-600">{item.description}</div>
              </div>
              {item.completed ? (
                <CheckCircle className="h-5 w-5 text-blue-600" />
              ) : item.skipped ? (
                <Clock className="h-5 w-5 text-gray-500" />
              ) : (
                <AlertCircle className="h-5 w-5 text-orange-600" />
              )}
            </motion.div>
          ))}
        </div>

        {(skippedOptional > 0 || completedOptional < optionalItems.length) && (
          <div className="mt-4 p-4 bg-blue-50 border border-blue-200 rounded-lg">
            <div className="flex items-start gap-2">
              <Zap className="h-5 w-5 text-blue-600 mt-0.5" />
              <div>
                <div className="font-medium text-blue-800 mb-1">
                  Complete Setup Later
                </div>
                <div className="text-sm text-blue-700">
                  You can set up calendar integration and Studio Intelligence anytime from your dashboard.
                  These features will help you optimize operations and increase revenue.
                </div>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Studio Summary */}
      <div className="bg-white border border-gray-200 rounded-lg p-6">
        <h3 className="font-semibold text-gray-900 mb-4">Studio Summary</h3>
        <div className="grid md:grid-cols-2 gap-4 text-sm">
          <div>
            <div className="text-gray-500">Business Name</div>
            <div className="font-medium">{data.businessInfo?.businessName || 'Not specified'}</div>
          </div>
          <div>
            <div className="text-gray-500">Email</div>
            <div className="font-medium">{data.businessInfo?.businessEmail || 'Not specified'}</div>
          </div>
          <div>
            <div className="text-gray-500">Location</div>
            <div className="font-medium">
              {data.businessInfo?.address?.city && data.businessInfo?.address?.state
                ? `${data.businessInfo.address.city}, ${data.businessInfo.address.state}`
                : 'Not specified'
              }
            </div>
          </div>
          <div>
            <div className="text-gray-500">Setup Status</div>
            <div className="font-medium text-green-600">
              {isReadyToLaunch ? 'Ready to Launch' : 'Setup Incomplete'}
            </div>
          </div>
        </div>
      </div>

      {/* Navigation Buttons */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.8 }}
        className="space-y-4"
      >
        <button
          onClick={handleSubmit}
          disabled={!isReadyToLaunch}
          className={`w-full py-4 px-6 font-medium rounded-lg transition-all shadow-lg hover:shadow-xl flex items-center justify-center gap-3 ${
            isReadyToLaunch
              ? 'bg-gradient-to-r from-green-600 to-emerald-600 text-white hover:from-green-700 hover:to-emerald-700'
              : 'bg-gray-300 text-gray-500 cursor-not-allowed'
          }`}
        >
          <Sparkles className="h-5 w-5" />
          Launch My Studio on Hobbyist
          <ArrowRight className="h-5 w-5" />
        </button>

        <button
          type="button"
          onClick={onPrevious}
          className="w-full py-3 px-6 border border-gray-300 text-gray-700 rounded-lg font-medium hover:bg-gray-50 transition-all"
        >
          Back to Edit
        </button>

        {!isReadyToLaunch && (
          <p className="text-center text-sm text-red-600 mt-2">
            Please complete all required setup steps before launching
          </p>
        )}
      </motion.div>

      {/* Success Message */}
      {isReadyToLaunch && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 1 }}
          className="text-center"
        >
          <p className="text-sm text-gray-600">
            🎉 Congratulations! Your studio is ready to start accepting bookings on Hobbyist.
            <br />
            <span className="text-green-600 font-medium">
              Welcome to the future of studio management!
            </span>
          </p>
        </motion.div>
      )}
    </div>
  );
}