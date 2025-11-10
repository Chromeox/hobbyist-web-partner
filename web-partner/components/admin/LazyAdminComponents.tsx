'use client';

import React, { Suspense } from 'react';
import dynamic from 'next/dynamic';
import LoadingState from '@/components/ui/LoadingState';

// Dynamically import admin-only components to reduce main bundle size
// These components are only loaded when users access admin pages

const PayoutDashboard = dynamic(() => import('../../app/dashboard/payouts/PayoutDashboard'), {
  loading: () => <LoadingState message="Loading payout dashboard..." />,
  ssr: false
});

const FinancialReports = dynamic(() => import('../../app/dashboard/payouts/FinancialReports'), {
  loading: () => <LoadingState message="Loading financial reports..." />,
  ssr: false
});

const CommissionCalculator = dynamic(() => import('../../app/dashboard/payouts/CommissionCalculator'), {
  loading: () => <LoadingState message="Loading commission calculator..." />,
  ssr: false
});

const InstructorApprovals = dynamic(() => import('../../app/dashboard/admin/instructor-approvals/page'), {
  loading: () => <LoadingState message="Loading instructor approvals..." />,
  ssr: false
});

const StudioApproval = dynamic(() => import('../../app/dashboard/admin/studio-approval/page'), {
  loading: () => <LoadingState message="Loading studio approval..." />,
  ssr: false
});

// Wrapper components with error boundaries
interface AdminComponentWrapperProps {
  children: React.ReactNode;
  fallback?: React.ReactNode;
}

function AdminComponentWrapper({ children, fallback }: AdminComponentWrapperProps) {
  return (
    <Suspense fallback={fallback || <LoadingState message="Loading admin features..." />}>
      {children}
    </Suspense>
  );
}

// Export wrapped components for easier use
export function LazyPayoutDashboard(props: any) {
  return (
    <AdminComponentWrapper>
      <PayoutDashboard {...props} />
    </AdminComponentWrapper>
  );
}

export function LazyFinancialReports(props: any) {
  return (
    <AdminComponentWrapper>
      <FinancialReports {...props} />
    </AdminComponentWrapper>
  );
}

export function LazyCommissionCalculator(props: any) {
  return (
    <AdminComponentWrapper>
      <CommissionCalculator {...props} />
    </AdminComponentWrapper>
  );
}

export function LazyInstructorApprovals(props: any) {
  return (
    <AdminComponentWrapper>
      <InstructorApprovals {...props} />
    </AdminComponentWrapper>
  );
}

export function LazyStudioApproval(props: any) {
  return (
    <AdminComponentWrapper>
      <StudioApproval {...props} />
    </AdminComponentWrapper>
  );
}

// Generic lazy admin component loader
export function LazyAdminComponent({ 
  component, 
  loadingMessage = "Loading admin component...",
  ...props 
}: { 
  component: string; 
  loadingMessage?: string;
  [key: string]: any;
}) {
  const Component = dynamic(() => import(`../../${component}`), {
    loading: () => <LoadingState message={loadingMessage} />,
    ssr: false
  });

  return (
    <AdminComponentWrapper>
      <Component {...props} />
    </AdminComponentWrapper>
  );
}