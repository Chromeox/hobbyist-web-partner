'use client';

import { Users, Clock } from 'lucide-react';

export default function InstructorsPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Instructor Management</h1>
        <p className="text-base text-gray-600 mt-1">
          Manage your studio's instructors and team members
        </p>
      </div>

      {/* Coming Soon Card */}
      <div className="bg-white rounded-xl border p-12 text-center">
        <div className="mx-auto flex items-center justify-center h-16 w-16 rounded-full bg-blue-100 mb-4">
          <Users className="h-8 w-8 text-blue-600" />
        </div>
        <h2 className="text-xl font-semibold text-gray-900 mb-2">Instructor Management Coming Soon</h2>
        <p className="text-gray-600 max-w-md mx-auto mb-6">
          This feature is currently under development. You'll soon be able to manage your instructors, view their schedules, and track performance metrics.
        </p>
        <div className="flex items-center justify-center gap-2 text-sm text-gray-500">
          <Clock className="h-4 w-4" />
          <span>Available in next update</span>
        </div>
      </div>
    </div>
  );
}
