'use client';

import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Calendar,
  Brain,
  Zap,
  X,
  ArrowRight,
  TrendingUp,
  Clock,
  CheckCircle,
  Sparkles
} from 'lucide-react';
import Link from 'next/link';

interface SetupRemindersProps {
  className?: string;
  onComplete?: (setupType: string) => void;
}

interface SetupItem {
  id: string;
  title: string;
  description: string;
  icon: React.ReactNode;
  benefit: string;
  estimatedTime: string;
  completionRate: string;
  actionUrl: string;
  priority: 'high' | 'medium' | 'low';
  color: string;
}

export default function SetupReminders({ className = '', onComplete }: SetupRemindersProps) {
  const [dismissedItems, setDismissedItems] = useState<Set<string>>(new Set());
  const [isClient, setIsClient] = useState(false);

  // Load dismissed items from localStorage on mount
  useEffect(() => {
    setIsClient(true);
    const storedDismissed = localStorage.getItem('dismissed-setup-reminders');
    if (storedDismissed) {
      try {
        const parsed = JSON.parse(storedDismissed);
        setDismissedItems(new Set(parsed));
      } catch (e) {
        console.error('Failed to parse dismissed items from localStorage', e);
      }
    }
  }, []);

  // Mock incomplete setup items - in production, this would come from user's actual setup status
  const incompleteSetups: SetupItem[] = [
    {
      id: 'calendar-intelligence',
      title: 'Set Up Calendar Integration',
      description: 'Connect your booking system and activate AI-powered studio intelligence',
      icon: <Brain className="h-5 w-5" />,
      benefit: 'Average 20% revenue increase + instant insights',
      estimatedTime: '3 minutes',
      completionRate: '87% of studios complete this',
      actionUrl: '/dashboard/intelligence?setup=calendar',
      priority: 'high',
      color: 'purple'
    }
  ];

  // Filter out dismissed items
  const activeSetups = incompleteSetups.filter(setup => !dismissedItems.has(setup.id));

  const handleDismiss = (setupId: string) => {
    const newDismissed = new Set([...dismissedItems, setupId]);
    setDismissedItems(newDismissed);

    // Save to localStorage
    if (isClient) {
      localStorage.setItem('dismissed-setup-reminders', JSON.stringify([...newDismissed]));
    }
  };

  const handleComplete = (setupId: string) => {
    handleDismiss(setupId);
    if (onComplete) {
      onComplete(setupId);
    }
  };

  const getColorClasses = (color: string) => {
    const colorMap = {
      blue: {
        bg: 'from-blue-50 to-blue-100',
        border: 'border-blue-200',
        text: 'text-blue-800',
        icon: 'bg-blue-100 text-blue-600',
        button: 'bg-blue-600 hover:bg-blue-700'
      },
      purple: {
        bg: 'from-purple-50 to-purple-100',
        border: 'border-purple-200',
        text: 'text-purple-800',
        icon: 'bg-purple-100 text-purple-600',
        button: 'bg-purple-600 hover:bg-purple-700'
      }
    };
    return colorMap[color as keyof typeof colorMap] || colorMap.blue;
  };

  // Always show setup reminders in development/demo mode
  // if (activeSetups.length === 0) {
  //   return null;
  // }

  return (
    <div className={`space-y-4 ${className}`}>
      <div className="flex items-center justify-between">
        <h3 className="text-lg font-semibold text-gray-900 flex items-center gap-2">
          <Zap className="h-5 w-5 text-orange-600" />
          Complete Your Setup
        </h3>
        <div className="text-sm text-gray-500">
          {activeSetups.length} remaining
        </div>
      </div>

      <AnimatePresence mode="popLayout">
        {activeSetups.map((setup, index) => {
          const colors = getColorClasses(setup.color);

          return (
            <motion.div
              key={setup.id}
              initial={{ opacity: 0, y: 20, scale: 0.95 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{
                opacity: 0,
                x: 300,
                scale: 0.8,
                transition: { duration: 0.3 }
              }}
              transition={{ delay: index * 0.1 }}
              className={`relative bg-gradient-to-r ${colors.bg} border ${colors.border} rounded-xl p-6 hover:shadow-lg transition-all duration-300`}
            >
              {/* Dismiss Button */}
              <button
                onClick={() => handleDismiss(setup.id)}
                className="absolute top-4 right-4 text-gray-400 hover:text-gray-600 transition-colors"
              >
                <X className="h-4 w-4" />
              </button>

              <div className="flex items-start gap-4">
                {/* Icon */}
                <div className={`w-12 h-12 ${colors.icon} rounded-lg flex items-center justify-center flex-shrink-0`}>
                  {setup.icon}
                </div>

                {/* Content */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-start justify-between mb-2">
                    <h4 className={`font-semibold ${colors.text}`}>
                      {setup.title}
                    </h4>
                    {setup.priority === 'high' && (
                      <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-orange-100 text-orange-800">
                        High Impact
                      </span>
                    )}
                  </div>

                  <p className="text-gray-700 text-sm mb-3">
                    {setup.description}
                  </p>

                  {/* Benefits */}
                  <div className="grid sm:grid-cols-3 gap-3 mb-4">
                    <div className="flex items-center gap-2">
                      <TrendingUp className="h-4 w-4 text-green-600" />
                      <span className="text-xs text-gray-600">{setup.benefit}</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <Clock className="h-4 w-4 text-blue-600" />
                      <span className="text-xs text-gray-600">{setup.estimatedTime}</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <CheckCircle className="h-4 w-4 text-purple-600" />
                      <span className="text-xs text-gray-600">{setup.completionRate}</span>
                    </div>
                  </div>

                  {/* Action Buttons */}
                  <div className="flex flex-col sm:flex-row gap-3">
                    <Link
                      href={setup.actionUrl}
                      onClick={() => handleComplete(setup.id)}
                      className={`inline-flex items-center justify-center gap-2 px-4 py-2 ${colors.button} text-white font-medium rounded-lg transition-colors flex-1 sm:flex-none`}
                    >
                      <Sparkles className="h-4 w-4" />
                      Set Up Now
                      <ArrowRight className="h-4 w-4" />
                    </Link>

                    <button
                      onClick={() => handleDismiss(setup.id)}
                      className="inline-flex items-center justify-center px-4 py-2 text-gray-600 hover:text-gray-800 font-medium transition-colors text-sm"
                    >
                      Remind me later
                    </button>
                  </div>
                </div>
              </div>

              {/* Progress indicator for high priority items */}
              {setup.priority === 'high' && (
                <div className="absolute bottom-0 left-0 right-0 h-1 bg-gray-200 rounded-b-xl overflow-hidden">
                  <motion.div
                    initial={{ width: 0 }}
                    animate={{ width: '100%' }}
                    transition={{ duration: 10, ease: "linear" }}
                    className="h-full bg-gradient-to-r from-orange-400 to-orange-600"
                  />
                </div>
              )}
            </motion.div>
          );
        })}
      </AnimatePresence>

      {/* Overall completion encouragement */}
      {activeSetups.length > 0 && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.5 }}
          className="bg-gradient-to-r from-green-50 to-emerald-50 border border-green-200 rounded-lg p-4"
        >
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 bg-green-100 rounded-full flex items-center justify-center">
              <Sparkles className="h-4 w-4 text-green-600" />
            </div>
            <div>
              <p className="text-sm font-medium text-green-800">
                Complete these setups to unlock your studio's full potential
              </p>
              <p className="text-xs text-green-700">
                Studios that complete all setup steps see an average 25% increase in bookings
              </p>
            </div>
          </div>
        </motion.div>
      )}
    </div>
  );
}