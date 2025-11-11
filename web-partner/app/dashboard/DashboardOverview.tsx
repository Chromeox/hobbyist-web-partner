/**
 * Dashboard Overview Component
 * 
 * DATA SOURCE INFORMATION:
 * - Currently displays DEMO DATA for development/testing
 * - In production, this will fetch REAL DATA from your Supabase database
 * - The "Popular Classes" section will show YOUR STUDIO'S actual classes
 * - Data will be fetched based on the logged-in studio owner's account
 * 
 * To enable real data:
 * 1. Ensure Supabase tables are set up (classes, bookings, etc.)
 * 2. Uncomment the real data fetching code in useEffect
 * 3. Remove the mock data assignments
 * 
 * The system is fully prepared to display your studio's actual data!
 */

'use client';

import React, { useState, useEffect, useRef, useMemo } from 'react';
import { useRouter } from 'next/navigation';
import StudioIntelligenceSummary from '../../components/studio/StudioIntelligenceSummary';
import { motion } from 'framer-motion';
import { dashboardService } from '@/lib/services/dashboard';
import { formatCurrency } from '@/lib/utils';
import type { DashboardPeriod } from '@/lib/utils/dateRange';
import {
  TrendingUp,
  TrendingDown,
  Users,
  Calendar,
  DollarSign,
  Star,
  Clock,
  Activity,
  BookOpen,
  Target,
  Award,
  AlertCircle,
  ChevronRight,
  Download,
  RefreshCw,
  Filter,
  Plus
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

interface KPICard {
  title: string;
  value: string | number;
  change: number;
  changeType: 'increase' | 'decrease';
  icon: React.ElementType;
  color: string;
}

interface DashboardOverviewProps {
  studioId: string | null;
}

const SkeletonCard = () => (
    <div className="relative overflow-hidden bg-gray-100 border rounded-xl p-4 animate-pulse">
        <div className="h-6 bg-gray-200 rounded w-1/4 mb-2"></div>
        <div className="h-8 bg-gray-200 rounded w-1/2 mb-4"></div>
        <div className="h-4 bg-gray-200 rounded w-full"></div>
    </div>
);

interface EmptyStateProps {
  title: string;
  message: string;
  actionText?: string;
  onAction?: () => void;
  icon?: React.ElementType;
}

const EmptyState = ({ title, message, actionText, onAction, icon: Icon = BookOpen }: EmptyStateProps) => (
  <div className="text-center py-12">
    <div className="mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-gray-100">
      <Icon className="h-6 w-6 text-gray-400" />
    </div>
    <h3 className="mt-2 text-sm font-medium text-gray-900">{title}</h3>
    <p className="mt-1 text-sm text-gray-500">{message}</p>
    {actionText && onAction && (
      <div className="mt-6">
        <button
          type="button"
          onClick={onAction}
          className="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
        >
          <Plus className="-ml-1 mr-2 h-5 w-5" />
          {actionText}
        </button>
      </div>
    )}
  </div>
);

export default function DashboardOverview({ studioId }: DashboardOverviewProps) {
  const router = useRouter();
  const effectiveStudioId = studioId || 'demo-studio-id';
  const [selectedPeriod, setSelectedPeriod] = useState<DashboardPeriod>('week');
  const [isLoading, setIsLoading] = useState(true);
  const [kpiData, setKpiData] = useState<KPICard[]>([]);
  const [revenueSeries, setRevenueSeries] = useState<{ labels: string[]; values: number[] }>({ labels: [], values: [] });
  const [classPopularity, setClassPopularity] = useState<{ labels: string[]; values: number[] }>({ labels: [], values: [] });
  const [scheduleSummary, setScheduleSummary] = useState<{ totalClasses: number; totalSeats: number; seatsBooked: number; occupancyPercent: number } | null>(null);
  const [upcomingClasses, setUpcomingClasses] = useState<any[]>([]);
  const [recentActivities, setRecentActivities] = useState<any[]>([]);
  const [quickStats, setQuickStats] = useState<{ todaysRevenue: number; activeClasses: number }>({ todaysRevenue: 0, activeClasses: 0 });
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const chartRef = useRef<ChartJS<'line', (number | null)[], unknown> | null>(null);

  const formatPeriodValue = (id: string, value: number) => {
    if (id === 'revenue') {
      return formatCurrency(value);
    }
    return value.toLocaleString();
  };

  const formatTimeRange = (start: string, end: string) => {
    const startDate = new Date(start);
    const endDate = new Date(end);
    const formatter = new Intl.DateTimeFormat('en-US', {
      hour: 'numeric',
      minute: '2-digit'
    });

    return `${formatter.format(startDate)} - ${formatter.format(endDate)}`;
  };

  const formatTimestamp = (timestamp: string) => {
    const date = new Date(timestamp);
    return date.toLocaleString();
  };

  const fetchDashboardData = async (period: DashboardPeriod = selectedPeriod) => {
    setIsLoading(true);
    setErrorMessage(null);
    try {
      const [metrics, revenueTrend, popularClasses, scheduleOverview, activityFeed] = await Promise.all([
        dashboardService.getMetrics({ studioId: effectiveStudioId, period }),
        dashboardService.getRevenueTrend({ studioId: effectiveStudioId, period }),
        dashboardService.getPopularClasses({ studioId: effectiveStudioId, period, limit: 5 }),
        dashboardService.getSchedule({ studioId: effectiveStudioId }),
        dashboardService.getActivity({ studioId: effectiveStudioId, period, limit: 10 })
      ]);

      const kpiIconMap: Record<string, React.ElementType> = {
        revenue: DollarSign,
        bookings: Users,
        schedules: Calendar,
        instructors: Star
      };

      const kpiColorMap: Record<string, string> = {
        revenue: 'green',
        bookings: 'blue',
        schedules: 'purple',
        instructors: 'yellow'
      };

      const nextKpis: KPICard[] = metrics.kpis.map(kpi => {
        const change = Math.abs(Math.round(kpi.deltaPercent));
        const changeType = kpi.deltaPercent >= 0 ? 'increase' : 'decrease';
        const icon = kpiIconMap[kpi.id] ?? TrendingUp;
        const color = kpiColorMap[kpi.id] ?? 'blue';

        return {
          title: kpi.title,
          value: formatPeriodValue(kpi.id, kpi.value),
          change,
          changeType,
          icon,
          color
        };
      });

      setKpiData(nextKpis);
      setQuickStats(metrics.quickStats);

      const revenuePoints = revenueTrend.series.find(series => series.label === 'Revenue');
      const revenueDataPoints =
        revenuePoints?.points.filter(point => typeof point.value === 'number') ?? [];

      setRevenueSeries({
        labels: revenueDataPoints.map(point => point.label),
        values: revenueDataPoints.map(point => Number(point.value ?? 0))
      });

      const classes = popularClasses.classes ?? [];
      setClassPopularity({
        labels: classes.map(item => item.className),
        values: classes.map(item => item.bookingCount)
      });

      setScheduleSummary(scheduleOverview.summary);

      const formattedSchedules = scheduleOverview.schedules.map(schedule => ({
        id: schedule.scheduleId,
        time: formatTimeRange(schedule.startTime, schedule.endTime),
        name: schedule.className,
        instructor: schedule.instructorName || 'TBD',
        enrolled: schedule.enrolled,
        capacity: schedule.capacity
      }));
      setUpcomingClasses(formattedSchedules);

      const activities = activityFeed.events.map(event => ({
        id: event.id,
        type: event.type,
        message: event.message,
        time: formatTimestamp(event.createdAt),
        createdAt: event.createdAt
      }));
      setRecentActivities(activities);
    } catch (error) {
      console.error('Error fetching dashboard data:', error);
      setErrorMessage('We had trouble loading live data. Try refreshing or check your integrations.');

      setKpiData([]);
      setClassPopularity({ labels: [], values: [] });
      setRevenueSeries({ labels: [], values: [] });
      setScheduleSummary(null);
      setUpcomingClasses([]);
      setRecentActivities([]);
      setQuickStats({ todaysRevenue: 0, activeClasses: 0 });
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchDashboardData();
  }, [selectedPeriod, effectiveStudioId]);
  
  const revenueChartData = useMemo(() => {
    if (!revenueSeries.labels.length || !revenueSeries.values.length) {
      return null;
    }

    const labels = revenueSeries.labels;
    const values = revenueSeries.values.map(value => Number.isFinite(value) ? value : 0);

    return {
      labels,
      datasets: [
        {
          label: 'Revenue',
          data: values,
          fill: true,
          backgroundColor: 'rgba(59, 130, 246, 0.1)',
          borderColor: 'rgb(59, 130, 246)',
          tension: 0.4
        }
      ]
    };
  }, [revenueSeries]);

  useEffect(() => {
    if (!revenueChartData) {
      chartRef.current = null;
    }
  }, [revenueChartData]);

  const classPopularityData = useMemo(() => {
    if (!classPopularity.labels.length) {
      return null;
    }

    return {
      labels: classPopularity.labels,
      datasets: [
        {
          label: 'Total Bookings',
          data: classPopularity.values,
          backgroundColor: [
            'rgba(59, 130, 246, 0.8)',
            'rgba(139, 92, 246, 0.8)',
            'rgba(236, 72, 153, 0.8)',
            'rgba(34, 197, 94, 0.8)',
            'rgba(251, 146, 60, 0.8)'
          ]
        }
      ]
    };
  }, [classPopularity]);

  const occupancyRateData = useMemo(() => {
    const seatsBooked = scheduleSummary?.seatsBooked ?? 0;
    const totalSeats = scheduleSummary?.totalSeats ?? 0;

    if (totalSeats === 0) {
      return {
        labels: ['Occupied', 'Available'],
        datasets: [
          {
            data: [0, 1],
            backgroundColor: ['rgba(34, 197, 94, 0.8)', 'rgba(229, 231, 235, 0.8)'],
            borderWidth: 0
          }
        ]
      };
    }

    return {
      labels: ['Occupied', 'Available'],
      datasets: [
        {
          data: [seatsBooked, Math.max(totalSeats - seatsBooked, 0)],
          backgroundColor: ['rgba(34, 197, 94, 0.8)', 'rgba(229, 231, 235, 0.8)'],
          borderWidth: 0
        }
      ]
    };
  }, [scheduleSummary]);

  const occupancySummary = useMemo(() => {
    const percent = scheduleSummary?.occupancyPercent ?? 0;
    const seatsBooked = scheduleSummary?.seatsBooked ?? 0;
    const totalSeats = scheduleSummary?.totalSeats ?? 0;

    return {
      percent,
      seatsBooked,
      totalSeats,
      label: totalSeats > 0
        ? `${seatsBooked.toLocaleString()} of ${totalSeats.toLocaleString()} seats`
        : 'No scheduled classes'
    };
  }, [scheduleSummary]);

  const handleRefresh = () => {
    fetchDashboardData();
  };

  const handleChartClick = (event: React.MouseEvent<HTMLCanvasElement>) => {
    if (!revenueChartData) {
      return;
    }

    if (chartRef.current) {
        const chart = chartRef.current;
        const elements = chart.getElementsAtEventForMode(event.nativeEvent, 'nearest', { intersect: true }, true);
        if (elements.length > 0) {
            const element = elements[0];
            const value = Number(revenueChartData.datasets[element.datasetIndex].data[element.index]) || 0;
            const label = revenueChartData.labels[element.index];
            alert(`Revenue for ${label}: ${formatCurrency(value)}`);
        }
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Dashboard Overview</h1>
          <p className="text-gray-600 mt-1">Welcome back! Here's what's happening with your studio.</p>
        </div>
        
        <div className="flex items-center gap-3">
          <select
            value={selectedPeriod}
            onChange={(e) => setSelectedPeriod(e.target.value as DashboardPeriod)}
            className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent appearance-none bg-white pr-10 cursor-pointer"
            style={{
              backgroundImage: `url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%236b7280' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='M6 8l4 4 4-4'/%3e%3c/svg%3e")`,
              backgroundPosition: 'right 0.5rem center',
              backgroundRepeat: 'no-repeat',
              backgroundSize: '1.5em 1.5em'
            }}
          >
            <option value="today">Today</option>
            <option value="week">This Week</option>
            <option value="month">This Month</option>
            <option value="year">This Year</option>
          </select>
          
          <button
            onClick={handleRefresh}
            className={`p-2 border border-gray-300 rounded-lg hover:bg-gray-50 ${isLoading ? 'animate-spin' : ''}`}
          >
            <RefreshCw className="h-5 w-5 text-gray-600" />
          </button>
          
          <button className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors flex items-center">
            <Download className="h-4 w-4 mr-2" />
            Export Report
          </button>
        </div>
      </div>

      {!isLoading && (
        <div className="grid grid-cols-1 gap-2 text-sm text-gray-600 sm:grid-cols-2">
          <div>
            Today's Revenue:{' '}
            <span className="font-semibold text-gray-900">
              {formatCurrency(quickStats.todaysRevenue)}
            </span>
          </div>
          <div>
            Active Classes:{' '}
            <span className="font-semibold text-gray-900">
              {quickStats.activeClasses.toLocaleString()}
            </span>
          </div>
        </div>
      )}

      {errorMessage && (
        <div className="rounded-lg border border-yellow-200 bg-yellow-50 px-4 py-3 text-sm text-yellow-800">
          {errorMessage}
        </div>
      )}

      {/* KPI Cards - Redesigned for better space utilization */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {isLoading ? (
          <>
            <SkeletonCard />
            <SkeletonCard />
            <SkeletonCard />
            <SkeletonCard />
          </>
        ) : kpiData.length > 0 ? (
          kpiData.map((kpi, index) => {
            const Icon = kpi.icon;
            const colorClasses = {
              green: 'from-green-50 to-green-100 border-green-200',
              blue: 'from-blue-50 to-blue-100 border-blue-200',
              purple: 'from-purple-50 to-purple-100 border-purple-200',
              yellow: 'from-yellow-50 to-yellow-100 border-yellow-200'
            };
            const iconColors = {
              green: 'text-green-600 bg-green-100',
              blue: 'text-blue-600 bg-blue-100',
              purple: 'text-purple-600 bg-purple-100',
              yellow: 'text-yellow-600 bg-yellow-100'
            };

            return (
              <motion.div
                key={kpi.title}
                initial={{ opacity: 0, scale: 0.95 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ delay: index * 0.05 }}
                className={`relative overflow-hidden bg-gradient-to-br ${colorClasses[kpi.color as keyof typeof colorClasses]} 
                           border rounded-xl p-4 hover:shadow-lg transition-all duration-300 group`}
              >
                {/* Background Pattern */}
                <div className="absolute top-0 right-0 -mt-4 -mr-4 opacity-10">
                  <Icon className="h-24 w-24" />
                </div>

                {/* Content */}
                <div className="relative">
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <div className={`inline-flex p-2 rounded-lg ${iconColors[kpi.color as keyof typeof iconColors]} mb-2`}>
                        <Icon className="h-4 w-4" />
                      </div>
                      <h3 className="text-xs font-medium text-gray-600 uppercase tracking-wider">{kpi.title}</h3>
                      <p className="text-2xl font-bold text-gray-900 mt-1">{kpi.value}</p>
                    </div>

                    {/* Change indicator */}
                    <div
                      className={`flex items-center gap-1 px-2 py-1 rounded-full text-xs font-semibold
                        ${kpi.changeType === 'increase' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}
                    >
                      {kpi.changeType === 'increase' ? (
                        <TrendingUp className="h-3 w-3" />
                      ) : (
                        <TrendingDown className="h-3 w-3" />
                      )}
                      <span>{Math.abs(kpi.change)}%</span>
                    </div>
                  </div>

                  {/* Mini Chart or Progress Bar */}
                  <div className="mt-3 h-1 bg-gray-200 rounded-full overflow-hidden">
                    <motion.div
                      className={`h-full bg-gradient-to-r ${
                        kpi.color === 'green'
                          ? 'from-green-400 to-green-600'
                          : kpi.color === 'blue'
                            ? 'from-blue-400 to-blue-600'
                            : kpi.color === 'purple'
                              ? 'from-purple-400 to-purple-600'
                              : 'from-yellow-400 to-yellow-600'
                      }`}
                      initial={{ width: 0 }}
                      animate={{ width: `${Math.min(100, Math.abs(kpi.change) * 5)}%` }}
                      transition={{ delay: index * 0.1 + 0.3, duration: 0.5 }}
                    />
                  </div>

                  {/* Period comparison */}
                  <p className="text-xs text-gray-500 mt-2">
                    vs last {selectedPeriod === 'today' ? 'day' : selectedPeriod}
                  </p>
                </div>
              </motion.div>
            );
          })
        ) : (
          <div className="sm:col-span-2 lg:col-span-4">
            <div className="bg-white border border-dashed border-gray-200 rounded-xl">
              <EmptyState
                title="No performance data yet"
                message="Connect your integrations or refresh to see studio KPIs here."
                actionText="Refresh data"
                onAction={handleRefresh}
                icon={Target}
              />
            </div>
          </div>
        )}
      </div>

      {/* Studio Intelligence Summary */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <StudioIntelligenceSummary
          studioId={effectiveStudioId}
          className="lg:col-span-1"
        />

        {/* Quick Action Cards */}
        <div className="lg:col-span-2 grid grid-cols-1 sm:grid-cols-2 gap-4">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="bg-white shadow-lg border border-gray-200 rounded-xl p-4 hover:shadow-xl transition-all duration-300 group cursor-pointer"
            onClick={() => router.push('/dashboard/classes')}
          >
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 rounded-lg">
                <BookOpen className="h-5 w-5 text-blue-600" />
              </div>
              <div>
                <h3 className="font-semibold text-gray-900">Create Class</h3>
                <p className="text-sm text-gray-600">Add new workshop</p>
              </div>
              <ChevronRight className="h-4 w-4 text-gray-400 ml-auto group-hover:translate-x-1 transition-transform" />
            </div>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2 }}
            className="bg-white shadow-lg border border-gray-200 rounded-xl p-4 hover:shadow-xl transition-all duration-300 group cursor-pointer"
            onClick={() => window.location.href = '/dashboard/reservations'}
          >
            <div className="flex items-center gap-3">
              <div className="p-2 bg-green-100 rounded-lg">
                <Calendar className="h-5 w-5 text-green-600" />
              </div>
              <div>
                <h3 className="font-semibold text-gray-900">View Schedule</h3>
                <p className="text-sm text-gray-600">Manage bookings</p>
              </div>
              <ChevronRight className="h-4 w-4 text-gray-400 ml-auto group-hover:translate-x-1 transition-transform" />
            </div>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.3 }}
            className="bg-white shadow-lg border border-gray-200 rounded-xl p-4 hover:shadow-xl transition-all duration-300 group cursor-pointer"
            onClick={() => window.location.href = '/dashboard/students'}
          >
            <div className="flex items-center gap-3">
              <div className="p-2 bg-purple-100 rounded-lg">
                <Users className="h-5 w-5 text-purple-600" />
              </div>
              <div>
                <h3 className="font-semibold text-gray-900">Student List</h3>
                <p className="text-sm text-gray-600">Manage students</p>
              </div>
              <ChevronRight className="h-4 w-4 text-gray-400 ml-auto group-hover:translate-x-1 transition-transform" />
            </div>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.4 }}
            className="bg-white shadow-lg border border-gray-200 rounded-xl p-4 hover:shadow-xl transition-all duration-300 group cursor-pointer"
            onClick={() => window.location.href = '/dashboard/revenue'}
          >
            <div className="flex items-center gap-3">
              <div className="p-2 bg-yellow-100 rounded-lg">
                <DollarSign className="h-5 w-5 text-yellow-600" />
              </div>
              <div>
                <h3 className="font-semibold text-gray-900">Revenue Report</h3>
                <p className="text-sm text-gray-600">View earnings</p>
              </div>
              <ChevronRight className="h-4 w-4 text-gray-400 ml-auto group-hover:translate-x-1 transition-transform" />
            </div>
          </motion.div>
        </div>
      </div>

      {/* Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 overflow-hidden">
        {/* Revenue Chart */}
        <div className="lg:col-span-2 bg-white shadow-lg border border-gray-200 rounded-xl p-6">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-xl font-semibold text-gray-900">Revenue Overview</h2>
            <button 
              onClick={() => window.location.href = '/dashboard/revenue'}
              className="text-sm text-blue-600 hover:text-blue-700 font-medium transition-colors flex items-center gap-1 group"
            >
              View Details 
              <ChevronRight className="inline h-4 w-4 transition-transform group-hover:translate-x-1" />
            </button>
          </div>
          <div className="relative h-64 min-h-[16rem] max-h-[16rem] overflow-hidden">
            {revenueChartData ? (
              <Line
                ref={chart => {
                  chartRef.current = chart ?? null;
                }}
                data={revenueChartData}
                onClick={handleChartClick}
                options={{
                  responsive: true,
                  maintainAspectRatio: false,
                  plugins: {
                    legend: { display: false },
                    tooltip: {
                      callbacks: {
                        label: context => formatCurrency(Number(context.parsed.y || 0))
                      }
                    }
                  },
                  scales: {
                    y: {
                      beginAtZero: true,
                      ticks: {
                        callback: value => formatCurrency(Number(value))
                      }
                    }
                  }
                }}
              />
            ) : (
              <div className="flex h-full items-center justify-center rounded-xl border-2 border-dashed border-gray-200 bg-gray-50 px-6">
                <EmptyState
                  title="No revenue data"
                  message="We could not load revenue trends for the selected period."
                  actionText="Refresh data"
                  onAction={handleRefresh}
                  icon={Activity}
                />
              </div>
            )}
          </div>
        </div>

        {/* Occupancy Rate */}
        <div className="bg-white shadow-lg border border-gray-200 rounded-xl p-6">
          <h2 className="text-xl font-semibold text-gray-900 mb-6">Occupancy Rate</h2>
          <div className="relative h-64 min-h-[16rem] max-h-[16rem] overflow-hidden">
            <Doughnut
              data={occupancyRateData}
              options={{
                responsive: true,
                maintainAspectRatio: false,
                cutout: '70%',
                plugins: {
                  legend: { 
                    position: 'bottom',
                    labels: {
                      padding: 15,
                      font: {
                        size: 12
                      }
                    }
                  },
                  tooltip: {
                    callbacks: {
                      label: (context) => {
                        if (context.label === 'Occupied') {
                          return `${context.label}: ${occupancySummary.seatsBooked.toLocaleString()} seats`;
                        }
                        const available = Math.max(occupancySummary.totalSeats - occupancySummary.seatsBooked, 0);
                        return `${context.label}: ${available.toLocaleString()} seats`;
                      }
                    }
                  }
                }
              }}
            />
            <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
              <div className="text-center mb-8">
                <p className="text-2xl font-bold text-gray-900">{Math.round(occupancySummary.percent)}%</p>
                <p className="text-sm text-gray-600">{occupancySummary.label}</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Class Popularity & Upcoming Classes */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 overflow-hidden">
        {/* Class Popularity */}
        <div className="bg-white shadow-lg border border-gray-200 rounded-xl p-6">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-xl font-semibold text-gray-900">Popular Classes</h2>
            <span className="text-xs text-gray-500">Your studio's top performers</span>
          </div>
          <div className="relative h-64 min-h-[16rem] max-h-[16rem] overflow-hidden">
            {classPopularityData && classPopularityData.datasets[0].data.length > 0 ? (
              <Bar
                data={classPopularityData}
                options={{
                  responsive: true,
                  maintainAspectRatio: false,
                  plugins: {
                    legend: { display: false },
                    tooltip: {
                      callbacks: {
                        label: (context) => `${context.label}: ${context.parsed.y} bookings`
                      }
                    }
                  },
                  scales: {
                    y: { 
                      beginAtZero: true,
                      title: {
                        display: true,
                        text: 'Total Bookings'
                      }
                    }
                  }
                }}
              />
            ) : (
                <EmptyState 
                    title="No class data available" 
                    message="Once you have bookings, you will see your most popular classes here."
                    actionText="Create a Class"
                    onAction={() => { /* Navigate to create class page */ }}
                />
            )}
          </div>
        </div>

        {/* Upcoming Classes */}
        <div className="bg-white shadow-lg border border-gray-200 rounded-xl p-6">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-xl font-semibold text-gray-900">Today's Classes</h2>
            <span className="text-sm text-gray-500">{upcomingClasses.length} classes</span>
          </div>
          <div className="space-y-4">
            {upcomingClasses.length > 0 ? (
                upcomingClasses.map(cls => (
                  <div key={cls.id} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
                    <div className="flex-1">
                      <div className="flex items-center gap-2">
                        <Clock className="h-4 w-4 text-gray-500" />
                        <span className="text-sm text-gray-600">{cls.time}</span>
                      </div>
                      <h3 className="font-medium text-gray-900 mt-1">{cls.name}</h3>
                      <p className="text-sm text-gray-600">{cls.instructor}</p>
                    </div>
                    <div className="text-right">
                      <div className={`text-sm font-medium ${
                        cls.enrolled === cls.capacity ? 'text-red-600' : 'text-green-600'
                      }`}>
                        {cls.enrolled}/{cls.capacity}
                      </div>
                      <div className="text-xs text-gray-500">
                        {cls.enrolled === cls.capacity ? 'Full' : `${cls.capacity - cls.enrolled} spots`}
                      </div>
                    </div>
                  </div>
                ))
            ) : (
              <div className="rounded-xl border-2 border-dashed border-gray-200 bg-gray-50">
                <EmptyState
                  title="No classes on the schedule"
                  message="Add a class or enable calendar sync to see today's lineup."
                  actionText="Create a class"
                  onAction={() => {
                    // TODO: navigate to create class page
                  }}
                  icon={Calendar}
                />
              </div>
            )}
          </div>
        </div>
      </div>


      {/* Recent Activity */}
      <div className="bg-white shadow-lg border border-gray-200 rounded-xl p-6">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-xl font-semibold text-gray-900">Recent Activity</h2>
          <button className="text-sm text-blue-600 hover:text-blue-700 font-medium">
            View All <ChevronRight className="inline h-4 w-4" />
          </button>
        </div>
        <div className="space-y-3">
            {recentActivities.length > 0 ? (
                recentActivities.map(activity => (
                  <div key={activity.id} className="flex items-start gap-3 p-3 hover:bg-gray-50 rounded-lg transition-colors">
                    <div className={`p-2 rounded-lg ${
                      activity.type === 'booking' ? 'bg-blue-100 text-blue-600' :
                      activity.type === 'review' ? 'bg-yellow-100 text-yellow-600' :
                      activity.type === 'payment' ? 'bg-green-100 text-green-600' :
                      'bg-red-100 text-red-600'
                    }`}>
                      <Activity className="h-4 w-4" />
                    </div>
                    <div className="flex-1">
                      <p className="text-gray-900">{activity.message}</p>
                      <p className="text-sm text-gray-500 mt-1">{activity.time}</p>
                    </div>
                  </div>
                ))
            ) : (
                <EmptyState 
                    title="No recent activity" 
                    message="Recent bookings, reviews, and payments will appear here."
                />
            )}
        </div>
      </div>
    </div>
  );
}
