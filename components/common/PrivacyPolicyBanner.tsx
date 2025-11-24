'use client';

import React from 'react';
import Link from 'next/link';
import { Shield, ExternalLink, CheckCircle } from 'lucide-react';

interface PrivacyPolicyBannerProps {
  variant?: 'minimal' | 'detailed' | 'inline';
  context?: 'signup' | 'onboarding' | 'payment' | 'calendar' | 'general';
  showTrustIndicators?: boolean;
}

export default function PrivacyPolicyBanner({
  variant = 'minimal',
  context = 'general',
  showTrustIndicators = false
}: PrivacyPolicyBannerProps) {

  const contextMessages = {
    signup: "By creating an account, you agree to our privacy practices for handling your business information.",
    onboarding: "We collect only essential business data to provide studio management services.",
    payment: "Payment information is securely processed by Stripe and never stored on our servers.",
    calendar: "Calendar data is encrypted and used only to sync your schedules and bookings.",
    general: "Your privacy and data security are our top priorities."
  };

  const trustIndicators = [
    { icon: Shield, text: "SOC 2 Compliant", color: "text-green-600" },
    { icon: CheckCircle, text: "GDPR Compliant", color: "text-blue-600" },
    { icon: Shield, text: "AES-256 Encrypted", color: "text-purple-600" }
  ];

  if (variant === 'minimal') {
    return (
      <div className="text-center text-sm text-gray-600">
        <p>
          {contextMessages[context]}{' '}
          <Link
            href="/legal/privacy"
            className="text-blue-600 hover:text-blue-700 underline"
          >
            Privacy Policy
          </Link>
        </p>
      </div>
    );
  }

  if (variant === 'inline') {
    return (
      <div className="flex items-center gap-2 text-sm text-gray-600 bg-gray-50 rounded-lg p-3">
        <Shield className="h-4 w-4 text-green-600 flex-shrink-0" />
        <span>
          {contextMessages[context]}{' '}
          <Link
            href="/legal/privacy"
            className="text-blue-600 hover:text-blue-700 underline inline-flex items-center gap-1"
          >
            View Privacy Policy
            <ExternalLink className="h-3 w-3" />
          </Link>
        </span>
      </div>
    );
  }

  // Detailed variant
  return (
    <div className="bg-blue-50 border border-blue-200 rounded-lg p-6">
      <div className="flex items-start gap-3 mb-4">
        <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center flex-shrink-0">
          <Shield className="h-4 w-4 text-blue-600" />
        </div>
        <div className="flex-1">
          <h3 className="font-semibold text-blue-800 mb-2">Your Privacy Matters</h3>
          <p className="text-blue-700 text-sm mb-3">
            {contextMessages[context]}
          </p>

          {showTrustIndicators && (
            <div className="grid grid-cols-3 gap-4 mb-4">
              {trustIndicators.map((indicator, index) => (
                <div key={index} className="text-center">
                  <indicator.icon className={`h-5 w-5 mx-auto mb-1 ${indicator.color}`} />
                  <p className="text-xs text-gray-600">{indicator.text}</p>
                </div>
              ))}
            </div>
          )}

          <Link
            href="/legal/privacy"
            className="inline-flex items-center gap-2 text-blue-600 hover:text-blue-700 font-medium text-sm"
          >
            Read Full Privacy Policy
            <ExternalLink className="h-4 w-4" />
          </Link>
        </div>
      </div>
    </div>
  );
}