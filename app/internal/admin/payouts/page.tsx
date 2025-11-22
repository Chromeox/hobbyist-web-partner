/**
 * Platform-Wide Payouts - Admin Portal
 *
 * View and process all payouts across all studios/instructors
 */

'use client';

import React from 'react';
import { DollarSign, Clock, CheckCircle, AlertCircle } from 'lucide-react';

export default function PayoutsPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Platform Payouts</h1>
        <p className="text-gray-600 mt-1">Manage all payouts across the platform</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center justify-between mb-2">
            <DollarSign className="h-8 w-8 text-green-600" />
          </div>
          <p className="text-sm text-gray-600">Total Payouts</p>
          <p className="text-3xl font-bold text-gray-900 mt-2">$0</p>
        </div>

        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center justify-between mb-2">
            <Clock className="h-8 w-8 text-yellow-600" />
          </div>
          <p className="text-sm text-gray-600">Pending</p>
          <p className="text-3xl font-bold text-gray-900 mt-2">$0</p>
        </div>

        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center justify-between mb-2">
            <CheckCircle className="h-8 w-8 text-green-600" />
          </div>
          <p className="text-sm text-gray-600">Completed</p>
          <p className="text-3xl font-bold text-gray-900 mt-2">$0</p>
        </div>

        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center justify-between mb-2">
            <AlertCircle className="h-8 w-8 text-red-600" />
          </div>
          <p className="text-sm text-gray-600">Failed</p>
          <p className="text-3xl font-bold text-gray-900 mt-2">$0</p>
        </div>
      </div>

      <div className="bg-white rounded-lg shadow p-6">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Recent Payouts</h2>
        <p className="text-gray-500 text-center py-8">
          Payout management interface coming soon...
          <br />
          <span className="text-sm">Will show all instructor payouts with filtering and bulk processing</span>
        </p>
      </div>
    </div>
  );
}
