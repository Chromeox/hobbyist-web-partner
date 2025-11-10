'use client';

import React, { Suspense } from 'react';
import dynamic from 'next/dynamic';
import LoadingState from '@/components/ui/LoadingState';

// Dynamically import Recharts components to reduce bundle size
// These are heavy components only used in admin/analytics pages
const LineChart = dynamic(() => import('recharts').then(mod => ({ default: mod.LineChart })), {
  loading: () => <LoadingState message="Loading chart..." size="sm" />,
  ssr: false
});

const BarChart = dynamic(() => import('recharts').then(mod => ({ default: mod.BarChart })), {
  loading: () => <LoadingState message="Loading chart..." size="sm" />,
  ssr: false
});

const AreaChart = dynamic(() => import('recharts').then(mod => ({ default: mod.AreaChart })), {
  loading: () => <LoadingState message="Loading chart..." size="sm" />,
  ssr: false
});

const PieChart = dynamic(() => import('recharts').then(mod => ({ default: mod.PieChart })), {
  loading: () => <LoadingState message="Loading chart..." size="sm" />,
  ssr: false
});

const Line = dynamic(() => import('recharts').then(mod => ({ default: mod.Line })), {
  ssr: false
});

const Bar = dynamic(() => import('recharts').then(mod => ({ default: mod.Bar })), {
  ssr: false
});

const Area = dynamic(() => import('recharts').then(mod => ({ default: mod.Area })), {
  ssr: false
});

const XAxis = dynamic(() => import('recharts').then(mod => ({ default: mod.XAxis })), {
  ssr: false
});

const YAxis = dynamic(() => import('recharts').then(mod => ({ default: mod.YAxis })), {
  ssr: false
});

const CartesianGrid = dynamic(() => import('recharts').then(mod => ({ default: mod.CartesianGrid })), {
  ssr: false
});

const Tooltip = dynamic(() => import('recharts').then(mod => ({ default: mod.Tooltip })), {
  ssr: false
});

const ResponsiveContainer = dynamic(() => import('recharts').then(mod => ({ default: mod.ResponsiveContainer })), {
  ssr: false
});

const Legend = dynamic(() => import('recharts').then(mod => ({ default: mod.Legend })) as any, {
  ssr: false
});

// Wrapper components for easier use
interface DynamicLineChartProps {
  data: any[];
  children: React.ReactNode;
}

export function DynamicLineChart({ data, children, ...props }: DynamicLineChartProps & any) {
  return (
    <Suspense fallback={<LoadingState message="Loading line chart..." size="sm" />}>
      <ResponsiveContainer width="100%" height={350}>
        <LineChart data={data} {...props}>
          {children}
        </LineChart>
      </ResponsiveContainer>
    </Suspense>
  );
}

export function DynamicBarChart({ data, children, ...props }: DynamicLineChartProps & any) {
  return (
    <Suspense fallback={<LoadingState message="Loading bar chart..." size="sm" />}>
      <ResponsiveContainer width="100%" height={350}>
        <BarChart data={data} {...props}>
          {children}
        </BarChart>
      </ResponsiveContainer>
    </Suspense>
  );
}

export function DynamicAreaChart({ data, children, ...props }: DynamicLineChartProps & any) {
  return (
    <Suspense fallback={<LoadingState message="Loading area chart..." size="sm" />}>
      <ResponsiveContainer width="100%" height={350}>
        <AreaChart data={data} {...props}>
          {children}
        </AreaChart>
      </ResponsiveContainer>
    </Suspense>
  );
}

// Export all components for direct use
export {
  LineChart,
  BarChart,
  AreaChart,
  PieChart,
  Line,
  Bar,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend
};

// Fallback components for when charts fail to load
export function ChartFallback({ message = "Chart unavailable" }: { message?: string }) {
  return (
    <div className="flex items-center justify-center h-64 bg-gray-50 rounded-lg border border-gray-200">
      <div className="text-center">
        <div className="w-12 h-12 mx-auto mb-4 bg-gray-200 rounded-lg flex items-center justify-center">
          <div className="w-6 h-6 bg-gray-400 rounded"></div>
        </div>
        <p className="text-sm text-gray-600">{message}</p>
      </div>
    </div>
  );
}