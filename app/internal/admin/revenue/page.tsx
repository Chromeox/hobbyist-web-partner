/**
 * Platform Revenue Analytics - Admin Portal
 *
 * Platform-wide revenue metrics and analytics
 */

'use client';

import React from 'react';
import { TrendingUp, DollarSign, BarChart3, Download } from 'lucide-react';

export default function RevenuePage() {
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Revenue Analytics</h1>
          <p className="text-gray-600 mt-1">Platform-wide revenue insights</p>
        </div>
        <button className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 flex items-center">
          <Download className="h-5 w-5 mr-2" />
          Export Report
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center justify-between mb-2">
            <DollarSign className="h-8 w-8 text-green-600" />
          </div>
          <p className="text-sm text-gray-600">Total Revenue</p>
          <p className="text-3xl font-bold text-gray-900 mt-2">$0</p>
          <p className="text-sm text-green-600 mt-1">+0% from last month</p>
        </div>

        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center justify-between mb-2">
            <TrendingUp className="h-8 w-8 text-blue-600" />
          </div>
          <p className="text-sm text-gray-600">Platform Commission</p>
          <p className="text-3xl font-bold text-gray-900 mt-2">$0</p>
          <p className="text-sm text-gray-500 mt-1">15% average</p>
        </div>

        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center justify-between mb-2">
            <BarChart3 className="h-8 w-8 text-purple-600" />
          </div>
          <p className="text-sm text-gray-600">Instructor Earnings</p>
          <p className="text-3xl font-bold text-gray-900 mt-2">$0</p>
          <p className="text-sm text-gray-500 mt-1">85% average</p>
        </div>
      </div>

      <div className="bg-white rounded-lg shadow p-6">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Revenue Trends</h2>
        <p className="text-gray-500 text-center py-8">
          Revenue charts and analytics coming soon...
          <br />
          <span className="text-sm">Will show revenue by studio, payment method, and time period</span>
        </p>
      </div>
    </div>
  );
}
