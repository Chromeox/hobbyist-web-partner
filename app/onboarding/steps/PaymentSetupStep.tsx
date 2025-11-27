'use client';

import React, { useState } from 'react';
import { motion } from 'framer-motion';
import {
  CreditCard,
  Shield,
  CheckCircle,
  ArrowRight,
  Building2,
  Users,
  TrendingUp,
  DollarSign,
  Zap,
  SkipForward,
  ExternalLink
} from 'lucide-react';
import PrivacyPolicyBanner from '@/components/common/PrivacyPolicyBanner';
import { useAnalytics } from '@/lib/hooks/useAnalytics';

interface PaymentSetupStepProps {
  onNext: (data: any) => void;
  onPrevious: () => void;
  data: any;
}

// Stripe Logo Component
const StripeLogo = () => (
  <svg viewBox="0 0 60 25" className="h-6 w-auto">
    <path
      fill="#6772e5"
      d="M59.64 14.28h-8.06c.19 1.93 1.6 2.55 3.2 2.55 1.64 0 2.96-.37 4.05-.95v3.32a8.33 8.33 0 0 1-4.56 1.1c-4.01 0-6.83-2.5-6.83-7.48 0-4.19 2.39-7.52 6.3-7.52 3.92 0 5.96 3.28 5.96 7.5 0 .4-.04 1.26-.06 1.48zm-5.92-5.62c-1.03 0-2.17.73-2.17 2.58h4.25c0-1.85-1.07-2.58-2.08-2.58zM40.95 20.3c-1.44 0-2.32-.6-2.9-1.04l-.02 4.63-4.12.87V5.57h3.76l.08 1.02a4.7 4.7 0 0 1 3.23-1.29c2.9 0 5.62 2.6 5.62 7.4 0 5.23-2.7 7.6-5.65 7.6zM40 8.95c-.95 0-1.54.34-1.97.81l.02 6.12c.4.44.98.78 1.95.78 1.52 0 2.54-1.65 2.54-3.87 0-2.15-1.04-3.84-2.54-3.84zM28.24 5.57h4.13v14.44h-4.13V5.57zm0-4.7L32.37 0v3.36l-4.13.88V.88z"
    />
    <path
      fill="#6772e5"
      d="M13.04 7.98v3.17L9.96 11.2c-.33-.02-.66-.04-.66-.04C7.64 11.16 6 12.1 6 14.58c0 1.31.83 2.77 2.68 2.77 1.24 0 2.36-.5 3.36-1.31l.33 1.29h3.68V7.98h-3.01zm0 8.08c-.42.73-1.21 1.21-2.09 1.21-.5 0-.94-.19-.94-.68 0-.84.81-1.13 2.09-1.13.33 0 .66.02.94.04v.56z"
    />
    <path
      fill="#6772e5"
      d="M26.34 10.78c-.4-.02-.84-.04-1.18-.04-1.75 0-2.87.86-2.87 2.58v6.69h-4.13V7.98h3.76l.07 1.02c.65-.82 1.78-1.02 2.85-1.02.31 0 .66.02 1.02.04v2.76h-.52z"
    />
  </svg>
);

export default function PaymentSetupStep({ onNext, onPrevious, data }: PaymentSetupStepProps) {
  const { trackStripeConnected, trackEvent } = useAnalytics();
  const [setupMode, setSetupMode] = useState<'overview' | 'connecting' | 'completed'>('overview');
  const [isConnecting, setIsConnecting] = useState(false);
  const [isSkipping, setIsSkipping] = useState(false);

  const benefits = [
    {
      icon: <CreditCard className="h-5 w-5" />,
      title: 'Accept All Payment Methods',
      description: 'Credit cards, debit cards, Apple Pay, Google Pay, and more'
    },
    {
      icon: <Shield className="h-5 w-5" />,
      title: 'Enterprise Security',
      description: 'Bank-level security with PCI DSS compliance and fraud protection'
    },
    {
      icon: <TrendingUp className="h-5 w-5" />,
      title: 'Transparent Pricing',
      description: '2.9% + 30¢ per transaction with no hidden fees or monthly costs'
    }
  ];

  const features = [
    'Instant payouts to your bank account',
    'Real-time transaction monitoring',
    'Automatic tax reporting and 1099s',
    'Chargeback and dispute protection',
    'Mobile-optimized checkout experience',
    'Recurring billing and subscription management'
  ];

  const handleConnectStripe = async () => {
    trackEvent('stripe_connect_started');
    setIsConnecting(true);
    setSetupMode('connecting');

    try {
      // Call the API to create a Stripe Express account
      const response = await fetch('/api/stripe/connect', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          businessName: data.businessInfo?.legalBusinessName || 'Hobbyist Partner',
          businessEmail: data.owner?.email,
          country: data.businessInfo?.address?.country || 'CA', // Default to CA or US
          type: 'express'
        }),
      });

      const result = await response.json();

      if (result.success && result.onboarding_url) {
        // Redirect to Stripe onboarding
        window.location.href = result.onboarding_url;
      } else {
        console.error('Stripe Connect failed:', result.error);
        setIsConnecting(false);
        setSetupMode('overview');
        // You might want to show an error message here
      }
    } catch (error) {
      console.error('Error initiating Stripe Connect:', error);
      setIsConnecting(false);
      setSetupMode('overview');
    }
  };

  const handleSkip = () => {
    trackEvent('stripe_connect_skipped', {
      reason: 'user_choice',
      step: 'onboarding'
    });
    setIsSkipping(true);
    setTimeout(() => {
      onNext({ payment: { skipped: true, reason: 'user_choice' } });
    }, 1000);
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
          Payment Processing Setup Complete! 🎉
        </h2>
        <p className="text-gray-600 mb-6 max-w-lg mx-auto">
          Your Stripe account is now connected and ready to accept payments. You can start
          processing transactions immediately.
        </p>

        <div className="bg-green-50 border border-green-200 rounded-lg p-4 mb-6 max-w-md mx-auto">
          <div className="flex items-center gap-2 text-green-800 font-medium mb-2">
            <DollarSign className="h-5 w-5" />
            Ready to Accept Payments
          </div>
          <p className="text-sm text-green-700">
            Your students can now book and pay for classes seamlessly through your
            Hobbyist studio portal.
          </p>
        </div>

        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 1 }}
          className="text-sm text-gray-500"
        >
          Proceeding to calendar setup...
        </motion.div>
      </div>
    );
  }

  if (setupMode === 'connecting') {
    return (
      <div className="text-center">
        <motion.div
          initial={{ scale: 0 }}
          animate={{ scale: 1 }}
          transition={{ type: "spring", stiffness: 200 }}
          className="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-6"
        >
          <motion.div
            animate={{ rotate: 360 }}
            transition={{ duration: 2, repeat: Infinity, ease: "linear" }}
          >
            <CreditCard className="h-8 w-8 text-blue-600" />
          </motion.div>
        </motion.div>

        <h2 className="text-2xl font-bold text-gray-900 mb-4">
          Connecting to Stripe...
        </h2>
        <p className="text-gray-600 mb-8 max-w-lg mx-auto">
          We're setting up your secure payment processing account. This usually takes
          just a few moments.
        </p>

        <div className="bg-blue-50 border border-blue-200 rounded-lg p-6 max-w-md mx-auto">
          <div className="space-y-3">
            <div className="flex items-center gap-3">
              <motion.div
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                transition={{ delay: 0.5 }}
              >
                <CheckCircle className="h-5 w-5 text-blue-600" />
              </motion.div>
              <span className="text-sm text-blue-800">Verifying business information...</span>
            </div>
            <div className="flex items-center gap-3">
              <motion.div
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                transition={{ delay: 1.5 }}
              >
                <CheckCircle className="h-5 w-5 text-blue-600" />
              </motion.div>
              <span className="text-sm text-blue-800">Setting up payment methods...</span>
            </div>
            <div className="flex items-center gap-3">
              <motion.div
                animate={{ rotate: 360 }}
                transition={{ duration: 1, repeat: Infinity, ease: "linear" }}
                className="w-5 h-5 border-2 border-blue-600 border-t-transparent rounded-full"
              />
              <span className="text-sm text-blue-800">Finalizing account setup...</span>
            </div>
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
          className="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-4"
        >
          <CreditCard className="h-8 w-8 text-blue-600" />
        </motion.div>

        <h2 className="text-2xl font-bold text-gray-900 mb-2">
          Payment Processing Setup
        </h2>
        <p className="text-gray-600 max-w-2xl mx-auto">
          Connect with Stripe to accept payments from your students. Start earning revenue
          from day one with secure, reliable payment processing.
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

      {/* Stripe Integration Preview */}
      <div className="bg-gradient-to-br from-purple-50 to-blue-50 border border-purple-200 rounded-xl p-8">
        <div className="text-center mb-6">
          <div className="flex items-center justify-center gap-3 mb-4">
            <h3 className="font-semibold text-gray-900 text-lg">Powered by</h3>
            <StripeLogo />
          </div>
          <p className="text-gray-600 text-sm">
            Trusted by millions of businesses worldwide
          </p>
        </div>

        <div className="grid md:grid-cols-2 gap-8">
          <div>
            <h4 className="font-semibold text-gray-900 mb-3">What You Get:</h4>
            <div className="space-y-2">
              {features.map((feature, index) => (
                <motion.div
                  key={index}
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: index * 0.1 }}
                  className="flex items-center gap-2 text-sm text-gray-700"
                >
                  <CheckCircle className="h-4 w-4 text-green-500" />
                  {feature}
                </motion.div>
              ))}
            </div>
          </div>

          <div className="bg-white rounded-lg p-6 border border-gray-200">
            <h4 className="font-semibold text-gray-900 mb-3">Revenue Dashboard Preview</h4>
            <div className="space-y-4">
              <div className="flex justify-between items-center">
                <span className="text-gray-600">Today's Revenue</span>
                <span className="font-semibold text-green-600">$2,340</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-gray-600">This Week</span>
                <span className="font-semibold text-green-600">$12,580</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-gray-600">Commission (15%)</span>
                <span className="font-semibold text-blue-600">$1,887</span>
              </div>
              <div className="pt-2 border-t border-gray-200">
                <div className="flex justify-between items-center">
                  <span className="text-gray-900 font-medium">Your Earnings</span>
                  <span className="font-bold text-green-600">$10,693</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Action Buttons */}
      <div className="flex flex-col sm:flex-row gap-4 justify-center">
        <button
          onClick={handleConnectStripe}
          disabled={isConnecting}
          className="flex items-center justify-center gap-2 px-6 py-3 bg-gradient-to-r from-purple-600 to-blue-600 text-white font-medium rounded-lg hover:from-purple-700 hover:to-blue-700 transition-all shadow-md hover:shadow-lg disabled:opacity-50"
        >
          {isConnecting ? (
            <>
              <motion.div
                animate={{ rotate: 360 }}
                transition={{ duration: 1, repeat: Infinity, ease: "linear" }}
                className="w-4 h-4 border-2 border-white border-t-transparent rounded-full"
              />
              Connecting...
            </>
          ) : (
            <>
              <Shield className="h-4 w-4" />
              Connect with Stripe
              <ArrowRight className="h-4 w-4" />
            </>
          )}
        </button>

        <button
          onClick={handleSkip}
          disabled={isSkipping || isConnecting}
          className="flex items-center justify-center gap-2 px-6 py-3 border border-gray-300 text-gray-700 font-medium rounded-lg hover:bg-gray-50 transition-colors disabled:opacity-50"
        >
          {isSkipping ? (
            <>
              <motion.div
                animate={{ rotate: 360 }}
                transition={{ duration: 1, repeat: Infinity, ease: "linear" }}
              >
                <SkipForward className="h-4 w-4" />
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

      {/* Skip Information - Enhanced Warning */}
      <div className="bg-amber-50 border border-amber-200 rounded-lg p-4 text-center">
        <p className="text-amber-800 font-medium mb-1">
          ⚠️ Without Stripe, you can list classes but won't receive payouts
        </p>
        <p className="text-sm text-amber-700">
          You can set this up anytime from your dashboard. Students can still discover your classes,
          but bookings with payment won't be available until Stripe is connected.
        </p>
      </div>

      {/* Payment Privacy Notice */}
      <div className="mt-8 pt-6 border-t border-gray-200">
        <PrivacyPolicyBanner
          variant="inline"
          context="payment"
        />
      </div>
    </div>
  );
}