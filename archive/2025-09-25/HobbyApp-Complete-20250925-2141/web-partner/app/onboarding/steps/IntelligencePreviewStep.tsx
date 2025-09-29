'use client';

import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Brain,
  TrendingUp,
  Clock,
  Users,
  MapPin,
  DollarSign,
  Target,
  Zap,
  CheckCircle,
  ArrowRight,
  SkipForward,
  Lightbulb,
  BarChart3,
  Calendar,
  Sparkles
} from 'lucide-react';
import StudioIntelligenceSummary from '@/components/studio/StudioIntelligenceSummary';

interface IntelligencePreviewStepProps {
  onNext: (data: any) => void;
  onPrevious: () => void;
  data: any;
}

export default function IntelligencePreviewStep({ onNext, onPrevious, data }: IntelligencePreviewStepProps) {
  const [currentDemo, setCurrentDemo] = useState(0);
  const [isActivating, setIsActivating] = useState(false);
  const [showLivePreview, setShowLivePreview] = useState(false);

  const hasCalendarData = data.calendarSetup?.completed && !data.calendarSetup?.skipped;

  const demoInsights = [
    {
      icon: <Clock className="h-5 w-5" />,
      title: "Thursday 6pm pottery classes have 92% booking rate",
      description: "Add more pottery sessions in this high-success time slot",
      impact: "+$850/week revenue potential",
      color: "text-green-600 bg-green-100"
    },
    {
      icon: <MapPin className="h-5 w-5" />,
      title: "Studio B only 45% utilized on Mondays",
      description: "Perfect opportunity for beginner painting workshops",
      impact: "+$600/week revenue potential",
      color: "text-blue-600 bg-blue-100"
    },
    {
      icon: <Users className="h-5 w-5" />,
      title: "Sarah could teach 2 more classes weekly",
      description: "High-performing instructor with 95% capacity rate",
      impact: "+$400/week revenue potential",
      color: "text-purple-600 bg-purple-100"
    },
    {
      icon: <TrendingUp className="h-5 w-5" />,
      title: "Increase beginner pottery to 12 spots",
      description: "Consistent waitlist indicates high demand",
      impact: "+$300/week revenue potential",
      color: "text-orange-600 bg-orange-100"
    }
  ];

  const benefits = [
    {
      icon: <BarChart3 className="h-6 w-6" />,
      title: "Revenue Optimization",
      description: "Identify time slots and classes that generate the most income",
      stats: "Average 15-25% revenue increase"
    },
    {
      icon: <Calendar className="h-6 w-6" />,
      title: "Smart Scheduling",
      description: "AI-powered recommendations for optimal class timing",
      stats: "Reduce empty spots by 40%"
    },
    {
      icon: <Users className="h-6 w-6" />,
      title: "Instructor Optimization",
      description: "Balance workloads and maximize teaching effectiveness",
      stats: "Improve instructor utilization by 30%"
    },
    {
      icon: <Target className="h-6 w-6" />,
      title: "Capacity Planning",
      description: "Right-size your classes based on actual demand patterns",
      stats: "Increase overall capacity by 20%"
    }
  ];

  useEffect(() => {
    const interval = setInterval(() => {
      setCurrentDemo((prev) => (prev + 1) % demoInsights.length);
    }, 3000);

    return () => clearInterval(interval);
  }, []);

  const handleActivateIntelligence = () => {
    setIsActivating(true);
    setTimeout(() => {
      setShowLivePreview(true);
    }, 1500);

    setTimeout(() => {
      onNext({
        studioIntelligence: {
          activated: true,
          hasCalendarData,
          timestamp: new Date().toISOString()
        }
      });
    }, 5000);
  };

  const handleSkip = () => {
    onNext({
      studioIntelligence: {
        skipped: true,
        reason: 'user_choice',
        hasCalendarData
      }
    });
  };

  if (showLivePreview) {
    return (
      <div className="space-y-6">
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
            Studio Intelligence Activated! 🚀
          </h2>
          <p className="text-gray-600 mb-6">
            {hasCalendarData
              ? "Your calendar data is being analyzed. Here's a preview of your personalized insights:"
              : "Studio Intelligence is ready! Here's a preview of what you'll see once you import calendar data:"
            }
          </p>
        </div>

        {/* Live Preview */}
        <div className="bg-gray-50 rounded-xl p-6">
          <div className="mb-4">
            <h3 className="font-semibold text-gray-900 mb-2">
              {hasCalendarData ? "Your Studio Intelligence Dashboard" : "Sample Intelligence Dashboard"}
            </h3>
            <p className="text-sm text-gray-600">
              {hasCalendarData
                ? "Based on your imported calendar data"
                : "This is what you'll see with real data"
              }
            </p>
          </div>

          <StudioIntelligenceSummary
            studioId={data.studioId || 'demo-studio'}
            className="border-0 shadow-none bg-white"
          />
        </div>

        <div className="text-center">
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 2 }}
            className="text-sm text-gray-500 mb-4"
          >
            Completing setup...
          </motion.div>
        </div>
      </div>
    );
  }

  if (isActivating) {
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
            <Brain className="h-10 w-10 text-blue-600" />
          </motion.div>
        </motion.div>

        <div>
          <h2 className="text-2xl font-bold text-gray-900 mb-2">
            Activating Studio Intelligence
          </h2>
          <p className="text-gray-600">
            {hasCalendarData
              ? "Analyzing your calendar data to generate personalized insights..."
              : "Setting up your intelligence dashboard..."
            }
          </p>
        </div>

        <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 max-w-md mx-auto">
          <div className="flex items-center justify-center gap-2 text-blue-800">
            <Sparkles className="h-4 w-4" />
            <span className="text-sm font-medium">AI Analysis in Progress</span>
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
          className="w-16 h-16 bg-gradient-to-br from-purple-100 to-blue-100 rounded-full flex items-center justify-center mx-auto mb-4"
        >
          <Brain className="h-8 w-8 text-purple-600" />
        </motion.div>

        <h2 className="text-2xl font-bold text-gray-900 mb-2">
          Studio Intelligence
        </h2>
        <p className="text-gray-600 max-w-2xl mx-auto">
          Get AI-powered insights to optimize your studio operations and increase revenue.
          {hasCalendarData
            ? " Since you imported your calendar, we can provide personalized recommendations immediately!"
            : " Import your calendar data to unlock personalized insights."
          }
        </p>
      </div>

      {/* Demo Insights Carousel */}
      <div className="bg-gradient-to-r from-blue-50 to-purple-50 border border-blue-200 rounded-xl p-6">
        <div className="text-center mb-6">
          <h3 className="font-semibold text-gray-900 mb-2">
            {hasCalendarData ? "Your Potential Insights" : "Example Insights"}
          </h3>
          <p className="text-sm text-gray-600">
            {hasCalendarData
              ? "Based on similar studios with your booking patterns"
              : "Real insights from studios using our platform"
            }
          </p>
        </div>

        <div className="relative h-32 overflow-hidden rounded-lg">
          <AnimatePresence mode="wait">
            <motion.div
              key={currentDemo}
              initial={{ opacity: 0, x: 50 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -50 }}
              transition={{ duration: 0.5 }}
              className="absolute inset-0 bg-white border border-gray-200 rounded-lg p-4"
            >
              <div className="flex items-start gap-3">
                <div className={`p-2 rounded-lg ${demoInsights[currentDemo].color}`}>
                  {demoInsights[currentDemo].icon}
                </div>
                <div className="flex-1">
                  <h4 className="font-medium text-gray-900 mb-1">
                    {demoInsights[currentDemo].title}
                  </h4>
                  <p className="text-sm text-gray-600 mb-2">
                    {demoInsights[currentDemo].description}
                  </p>
                  <div className="text-sm font-medium text-green-600">
                    {demoInsights[currentDemo].impact}
                  </div>
                </div>
              </div>
            </motion.div>
          </AnimatePresence>
        </div>

        {/* Carousel Indicators */}
        <div className="flex justify-center gap-2 mt-4">
          {demoInsights.map((_, index) => (
            <button
              key={index}
              onClick={() => setCurrentDemo(index)}
              className={`w-2 h-2 rounded-full transition-colors ${
                index === currentDemo ? 'bg-blue-600' : 'bg-gray-300'
              }`}
            />
          ))}
        </div>
      </div>

      {/* Benefits Grid */}
      <div className="grid md:grid-cols-2 gap-6">
        {benefits.map((benefit, index) => (
          <motion.div
            key={benefit.title}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: index * 0.1 }}
            className="bg-white border border-gray-200 rounded-lg p-4 hover:shadow-md transition-shadow"
          >
            <div className="flex items-start gap-3">
              <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center flex-shrink-0 text-blue-600">
                {benefit.icon}
              </div>
              <div>
                <h3 className="font-semibold text-gray-900 mb-1">{benefit.title}</h3>
                <p className="text-sm text-gray-600 mb-2">{benefit.description}</p>
                <div className="text-xs font-medium text-blue-600 bg-blue-50 px-2 py-1 rounded">
                  {benefit.stats}
                </div>
              </div>
            </div>
          </motion.div>
        ))}
      </div>

      {/* Value Proposition */}
      <div className="bg-gradient-to-r from-green-50 to-emerald-50 border border-green-200 rounded-lg p-6">
        <div className="flex items-start gap-4">
          <div className="w-12 h-12 bg-green-600 rounded-lg flex items-center justify-center flex-shrink-0">
            <DollarSign className="h-6 w-6 text-white" />
          </div>
          <div>
            <h3 className="font-semibold text-gray-900 mb-2">
              {hasCalendarData
                ? "Ready for Immediate Insights"
                : "Competitive Advantage"}
            </h3>
            <p className="text-sm text-gray-700 mb-3">
              {hasCalendarData
                ? "With your calendar data imported, Studio Intelligence can provide actionable recommendations right away. Studios typically see results within the first week."
                : "Most studios operate on gut instinct. Studio Intelligence gives you data-driven insights that competitors don't have, helping you make smarter decisions about pricing, scheduling, and capacity."
              }
            </p>
            <div className="flex items-center gap-2 text-green-700">
              <Target className="h-4 w-4" />
              <span className="text-sm font-medium">
                {hasCalendarData
                  ? "Personalized recommendations ready to deploy"
                  : "Average studios see 20% revenue increase in first quarter"
                }
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* Action Buttons */}
      <div className="flex flex-col sm:flex-row gap-4 justify-center">
        <button
          onClick={handleActivateIntelligence}
          className="flex items-center justify-center gap-2 px-6 py-3 bg-gradient-to-r from-purple-600 to-blue-600 text-white font-medium rounded-lg hover:from-purple-700 hover:to-blue-700 transition-all shadow-md hover:shadow-lg"
        >
          <Zap className="h-4 w-4" />
          Activate Studio Intelligence
          <ArrowRight className="h-4 w-4" />
        </button>

        <button
          onClick={handleSkip}
          className="flex items-center justify-center gap-2 px-6 py-3 border border-gray-300 text-gray-700 font-medium rounded-lg hover:bg-gray-50 transition-colors"
        >
          <SkipForward className="h-4 w-4" />
          Set Up Later
        </button>
      </div>

      {/* Skip Information */}
      <div className="text-center">
        <p className="text-sm text-gray-500">
          {hasCalendarData
            ? "With your calendar data imported, you'll get immediate value from Studio Intelligence."
            : "You can activate Studio Intelligence anytime. Import calendar data first for the best experience."
          }
          <br />
          <span className="text-purple-600">Join thousands of studios already optimizing with AI!</span>
        </p>
      </div>
    </div>
  );
}