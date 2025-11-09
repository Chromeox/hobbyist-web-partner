'use client';

import React, { Suspense } from 'react';
import dynamic from 'next/dynamic';
import LoadingState from '@/components/ui/LoadingState';

// Dynamically import chart components to reduce initial bundle size
const LineChart = dynamic(() => import('react-chartjs-2').then(mod => ({ default: mod.Line })), {
  loading: () => <LoadingState message="Loading chart..." size="sm" />,
  ssr: false
});

const BarChart = dynamic(() => import('react-chartjs-2').then(mod => ({ default: mod.Bar })), {
  loading: () => <LoadingState message="Loading chart..." size="sm" />,
  ssr: false
});

const DoughnutChart = dynamic(() => import('react-chartjs-2').then(mod => ({ default: mod.Doughnut })), {
  loading: () => <LoadingState message="Loading chart..." size="sm" />,
  ssr: false
});

interface ChartProps {
  type: 'line' | 'bar' | 'doughnut';
  data: any;
  options?: any;
  className?: string;
}

export default function DynamicChart({ type, data, options, className }: ChartProps) {
  return (
    <Suspense fallback={<LoadingState message="Loading chart..." size="sm" />}>
      <div className={className}>
        {type === 'line' && <LineChart data={data} options={options} />}
        {type === 'bar' && <BarChart data={data} options={options} />}
        {type === 'doughnut' && <DoughnutChart data={data} options={options} />}
      </div>
    </Suspense>
  );
}

// Export individual chart components for direct use
export { LineChart, BarChart, DoughnutChart };