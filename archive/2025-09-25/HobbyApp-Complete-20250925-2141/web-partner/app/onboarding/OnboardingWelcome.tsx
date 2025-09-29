'use client';

import React from 'react';
import { motion } from 'framer-motion';
import {
  Building2,
  Users,
  Sparkles,
  Calendar,
  TrendingUp,
  Clock,
  ArrowRight,
  CheckCircle,
  Zap
} from 'lucide-react';

interface OnboardingWelcomeProps {
  accountType: 'studio' | 'instructor';
  businessName?: string;
  userName: string;
  onStart: () => void;
}

export default function OnboardingWelcome({
  accountType,
  businessName,
  userName,
  onStart
}: OnboardingWelcomeProps) {
  const isStudio = accountType === 'studio';

  const studioFeatures = [
    {
      icon: <Building2 className="h-5 w-5" />,
      title: "Studio Management",
      description: "Manage multiple rooms, instructors, and class schedules"
    },
    {
      icon: <Calendar className="h-5 w-5" />,
      title: "Calendar Integration",
      description: "Import from MindBody, Google Calendar, and other booking systems"
    },
    {
      icon: <TrendingUp className="h-5 w-5" />,
      title: "Revenue Analytics",
      description: "Track performance, optimize pricing, and increase bookings"
    },
    {
      icon: <Zap className="h-5 w-5" />,
      title: "AI Recommendations",
      description: "Smart insights to optimize your schedule and operations"
    }
  ];

  const instructorFeatures = [
    {
      icon: <Users className="h-5 w-5" />,
      title: "Student Management",
      description: "Track your students, their progress, and preferences"
    },
    {
      icon: <Calendar className="h-5 w-5" />,
      title: "Schedule Optimization",
      description: "Find the best times and venues for your classes"
    },
    {
      icon: <TrendingUp className="h-5 w-5" />,
      title: "Income Tracking",
      description: "Monitor your earnings and identify growth opportunities"
    },
    {
      icon: <Sparkles className="h-5 w-5" />,
      title: "Professional Growth",
      description: "Connect with studios and expand your teaching opportunities"
    }
  ];

  const features = isStudio ? studioFeatures : instructorFeatures;

  const setupSteps = isStudio ? [
    "Business information and verification",
    "Studio profile with photos and description",
    "Class offerings and pricing",
    "Payment setup and commission structure",
    "Calendar integration (optional but recommended)",
    "AI-powered insights setup (optional)"
  ] : [
    "Professional information and verification",
    "Instructor profile with experience and specialties",
    "Class offerings and availability",
    "Payment setup and rate structure",
    "Schedule optimization preferences",
    "Growth and networking setup"
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center px-4 sm:px-6 lg:px-8">
      <div className="max-w-4xl mx-auto">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
          className="text-center mb-8"
        >
          {/* Welcome Header */}
          <motion.div
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            transition={{ delay: 0.2, type: "spring", stiffness: 200 }}
            className={`w-20 h-20 ${isStudio ? 'bg-blue-100' : 'bg-purple-100'} rounded-full flex items-center justify-center mx-auto mb-6`}
          >
            {isStudio ? (
              <Building2 className="h-10 w-10 text-blue-600" />
            ) : (
              <Users className="h-10 w-10 text-purple-600" />
            )}
          </motion.div>

          <h1 className="text-4xl font-bold text-gray-900 mb-4">
            Welcome to Hobbyist, {userName}! 👋
          </h1>

          <p className="text-xl text-gray-600 mb-2">
            {isStudio ? (
              <>
                Let's get <span className="font-semibold text-blue-600">{businessName}</span> set up on our platform
              </>
            ) : (
              "Let's set up your instructor profile and start connecting with students"
            )}
          </p>

          <p className="text-gray-500">
            {isStudio
              ? "Join thousands of studios already growing their business with Hobbyist"
              : "Join hundreds of instructors already teaching through our platform"
            }
          </p>
        </motion.div>

        <div className="grid lg:grid-cols-2 gap-8 mb-8">
          {/* Features Section */}
          <motion.div
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.4 }}
            className="bg-white rounded-xl shadow-lg p-6"
          >
            <h2 className="text-xl font-semibold text-gray-900 mb-4 flex items-center gap-2">
              <Sparkles className={`h-5 w-5 ${isStudio ? 'text-blue-600' : 'text-purple-600'}`} />
              What You'll Get
            </h2>

            <div className="space-y-4">
              {features.map((feature, index) => (
                <motion.div
                  key={feature.title}
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.5 + index * 0.1 }}
                  className="flex items-start gap-3"
                >
                  <div className={`p-2 rounded-lg ${isStudio ? 'bg-blue-100 text-blue-600' : 'bg-purple-100 text-purple-600'} flex-shrink-0`}>
                    {feature.icon}
                  </div>
                  <div>
                    <h3 className="font-medium text-gray-900">{feature.title}</h3>
                    <p className="text-sm text-gray-600">{feature.description}</p>
                  </div>
                </motion.div>
              ))}
            </div>
          </motion.div>

          {/* Setup Process */}
          <motion.div
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.4 }}
            className="bg-white rounded-xl shadow-lg p-6"
          >
            <h2 className="text-xl font-semibold text-gray-900 mb-4 flex items-center gap-2">
              <Clock className={`h-5 w-5 ${isStudio ? 'text-blue-600' : 'text-purple-600'}`} />
              Setup Process (5-10 minutes)
            </h2>

            <div className="space-y-3">
              {setupSteps.map((step, index) => (
                <motion.div
                  key={index}
                  initial={{ opacity: 0, x: 10 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: 0.6 + index * 0.1 }}
                  className="flex items-center gap-3"
                >
                  <div className={`w-6 h-6 rounded-full ${isStudio ? 'bg-blue-100 text-blue-600' : 'bg-purple-100 text-purple-600'} flex items-center justify-center text-sm font-medium`}>
                    {index + 1}
                  </div>
                  <span className="text-sm text-gray-700">{step}</span>
                </motion.div>
              ))}
            </div>

            <div className={`mt-6 p-4 ${isStudio ? 'bg-blue-50 border-blue-200' : 'bg-purple-50 border-purple-200'} border rounded-lg`}>
              <div className="flex items-center gap-2 mb-2">
                <CheckCircle className={`h-4 w-4 ${isStudio ? 'text-blue-600' : 'text-purple-600'}`} />
                <span className={`text-sm font-medium ${isStudio ? 'text-blue-800' : 'text-purple-800'}`}>
                  Optional Steps
                </span>
              </div>
              <p className={`text-xs ${isStudio ? 'text-blue-700' : 'text-purple-700'}`}>
                {isStudio
                  ? "Calendar integration and AI insights are optional but highly recommended for immediate value"
                  : "You can skip any step and complete it later from your dashboard"
                }
              </p>
            </div>
          </motion.div>
        </div>

        {/* Call to Action */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.8 }}
          className="text-center"
        >
          <button
            onClick={onStart}
            className={`inline-flex items-center gap-3 px-8 py-4 ${
              isStudio
                ? 'bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700'
                : 'bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700'
            } text-white font-semibold rounded-lg shadow-lg hover:shadow-xl transition-all transform hover:scale-105`}
          >
            <span>Let's Get Started</span>
            <ArrowRight className="h-5 w-5" />
          </button>

          <p className="text-sm text-gray-500 mt-4">
            {isStudio
              ? "Ready to transform your studio operations? Let's build your profile!"
              : "Ready to expand your teaching opportunities? Let's build your profile!"
            }
          </p>
        </motion.div>

        {/* Help Section */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 1 }}
          className="text-center mt-8"
        >
          <p className="text-sm text-gray-500">
            Questions?{' '}
            <a
              href="mailto:support@hobbyist.com"
              className={`${isStudio ? 'text-blue-600 hover:text-blue-500' : 'text-purple-600 hover:text-purple-500'} font-medium`}
            >
              Contact our support team
            </a>
            {' '}or{' '}
            <a
              href="/help"
              className={`${isStudio ? 'text-blue-600 hover:text-blue-500' : 'text-purple-600 hover:text-purple-500'} font-medium`}
            >
              browse our help center
            </a>
          </p>
        </motion.div>
      </div>
    </div>
  );
}