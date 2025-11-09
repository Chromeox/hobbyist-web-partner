'use client';

import React, { Suspense } from 'react';
import LoadingState from '@/components/ui/LoadingState';

// Higher-order component to conditionally load admin components
interface AdminOnlyProps {
  children: React.ReactNode;
  fallback?: React.ReactNode;
  isAdmin: boolean;
}

export function AdminOnly({ children, fallback, isAdmin }: AdminOnlyProps) {
  if (!isAdmin) {
    return <>{fallback || null}</>;
  }

  return (
    <Suspense fallback={<LoadingState message="Loading admin features..." />}>
      {children}
    </Suspense>
  );
}

// Simple utility for conditional rendering with loading
export function withAdminOnly(Component: React.ComponentType<any>, loadingMessage?: string) {
  return function AdminOnlyWrapper(props: any) {
    const { isAdmin, ...otherProps } = props;
    
    if (!isAdmin) return null;
    
    return (
      <Suspense fallback={<LoadingState message={loadingMessage || "Loading admin content..."} />}>
        <Component {...otherProps} />
      </Suspense>
    );
  };
}