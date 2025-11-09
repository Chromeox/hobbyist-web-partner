'use client';

import React from 'react';
import { Loader2 } from 'lucide-react';

interface LoadingStateProps {
  message: string;
  description?: string;
  size?: 'sm' | 'md' | 'lg';
  showSpinner?: boolean;
  className?: string;
}

const sizeClasses = {
  sm: {
    container: 'py-8',
    spinner: 'h-4 w-4',
    message: 'text-sm',
    description: 'text-xs'
  },
  md: {
    container: 'py-12',
    spinner: 'h-6 w-6',
    message: 'text-base',
    description: 'text-sm'
  },
  lg: {
    container: 'py-16',
    spinner: 'h-8 w-8',
    message: 'text-lg',
    description: 'text-base'
  }
};

export default function LoadingState({ 
  message, 
  description, 
  size = 'md', 
  showSpinner = true,
  className = ''
}: LoadingStateProps) {
  const classes = sizeClasses[size];
  
  return (
    <div className={`flex flex-col items-center justify-center text-center ${classes.container} ${className}`}>
      {showSpinner && (
        <Loader2 className={`${classes.spinner} animate-spin text-blue-600 mb-3`} />
      )}
      
      <p className={`font-medium text-gray-900 ${classes.message}`}>
        {message}
      </p>
      
      {description && (
        <p className={`text-gray-600 mt-2 max-w-md ${classes.description}`}>
          {description}
        </p>
      )}
    </div>
  );
}

// Predefined loading states for common use cases
export const LoadingStates = {
  dashboard: {
    message: "Loading your studio overview...",
    description: "Preparing your dashboard with the latest data"
  },
  classes: {
    message: "Loading classes and schedules...",
    description: "Fetching your class information and upcoming sessions"
  },
  staff: {
    message: "Loading team members...",
    description: "Getting your staff and instructor information"
  },
  pricing: {
    message: "Loading pricing configuration...",
    description: "Retrieving your credit packs and commission settings"
  },
  analytics: {
    message: "Preparing analytics data...",
    description: "Processing your studio's performance metrics"
  },
  students: {
    message: "Loading student records...",
    description: "Fetching your student database and enrollment information"
  },
  reservations: {
    message: "Loading reservations...",
    description: "Getting your booking history and upcoming appointments"
  },
  revenue: {
    message: "Calculating revenue data...",
    description: "Processing your financial reports and earnings"
  },
  settings: {
    message: "Loading studio settings...",
    description: "Retrieving your configuration and preferences"
  }
};