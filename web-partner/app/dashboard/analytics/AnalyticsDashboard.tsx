'use client';

import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import {
  TrendingUp,
  TrendingDown,
  Users,
  Calendar,
  DollarSign,
  Star,
  Activity,
  Target,
  Download,
  RefreshCw,
  Filter,
  ChevronRight,
  ArrowUp,
  ArrowDown,
  Clock,
  BookOpen,
  CreditCard,
  UserCheck,
  BarChart3,
  PieChart,
  LineChart,
  Coins
} from 'lucide-react';
import { Line, Bar, Doughnut, Radar } from 'react-chartjs-2';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  RadialLinearScale,
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
  RadialLinearScale,
  Title,
  Tooltip,
  Legend,
  Filler
);

export default function AnalyticsDashboard() {
  const [selectedPeriod, setSelectedPeriod] = useState('month');
  const [isLoading, setIsLoading] = useState(false);
  const [showComparison, setShowComparison] = useState(true);

  // Simulate loading
  useEffect(() => {
    setIsLoading(true);
    setTimeout(() => setIsLoading(false), 800);
  }, [selectedPeriod]);

  // Skeleton loader for charts
  const ChartSkeleton = () => (
    <div className="animate-pulse">
      <div className="h-64 bg-gray-200 rounded-lg"></div>
    </div>
  );

  // Metric card skeleton
  const MetricSkeleton = () => (
    <div className="animate-pulse">
      <div className="h-6 bg-gray-200 rounded w-1/2 mb-2"></div>
      <div className="h-8 bg-gray-200 rounded w-3/4"></div>
    </div>
  );

  // Key metrics data
  const metrics = [
    {
      title: 'Credits Sold',
      value: '1,842',
      change: 15.3,
      changeType: 'increase',
      comparison: '1,598',
      icon: CreditCard,
      color: 'green'
    },
    {
      title: 'Credits Used',
      value: '1,563',
      change: 12.8,
      changeType: 'increase',
      comparison: '1,385',
      icon: Coins,
      color: 'blue'
    },
    {
      title: 'Avg Credits/Student',
      value: '8.4',
      change: 5.2,
      changeType: 'increase',
      comparison: '7.9',
      icon: UserCheck,
      color: 'purple'
    },
    {
      title: 'Credit Revenue',
      value: '$9,210',
      change: 18.7,
      changeType: 'increase',
      comparison: '$7,750',
      icon: DollarSign,
      color: 'yellow'
    }
  ];

  // Credit usage trend data
  const creditTrendData = {
    labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug'],
    datasets: [
      {
        label: 'Credits Purchased',
        data: [180, 195, 210, 240, 265, 285, 310, 342],
        borderColor: 'rgb(34, 197, 94)',
        backgroundColor: 'rgba(34, 197, 94, 0.1)',
        tension: 0.4,
        fill: true
      },
      {
        label: 'Credits Used',
        data: [165, 178, 192, 215, 235, 258, 275, 298],
        borderColor: 'rgb(59, 130, 246)',
        backgroundColor: 'rgba(59, 130, 246, 0.1)',
        tension: 0.4,
        fill: true,
        borderDash: [5, 5]
      }
    ]
  };

  // Class popularity data
  const classPopularityData = {
    labels: ['Yoga', 'Pilates', 'Spin', 'HIIT', 'Dance', 'Boxing'],
    datasets: [{
      label: 'Students',
      data: [120, 95, 85, 75, 60, 45],
      backgroundColor: [
        'rgba(59, 130, 246, 0.8)',
        'rgba(168, 85, 247, 0.8)',
        'rgba(34, 197, 94, 0.8)',
        'rgba(251, 146, 60, 0.8)',
        'rgba(239, 68, 68, 0.8)',
        'rgba(107, 114, 128, 0.8)'
      ]
    }]
  };

  // Peak hours data
  const peakHoursData = {
    labels: ['6AM', '7AM', '8AM', '9AM', '10AM', '11AM', '12PM', '1PM', '2PM', '3PM', '4PM', '5PM', '6PM', '7PM', '8PM'],
    datasets: [{
      label: 'Attendance',
      data: [15, 25, 45, 65, 55, 35, 40, 30, 25, 35, 45, 70, 85, 75, 40],
      backgroundColor: 'rgba(59, 130, 246, 0.6)',
      borderColor: 'rgb(59, 130, 246)',
      borderWidth: 2
    }]
  };

  // Student retention data
  const retentionData = {
    labels: ['0-1 month', '1-3 months', '3-6 months', '6-12 months', '12+ months'],
    datasets: [{
      label: 'Students',
      data: [45, 78, 125, 89, 105],
      backgroundColor: [
        'rgba(239, 68, 68, 0.8)',
        'rgba(251, 146, 60, 0.8)',
        'rgba(251, 191, 36, 0.8)',
        'rgba(34, 197, 94, 0.8)',
        'rgba(59, 130, 246, 0.8)'
      ]
    }]
  };

  // Performance radar data
  const performanceData = {
    labels: ['Revenue', 'Growth', 'Retention', 'Satisfaction', 'Utilization', 'Efficiency'],
    datasets: [{
      label: 'Current',
      data: [85, 78, 82, 92, 75, 88],
      backgroundColor: 'rgba(59, 130, 246, 0.2)',
      borderColor: 'rgb(59, 130, 246)',
      pointBackgroundColor: 'rgb(59, 130, 246)'
    },
    {
      label: 'Target',
      data: [90, 85, 85, 95, 80, 90],
      backgroundColor: 'rgba(156, 163, 175, 0.1)',
      borderColor: 'rgb(156, 163, 175)',
      pointBackgroundColor: 'rgb(156, 163, 175)',
      borderDash: [5, 5]
    }]
  };

  return (
    <div className="space-y-6">
      {/* Header with Controls */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Analytics Dashboard</h1>
          <p className="text-base text-gray-600 mt-1">
            Track performance and insights for your studio
          </p>
        </div>
        <div className="flex gap-3">
          <select
            value={selectedPeriod}
            onChange={(e) => setSelectedPeriod(e.target.value)}
            className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 text-sm bg-white text-gray-900 font-medium appearance-none pr-10 cursor-pointer"
            style={{
              backgroundImage: `url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%236b7280' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='M6 8l4 4 4-4'/%3e%3c/svg%3e")`,
              backgroundPosition: 'right 0.5rem center',
              backgroundRepeat: 'no-repeat',
              backgroundSize: '1.5em 1.5em'
            }}
          >
            <option value="week">This Week</option>
            <option value="month">This Month</option>
            <option value="quarter">This Quarter</option>
            <option value="year">This Year</option>
          </select>
          <button className="px-4 py-2 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors flex items-center gap-2 text-sm">
            <RefreshCw className="h-4 w-4" />
            Refresh
          </button>
          <button className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors flex items-center gap-2 text-sm">
            <Download className="h-4 w-4" />
            Export Report
          </button>
        </div>
      </div>

      {/* Key Metrics */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {metrics.map((metric, index) => {
          const Icon = metric.icon;
          const colorClasses = {
            green: 'bg-green-100 text-green-600',
            blue: 'bg-blue-100 text-blue-600',
            purple: 'bg-purple-100 text-purple-600',
            yellow: 'bg-yellow-100 text-yellow-600'
          };
          
          return (
            <motion.div
              key={metric.title}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.1 }}
              className="bg-white rounded-xl border p-5 hover:shadow-md transition-all duration-200 cursor-pointer"
            >
              {isLoading ? (
                <MetricSkeleton />
              ) : (
                <>
                  <div className="flex items-center justify-between mb-4">
                    <div className={`p-2.5 rounded-lg ${colorClasses[metric.color as keyof typeof colorClasses]}`}>
                      <Icon className="h-5 w-5" />
                    </div>
                    <div className={`flex items-center text-sm font-medium ${
                      metric.changeType === 'increase' ? 'text-green-600' : 'text-red-600'
                    }`}>
                      {metric.changeType === 'increase' ? <ArrowUp className="h-3 w-3 mr-1" /> : <ArrowDown className="h-3 w-3 mr-1" />}
                      {Math.abs(metric.change)}%
                    </div>
                  </div>
                  <h3 className="text-sm font-medium text-gray-600">{metric.title}</h3>
                  <div className="flex items-baseline justify-between mt-1">
                    <p className="text-2xl font-bold text-gray-900">{metric.value}</p>
                    {showComparison && (
                      <p className="text-sm text-gray-500">vs {metric.comparison}</p>
                    )}
                  </div>
                </>
              )}
            </motion.div>
          );
        })}
      </div>

      {/* Charts Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Revenue Trend */}
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ delay: 0.2 }}
          className="bg-white rounded-xl border p-6"
        >
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-xl font-semibold text-gray-900">Credit Usage Trends</h2>
            <button className="text-sm text-blue-600 hover:text-blue-700 font-medium flex items-center">
              Details <ChevronRight className="h-4 w-4 ml-1" />
            </button>
          </div>
          {isLoading ? (
            <ChartSkeleton />
          ) : (
            <div className="h-64">
              <Line
                data={creditTrendData}
                options={{
                  responsive: true,
                  maintainAspectRatio: false,
                  plugins: {
                    legend: {
                      position: 'bottom',
                      labels: {
                        padding: 15,
                        font: { size: 12 }
                      }
                    },
                    tooltip: {
                      callbacks: {
                        label: (context) => `${context.dataset.label}: ${context.parsed.y.toLocaleString()} credits`
                      }
                    }
                  },
                  scales: {
                    y: {
                      beginAtZero: true,
                      ticks: {
                        callback: (value) => `$${(value as number / 1000).toFixed(0)}k`
                      }
                    }
                  }
                }}
              />
            </div>
          )}
        </motion.div>

        {/* Class Popularity */}
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ delay: 0.3 }}
          className="bg-white rounded-xl border p-6"
        >
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-xl font-semibold text-gray-900">Class Popularity</h2>
            <button className="text-sm text-blue-600 hover:text-blue-700 font-medium flex items-center">
              Details <ChevronRight className="h-4 w-4 ml-1" />
            </button>
          </div>
          {isLoading ? (
            <ChartSkeleton />
          ) : (
            <div className="h-64">
              <Bar
                data={classPopularityData}
                options={{
                  responsive: true,
                  maintainAspectRatio: false,
                  plugins: {
                    legend: { display: false },
                    tooltip: {
                      callbacks: {
                        label: (context) => `${context.parsed.y} students`
                      }
                    }
                  },
                  scales: {
                    y: { beginAtZero: true }
                  }
                }}
              />
            </div>
          )}
        </motion.div>

        {/* Peak Hours */}
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ delay: 0.4 }}
          className="bg-white rounded-xl border p-6"
        >
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-xl font-semibold text-gray-900">Peak Hours</h2>
            <span className="text-sm text-gray-500">Today</span>
          </div>
          {isLoading ? (
            <ChartSkeleton />
          ) : (
            <div className="h-64">
              <Bar
                data={peakHoursData}
                options={{
                  responsive: true,
                  maintainAspectRatio: false,
                  plugins: {
                    legend: { display: false },
                    tooltip: {
                      callbacks: {
                        label: (context) => `${context.parsed.y} students`
                      }
                    }
                  },
                  scales: {
                    y: { beginAtZero: true }
                  }
                }}
              />
            </div>
          )}
        </motion.div>

        {/* Student Retention */}
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ delay: 0.5 }}
          className="bg-white rounded-xl border p-6"
        >
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-xl font-semibold text-gray-900">Student Retention</h2>
            <span className="text-sm text-gray-500">By duration</span>
          </div>
          {isLoading ? (
            <ChartSkeleton />
          ) : (
            <div className="h-64 flex items-center justify-center">
              <div className="w-56">
                <Doughnut
                  data={retentionData}
                  options={{
                    responsive: true,
                    maintainAspectRatio: true,
                    cutout: '60%',
                    plugins: {
                      legend: {
                        position: 'right',
                        labels: {
                          padding: 10,
                          font: { size: 11 }
                        }
                      }
                    }
                  }}
                />
              </div>
            </div>
          )}
        </motion.div>
      </div>

      {/* Performance Overview */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.6 }}
        className="bg-white rounded-xl border p-6"
      >
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-xl font-semibold text-gray-900">Performance Overview</h2>
          <div className="flex items-center gap-4">
            <label className="flex items-center gap-2 text-sm">
              <input
                type="checkbox"
                checked={showComparison}
                onChange={(e) => setShowComparison(e.target.checked)}
                className="rounded"
              />
              Show targets
            </label>
          </div>
        </div>
        {isLoading ? (
          <ChartSkeleton />
        ) : (
          <div className="h-80 flex items-center justify-center">
            <div className="w-full max-w-md">
              <Radar
                data={performanceData}
                options={{
                  responsive: true,
                  maintainAspectRatio: true,
                  plugins: {
                    legend: {
                      position: 'bottom',
                      labels: {
                        padding: 25,
                        font: { size: 11 },
                        boxWidth: 15,
                        boxHeight: 15
                      }
                    }
                  },
                  scales: {
                    r: {
                      beginAtZero: true,
                      max: 100,
                      ticks: {
                        stepSize: 20
                      }
                    }
                  }
                }}
              />
            </div>
          </div>
        )}
      </motion.div>

      {/* Quick Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-gradient-to-r from-blue-500 to-blue-600 rounded-xl p-5 text-white">
          <div className="flex items-center justify-between mb-3">
            <Target className="h-8 w-8 opacity-80" />
            <span className="text-2xl font-bold">92%</span>
          </div>
          <p className="text-sm opacity-90">Goal Achievement</p>
        </div>
        <div className="bg-gradient-to-r from-purple-500 to-purple-600 rounded-xl p-5 text-white">
          <div className="flex items-center justify-between mb-3">
            <Activity className="h-8 w-8 opacity-80" />
            <span className="text-2xl font-bold">1.8k</span>
          </div>
          <p className="text-sm opacity-90">Monthly Sessions</p>
        </div>
        <div className="bg-gradient-to-r from-green-500 to-green-600 rounded-xl p-5 text-white">
          <div className="flex items-center justify-between mb-3">
            <TrendingUp className="h-8 w-8 opacity-80" />
            <span className="text-2xl font-bold">24%</span>
          </div>
          <p className="text-sm opacity-90">Growth Rate</p>
        </div>
        <div className="bg-gradient-to-r from-orange-500 to-orange-600 rounded-xl p-5 text-white">
          <div className="flex items-center justify-between mb-3">
            <Clock className="h-8 w-8 opacity-80" />
            <span className="text-2xl font-bold">45min</span>
          </div>
          <p className="text-sm opacity-90">Avg. Class Duration</p>
        </div>
      </div>
    </div>
  );
}
