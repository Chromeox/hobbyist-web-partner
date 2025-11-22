/**
 * Studio Approvals - Admin Portal
 *
 * Reuses existing StudioApprovalDashboard component
 * Moved from /dashboard/admin/studio-approval
 */

'use client';

import React from 'react';
import dynamic from 'next/dynamic';

// Dynamically import the existing studio approval component
const StudioApprovalDashboard = dynamic(
  () => import('@/components/admin/StudioApprovalDashboard'),
  {
    loading: () => (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    ),
    ssr: false,
  }
);

export default function StudioApprovalsPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Studio Approvals</h1>
        <p className="text-gray-600 mt-1">Review and approve studio applications</p>
      </div>

      <StudioApprovalDashboard />
    </div>
  );
}
