'use client';

import { motion } from 'framer-motion';
import type { FC } from 'react';

interface ActionButtonsProps {
  onLogin: () => void;
  onRegister: () => void;
  onGuest: () => void;
}

const ActionButtons: FC<ActionButtonsProps> = ({ onLogin, onRegister, onGuest }) => {
  return (
    <div className="space-y-4">
      {/* Primary Action Buttons */}
      <div className="grid grid-cols-2 gap-4">
        <motion.button
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.9 }}
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.98 }}
          onClick={onLogin}
          className="px-6 py-4 bg-gray-900 text-white font-semibold rounded-2xl shadow-lg hover:bg-gray-800 transition-colors"
        >
          Log In
        </motion.button>

        <motion.button
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 1.0 }}
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.98 }}
          onClick={onRegister}
          className="px-6 py-4 bg-gray-900 text-white font-semibold rounded-2xl shadow-lg hover:bg-gray-800 transition-colors"
        >
          Register
        </motion.button>
      </div>

      {/* Guest Button */}
      <motion.button
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 1.1 }}
        whileHover={{ scale: 1.02 }}
        whileTap={{ scale: 0.98 }}
        onClick={onGuest}
        className="w-full px-6 py-4 bg-white text-gray-900 font-semibold rounded-2xl border-2 border-gray-900 shadow-md hover:bg-gray-50 transition-colors"
      >
        Continue with Guest
      </motion.button>
    </div>
  );
};

export default ActionButtons;