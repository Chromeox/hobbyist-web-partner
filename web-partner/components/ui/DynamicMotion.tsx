'use client';

import React, { Suspense } from 'react';
import dynamic from 'next/dynamic';

// Dynamically import framer-motion to reduce initial bundle size
const MotionDiv = dynamic(() => import('framer-motion').then(mod => ({ default: mod.motion.div })), {
  loading: () => <div />,
  ssr: false
});

const MotionSpan = dynamic(() => import('framer-motion').then(mod => ({ default: mod.motion.span })), {
  loading: () => <span />,
  ssr: false
});

const AnimatePresence = dynamic(() => import('framer-motion').then(mod => ({ default: mod.AnimatePresence })), {
  loading: () => <></>,
  ssr: false
});

interface DynamicMotionProps {
  children: React.ReactNode;
  className?: string;
  initial?: any;
  animate?: any;
  exit?: any;
  transition?: any;
  whileHover?: any;
  whileTap?: any;
  layout?: boolean;
  layoutId?: string;
}

export function DynamicMotionDiv({ children, ...props }: DynamicMotionProps) {
  return (
    <Suspense fallback={<div className={props.className}>{children}</div>}>
      <MotionDiv {...props}>
        {children}
      </MotionDiv>
    </Suspense>
  );
}

export function DynamicMotionSpan({ children, ...props }: DynamicMotionProps) {
  return (
    <Suspense fallback={<span className={props.className}>{children}</span>}>
      <MotionSpan {...props}>
        {children}
      </MotionSpan>
    </Suspense>
  );
}

export function DynamicAnimatePresence({ children, mode }: { children: React.ReactNode; mode?: string }) {
  return (
    <Suspense fallback={<>{children}</>}>
      <AnimatePresence mode={mode as any}>
        {children}
      </AnimatePresence>
    </Suspense>
  );
}

// Fallback components for when motion is disabled
export function StaticDiv({ children, className, ...rest }: any) {
  return <div className={className}>{children}</div>;
}

export function StaticSpan({ children, className, ...rest }: any) {
  return <span className={className}>{children}</span>;
}

// Hook to check if user prefers reduced motion
export function useReducedMotion() {
  const [prefersReducedMotion, setPrefersReducedMotion] = React.useState(false);
  
  React.useEffect(() => {
    const mediaQuery = window.matchMedia('(prefers-reduced-motion: reduce)');
    setPrefersReducedMotion(mediaQuery.matches);
    
    const handler = () => setPrefersReducedMotion(mediaQuery.matches);
    mediaQuery.addEventListener('change', handler);
    
    return () => mediaQuery.removeEventListener('change', handler);
  }, []);
  
  return prefersReducedMotion;
}