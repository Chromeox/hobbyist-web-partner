'use client';

import React, { useMemo, useCallback, memo } from 'react';
import { motion } from 'framer-motion';
import {
  TrendingUp,
  TrendingDown,
  Users,
  Calendar,
  DollarSign,
  Star,
  Activity,
  RefreshCw,
  Filter
} from 'lucide-react';
import { Line, Bar, Doughnut } from 'react-chartjs-2';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  Title,
  Tooltip,
  Legend,
  Filler
} from 'chart.js';
import {
  useDashboardStats,
  useClasses,
  useInstructors,
  usePrefetch,
  useRealtimeSubscription,
  useCacheManager
} from '../../lib/hooks/useOptimizedData';

// Register Chart.js components once
ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  Title,
  Tooltip,
  Legend,
  Filler
);

// Memoized KPI Card component to prevent re-renders
const KPICard = memo(({ 
  title, 
  value, 
  change, 
  changeType, 
  icon: Icon, 
  color 
}: {
  title: string;
  value: string | number;
  change: number;
  changeType: 'increase' | 'decrease';
  icon: React.ElementType;
  color: string;
}) => (
  <motion.div
    initial={{ opacity: 0, y: 20 }}
    animate={{ opacity: 1, y: 0 }}
    className="bg-white rounded-lg p-6 shadow-sm border border-gray-100"
  >
    <div className="flex justify-between items-start">
      <div>
        <p className="text-gray-600 text-sm font-medium">{title}</p>
        <p className="text-2xl font-bold mt-2">{value}</p>
        <div className="flex items-center mt-3">
          {changeType === 'increase' ? (
            <TrendingUp className="w-4 h-4 text-green-500 mr-1" />
          ) : (
            <TrendingDown className="w-4 h-4 text-red-500 mr-1" />
          )}
          <span className={`text-sm font-medium ${
            changeType === 'increase' ? 'text-green-600' : 'text-red-600'
          }`}>
            {Math.abs(change)}%
          </span>
          <span className="text-gray-500 text-sm ml-1">vs last week</span>
        </div>
      </div>
      <div className={`p-3 rounded-lg bg-${color}-50`}>
        <Icon className={`w-6 h-6 text-${color}-600`} />
      </div>
    </div>
  </motion.div>
));

KPICard.displayName = 'KPICard';

// Memoized chart component
const RevenueChart = memo(({ data }: { data: any }) => {
  const chartData = useMemo(() => ({
    labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    datasets: [{
      label: 'Revenue',
      data: data || [1200, 1900, 1500, 2200, 2800, 2400, 3200],
      borderColor: 'rgb(99, 102, 241)',
      backgroundColor: 'rgba(99, 102, 241, 0.1)',
      tension: 0.4,
      fill: true
    }]
  }), [data]);

  const options = useMemo(() => ({
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { display: false },
      tooltip: {
        callbacks: {
          label: (context: any) => `$${context.parsed.y}`
        }
      }
    },
    scales: {
      y: {
        beginAtZero: true,
        ticks: {
          callback: (value: any) => `$${value}`
        }
      }
    }
  }), []);

  return (
    <div className="h-64">
      <Line data={chartData} options={options} />
    </div>
  );
});

RevenueChart.displayName = 'RevenueChart';

// Main optimized dashboard component
export default function OptimizedDashboardOverview() {
  // Prefetch data on mount
  usePrefetch();
  
  // Use optimized data hooks
  const { data: stats, isLoading, refetch } = useDashboardStats();
  const { classes } = useClasses(undefined, 10);
  const { instructors } = useInstructors(10);
  const { clearCache } = useCacheManager();
  
  // Real-time updates
  useRealtimeSubscription('bookings', useCallback((payload) => {
    // Invalidate cache and refetch on real-time updates
    clearCache();
    refetch();
  }, [clearCache, refetch]));
  
  // Memoized KPI data with stable shape
  const kpiData = useMemo(() => {
    if (!stats) return [];
    
    return [
      {
        title: 'Total Revenue',
        value: `$${(stats.totalRevenue / 100).toLocaleString()}`,
        change: 12.5,
        changeType: 'increase' as const,
        icon: DollarSign,
        color: 'green'
      },
      {
        title: 'Active Students',
        value: stats.totalUsers,
        change: 8.2,
        changeType: 'increase' as const,
        icon: Users,
        color: 'blue'
      },
      {
        title: 'Total Classes',
        value: stats.totalClasses,
        change: -2.3,
        changeType: 'decrease' as const,
        icon: Calendar,
        color: 'purple'
      },
      {
        title: 'Total Bookings',
        value: stats.totalBookings,
        change: 15.7,
        changeType: 'increase' as const,
        icon: Activity,
        color: 'yellow'
      }
    ];
  }, [stats]);
  
  // Memoized chart data
  const classDistribution = useMemo(() => ({
    labels: ['Yoga', 'Fitness', 'Dance', 'Music', 'Art'],
    datasets: [{
      data: [30, 25, 20, 15, 10],
      backgroundColor: [
        'rgba(99, 102, 241, 0.8)',
        'rgba(34, 197, 94, 0.8)',
        'rgba(168, 85, 247, 0.8)',
        'rgba(251, 146, 60, 0.8)',
        'rgba(236, 72, 153, 0.8)'
      ]
    }]
  }), []);
  
  if (isLoading && !stats) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center">
          <RefreshCw className="w-8 h-8 animate-spin text-indigo-600 mx-auto mb-4" />
          <p className="text-gray-600">Loading dashboard...</p>
        </div>
      </div>
    );
  }
  
  return (
    <div className="p-6 space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold">Dashboard</h1>
          <p className="text-gray-600 mt-1">Welcome back! Here's your studio overview.</p>
        </div>
        <button
          onClick={refetch}
          className="flex items-center px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors"
        >
          <RefreshCw className="w-4 h-4 mr-2" />
          Refresh
        </button>
      </div>
      
      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {kpiData.map((kpi, index) => (
          <KPICard key={kpi.title} {...kpi} />
        ))}
      </div>
      
      {/* Charts Section */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Revenue Chart */}
        <div className="lg:col-span-2 bg-white rounded-lg p-6 shadow-sm border border-gray-100">
          <h3 className="text-lg font-semibold mb-4">Revenue Trend</h3>
          <RevenueChart data={null} />
        </div>
        
        {/* Class Distribution */}
        <div className="bg-white rounded-lg p-6 shadow-sm border border-gray-100">
          <h3 className="text-lg font-semibold mb-4">Class Distribution</h3>
          <div className="h-64">
            <Doughnut 
              data={classDistribution} 
              options={{
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                  legend: {
                    position: 'bottom' as const
                  }
                }
              }}
            />
          </div>
        </div>
      </div>
      
      {/* Recent Activity */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Recent Classes */}
        <div className="bg-white rounded-lg p-6 shadow-sm border border-gray-100">
          <h3 className="text-lg font-semibold mb-4">Recent Classes</h3>
          <div className="space-y-3">
            {classes.slice(0, 5).map((cls: any) => (
              <div key={cls.id} className="flex justify-between items-center py-2 border-b last:border-0">
                <div>
                  <p className="font-medium">{cls.title}</p>
                  <p className="text-sm text-gray-600">{cls.categories?.name}</p>
                </div>
                <span className="text-sm font-medium text-indigo-600">
                  ${cls.price}
                </span>
              </div>
            ))}
          </div>
        </div>
        
        {/* Top Instructors */}
        <div className="bg-white rounded-lg p-6 shadow-sm border border-gray-100">
          <h3 className="text-lg font-semibold mb-4">Top Instructors</h3>
          <div className="space-y-3">
            {instructors.slice(0, 5).map((instructor: any) => (
              <div key={instructor.id} className="flex justify-between items-center py-2 border-b last:border-0">
                <div className="flex items-center">
                  <div className="w-10 h-10 bg-indigo-100 rounded-full flex items-center justify-center">
                    <span className="text-indigo-600 font-medium">
                      {instructor.user_profiles?.first_name?.[0]}
                      {instructor.user_profiles?.last_name?.[0]}
                    </span>
                  </div>
                  <div className="ml-3">
                    <p className="font-medium">
                      {instructor.user_profiles?.first_name} {instructor.user_profiles?.last_name}
                    </p>
                    <p className="text-sm text-gray-600">
                      {instructor.total_students} students
                    </p>
                  </div>
                </div>
                <div className="flex items-center">
                  <Star className="w-4 h-4 text-yellow-500 mr-1" />
                  <span className="text-sm font-medium">{instructor.rating.toFixed(1)}</span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}