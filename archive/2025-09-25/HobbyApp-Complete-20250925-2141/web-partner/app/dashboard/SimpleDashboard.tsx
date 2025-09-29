'use client';

import React from 'react';

interface SimpleDashboardProps {
  children: React.ReactNode;
  studioName?: string;
  userName?: string;
}

export default function SimpleDashboard({ children, studioName = 'Your Studio', userName = 'Studio Owner' }: SimpleDashboardProps) {
  return (
    <div className="min-h-screen bg-gray-50">
      <div className="p-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-4">
          {studioName} Dashboard
        </h1>
        <p className="text-gray-600 mb-8">Welcome back, {userName}!</p>
        <div className="bg-white rounded-lg shadow-md p-6">
          {children}
        </div>
      </div>
    </div>
  );
}