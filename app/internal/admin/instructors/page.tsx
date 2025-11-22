/**
 * Instructors Management - Admin Portal
 *
 * All instructors list with filtering and quick actions
 */

'use client';

import React from 'react';
import Link from 'next/link';
import { Users, Clock, CheckCircle } from 'lucide-react';

export default function InstructorsPage() {
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Instructors</h1>
          <p className="text-gray-600 mt-1">Manage all instructors on the platform</p>
        </div>
        <Link
          href="/internal/admin/instructors/pending"
          className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 flex items-center"
        >
          <Clock className="h-5 w-5 mr-2" />
          Pending Approvals
        </Link>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center justify-between mb-2">
            <Users className="h-8 w-8 text-blue-600" />
          </div>
          <p className="text-sm text-gray-600">Total Instructors</p>
          <p className="text-3xl font-bold text-gray-900 mt-2">-</p>
        </div>

        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center justify-between mb-2">
            <CheckCircle className="h-8 w-8 text-green-600" />
          </div>
          <p className="text-sm text-gray-600">Active Instructors</p>
          <p className="text-3xl font-bold text-gray-900 mt-2">-</p>
        </div>

        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center justify-between mb-2">
            <Clock className="h-8 w-8 text-yellow-600" />
          </div>
          <p className="text-sm text-gray-600">Pending Approval</p>
          <p className="text-3xl font-bold text-gray-900 mt-2">-</p>
        </div>
      </div>

      <div className="bg-white rounded-lg shadow">
        <div className="p-6">
          <p className="text-gray-500 text-center py-8">Instructor list coming soon...</p>
        </div>
      </div>
    </div>
  );
}
