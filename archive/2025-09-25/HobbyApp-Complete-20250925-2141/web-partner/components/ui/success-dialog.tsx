'use client';

import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { CheckCircle, X, ExternalLink, Calendar, Users, CreditCard, BarChart3 } from 'lucide-react';
import { Button } from '@/components/ui/button';

interface SuccessDialogProps {
  isOpen: boolean;
  onClose: () => void;
  title: string;
  message: string;
  provider?: 'square' | 'google' | 'calendly';
  integrationData?: {
    merchantName?: string;
    locationName?: string;
    servicesCount?: number;
    appointmentsCount?: number;
  };
}

export default function SuccessDialog({
  isOpen,
  onClose,
  title,
  message,
  provider = 'square',
  integrationData
}: SuccessDialogProps) {
  const providerConfig = {
    square: {
      name: 'Square Appointments',
      icon: '⬜',
      color: 'bg-blue-600',
      features: ['Appointments', 'Customer Data', 'Payment History', 'Service Catalog']
    },
    google: {
      name: 'Google Calendar',
      icon: '📅',
      color: 'bg-green-600',
      features: ['Calendar Events', 'Recurring Schedules', 'Room Bookings', 'Attendee Lists']
    },
    calendly: {
      name: 'Calendly',
      icon: '📆',
      color: 'bg-purple-600',
      features: ['Scheduled Events', 'Event Types', 'Invitee Data', 'Booking Links']
    }
  };

  const config = providerConfig[provider];

  if (!isOpen) return null;

  return (
    <AnimatePresence>
      <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
        <motion.div
          initial={{ opacity: 0, scale: 0.9, y: 20 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.9, y: 20 }}
          transition={{ duration: 0.3, ease: "easeOut" }}
          className="bg-white rounded-xl shadow-2xl max-w-md w-full max-h-[90vh] overflow-y-auto"
        >
          {/* Header */}
          <div className="relative p-6 border-b">
            <button
              onClick={onClose}
              className="absolute top-4 right-4 text-gray-400 hover:text-gray-600 transition-colors"
            >
              <X className="h-5 w-5" />
            </button>

            <div className="flex items-center">
              <motion.div
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                transition={{ delay: 0.2, type: "spring", stiffness: 200 }}
                className={`w-12 h-12 ${config.color} rounded-full flex items-center justify-center mr-4`}
              >
                <CheckCircle className="h-6 w-6 text-white" />
              </motion.div>

              <div>
                <h2 className="text-xl font-bold text-gray-900">{title}</h2>
                <p className="text-sm text-gray-600 mt-1">{config.name} Connected</p>
              </div>
            </div>
          </div>

          {/* Content */}
          <div className="p-6">
            {/* Success Message */}
            <div className="mb-6">
              <p className="text-gray-700 leading-relaxed">{message}</p>
            </div>

            {/* Integration Details */}
            {integrationData && (
              <div className="bg-gray-50 rounded-lg p-4 mb-6">
                <h3 className="font-semibold text-gray-900 mb-3 flex items-center">
                  <BarChart3 className="h-4 w-4 mr-2" />
                  Integration Summary
                </h3>

                <div className="grid grid-cols-2 gap-3 text-sm">
                  {integrationData.merchantName && (
                    <div>
                      <span className="text-gray-500">Business:</span>
                      <span className="ml-2 font-medium">{integrationData.merchantName}</span>
                    </div>
                  )}
                  {integrationData.locationName && (
                    <div>
                      <span className="text-gray-500">Location:</span>
                      <span className="ml-2 font-medium">{integrationData.locationName}</span>
                    </div>
                  )}
                  {integrationData.servicesCount !== undefined && (
                    <div>
                      <span className="text-gray-500">Services:</span>
                      <span className="ml-2 font-medium">{integrationData.servicesCount}</span>
                    </div>
                  )}
                  {integrationData.appointmentsCount !== undefined && (
                    <div>
                      <span className="text-gray-500">Appointments:</span>
                      <span className="ml-2 font-medium">{integrationData.appointmentsCount}</span>
                    </div>
                  )}
                </div>
              </div>
            )}

            {/* Features List */}
            <div className="mb-6">
              <h3 className="font-semibold text-gray-900 mb-3">Now Available:</h3>
              <div className="grid grid-cols-1 gap-2">
                {config.features.map((feature, index) => (
                  <motion.div
                    key={feature}
                    initial={{ opacity: 0, x: -20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: 0.1 * index, duration: 0.3 }}
                    className="flex items-center text-sm text-gray-700"
                  >
                    <CheckCircle className="h-4 w-4 text-green-600 mr-3 flex-shrink-0" />
                    {feature}
                  </motion.div>
                ))}
              </div>
            </div>

            {/* Next Steps */}
            <div className="bg-blue-50 rounded-lg p-4 mb-6">
              <h3 className="font-semibold text-blue-900 mb-2">What's Next?</h3>
              <p className="text-sm text-blue-700">
                Your data is being analyzed to generate intelligent insights.
                Check the Studio Intelligence dashboard for recommendations that
                can increase your revenue by an average of 20%.
              </p>
            </div>
          </div>

          {/* Footer */}
          <div className="px-6 py-4 border-t bg-gray-50 rounded-b-xl">
            <div className="flex gap-3">
              <Button
                onClick={onClose}
                className="flex-1 bg-gray-600 hover:bg-gray-700"
              >
                <Calendar className="h-4 w-4 mr-2" />
                View Dashboard
              </Button>
              <Button
                onClick={() => window.open(`https://developer.squareup.com/apps`, '_blank')}
                variant="outline"
                className="flex-1"
              >
                <ExternalLink className="h-4 w-4 mr-2" />
                Manage Integration
              </Button>
            </div>
          </div>
        </motion.div>
      </div>
    </AnimatePresence>
  );
}