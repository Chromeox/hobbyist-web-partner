'use client';

import { motion } from 'framer-motion';
import type { FC } from 'react';

const HeroSection: FC = () => {
  return (
    <div className="relative mb-8">
      {/* Speech Bubbles */}
      <motion.div
        initial={{ opacity: 0, scale: 0.8, x: -20 }}
        animate={{ opacity: 1, scale: 1, x: 0 }}
        transition={{ delay: 0.5, type: "spring", stiffness: 200 }}
        className="absolute top-8 left-8 z-20"
      >
        <div className="bg-gray-900 text-white px-4 py-2 rounded-2xl rounded-bl-none shadow-lg text-sm font-medium">
          Let's learning!
        </div>
      </motion.div>

      <motion.div
        initial={{ opacity: 0, scale: 0.8, x: 20 }}
        animate={{ opacity: 1, scale: 1, x: 0 }}
        transition={{ delay: 0.6, type: "spring", stiffness: 200 }}
        className="absolute top-8 right-8 z-20"
      >
        <div className="bg-gray-900 text-white px-4 py-2 rounded-2xl rounded-br-none shadow-lg text-sm font-medium">
          Let's go!
        </div>
      </motion.div>

      {/* Hero Illustration */}
      <motion.div
        initial={{ opacity: 0, y: 30 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.4, duration: 0.8 }}
        className="relative w-full aspect-[4/5] bg-gradient-to-b from-purple-300/50 to-pink-300/50 rounded-3xl overflow-hidden shadow-xl"
      >

        {/* Main illustration placeholder - using a colorful gradient with shapes */}
        <div className="absolute inset-0 flex items-center justify-center">
          <motion.div
            initial={{ scale: 0.8, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            transition={{ delay: 0.6, duration: 0.6 }}
            className="relative w-full h-full flex items-end justify-center pb-8"
          >
            {/* Left Character Silhouette */}
            <motion.div
              animate={{
                y: [0, -8, 0],
              }}
              transition={{
                duration: 3,
                repeat: Infinity,
                ease: "easeInOut"
              }}
              className="relative mr-4"
            >
              <div className="w-32 h-48 bg-gradient-to-b from-yellow-400 to-red-400 rounded-full opacity-90 shadow-2xl" />
              <div className="absolute -top-2 left-1/2 -translate-x-1/2 w-20 h-20 bg-gradient-to-br from-amber-600 to-amber-800 rounded-full shadow-lg" />
              <motion.div
                animate={{
                  rotate: [0, 10, -10, 0],
                }}
                transition={{
                  duration: 2,
                  repeat: Infinity,
                  ease: "easeInOut"
                }}
                className="absolute top-12 -left-8 w-12 h-24 bg-yellow-500 rounded-full shadow-lg"
              />
            </motion.div>

            {/* Right Character Silhouette */}
            <motion.div
              animate={{
                y: [0, -10, 0],
              }}
              transition={{
                duration: 3.5,
                repeat: Infinity,
                ease: "easeInOut",
                delay: 0.5
              }}
              className="relative ml-4"
            >
              <div className="w-32 h-48 bg-gradient-to-b from-blue-400 to-blue-600 rounded-full opacity-90 shadow-2xl" />
              <div className="absolute -top-2 left-1/2 -translate-x-1/2 w-20 h-20 bg-gradient-to-br from-amber-700 to-gray-900 rounded-full shadow-lg" />
              <motion.div
                animate={{
                  rotate: [0, -10, 10, 0],
                }}
                transition={{
                  duration: 2.5,
                  repeat: Infinity,
                  ease: "easeInOut"
                }}
                className="absolute top-12 -right-8 w-12 h-24 bg-pink-300 rounded-full shadow-lg"
              />
            </motion.div>
          </motion.div>
        </div>

        {/* Ground/Floor element */}
        <div className="absolute bottom-0 left-0 right-0 h-24 bg-gradient-to-t from-pink-400/60 to-transparent" />
      </motion.div>
    </div>
  );
};

export default HeroSection;