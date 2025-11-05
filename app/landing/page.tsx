'use client';

import { motion } from 'framer-motion';
import { useRouter } from 'next/navigation';
import type { FC } from 'react';
import HeroSection from './components/HeroSection';
import ActionButtons from './components/ActionButtons';

const LandingPage: FC = () => {
  const router = useRouter();

  const handleLogin = () => {
    router.push('/auth/signin');
  };

  const handleRegister = () => {
    router.push('/auth/signup');
  };

  const handleGuest = () => {
    router.push('/dashboard?guest=true');
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-200 via-pink-200 to-purple-300 relative overflow-hidden">

      {/* Main Content */}
      <div className="relative z-10 flex flex-col items-center justify-center min-h-screen px-4 py-8">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
          className="w-full max-w-md"
        >
          {/* Back Button */}
          <motion.button
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.2 }}
            onClick={() => router.back()}
            className="mb-6 text-white/80 hover:text-white transition-colors"
            aria-label="Go back"
          >
            <svg
              className="w-8 h-8"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M15 19l-7-7 7-7"
              />
            </svg>
          </motion.button>

          {/* Progress Bar */}
          <motion.div
            initial={{ scaleX: 0 }}
            animate={{ scaleX: 1 }}
            transition={{ delay: 0.3, duration: 0.5 }}
            className="h-1 bg-white/30 rounded-full mb-8 overflow-hidden"
          >
            <motion.div
              initial={{ width: "0%" }}
              animate={{ width: "100%" }}
              transition={{ delay: 0.5, duration: 1 }}
              className="h-full bg-white rounded-full"
            />
          </motion.div>

          {/* Hero Section */}
          <HeroSection />

          {/* Content Section */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.8 }}
            className="bg-white rounded-t-3xl shadow-2xl p-8 -mt-8"
          >
            <div className="text-center mb-8">
              <h1 className="text-3xl font-bold text-gray-900 mb-3">
                Find your next hobby here🚀
              </h1>
              <p className="text-gray-600 text-base">
                Take your first step into creativity! 
              </p>
            </div>

            {/* Action Buttons */}
            <ActionButtons
              onLogin={handleLogin}
              onRegister={handleRegister}
              onGuest={handleGuest}
            />
          </motion.div>

          {/* Bottom Indicator */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 1.2 }}
            className="flex justify-center mt-6"
          >
            <div className="w-32 h-1 bg-gray-800 rounded-full" />
          </motion.div>
        </motion.div>
      </div>
    </div>
  );
};

export default LandingPage;