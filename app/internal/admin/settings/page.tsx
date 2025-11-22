/**
 * Admin Settings - Admin Portal
 *
 * Platform configuration and admin user management
 */

'use client';

import React from 'react';
import { Settings, Users, Percent, Flag } from 'lucide-react';

export default function SettingsPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Admin Settings</h1>
        <p className="text-gray-600 mt-1">Configure platform settings and permissions</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center mb-4">
            <Percent className="h-6 w-6 text-blue-600 mr-2" />
            <h2 className="text-lg font-semibold">Commission Rates</h2>
          </div>
          <p className="text-gray-600 mb-4">Configure platform and studio-specific commission rates</p>
          <button className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
            Manage Commissions
          </button>
        </div>

        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center mb-4">
            <Users className="h-6 w-6 text-purple-600 mr-2" />
            <h2 className="text-lg font-semibold">Admin Users</h2>
          </div>
          <p className="text-gray-600 mb-4">Manage admin access and permissions</p>
          <button className="px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700">
            Manage Admins
          </button>
        </div>

        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center mb-4">
            <Flag className="h-6 w-6 text-orange-600 mr-2" />
            <h2 className="text-lg font-semibold">Feature Flags</h2>
          </div>
          <p className="text-gray-600 mb-4">Enable or disable platform features</p>
          <button className="px-4 py-2 bg-orange-600 text-white rounded-lg hover:bg-orange-700">
            Manage Features
          </button>
        </div>

        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center mb-4">
            <Settings className="h-6 w-6 text-gray-600 mr-2" />
            <h2 className="text-lg font-semibold">Platform Settings</h2>
          </div>
          <p className="text-gray-600 mb-4">General platform configuration</p>
          <button className="px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700">
            Configure
          </button>
        </div>
      </div>
    </div>
  );
}
