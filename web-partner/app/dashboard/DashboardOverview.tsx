'use client';

import React, { useState, useEffect } from 'react';
import { SupabaseTest } from '../../components/SupabaseTest';
import { motion } from 'framer-motion';
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

export default function DashboardOverview() {
  const [selectedPeriod, setSelectedPeriod] = useState('week');
  const [isLoading, setIsLoading] = useState(false);

  // KPI Data
  const kpiData: KPICard[] = [
    {
      title: 'Total Revenue',
      value: '$12,845',
      change: 12.5,
      changeType: 'increase',
      icon: DollarSign,
      color: 'green'
    },
    {
      title: 'Active Students',
      value: 342,
      change: 8.2,
      changeType: 'increase',
      icon: Users,
      color: 'blue'
    },
    {
      title: 'Classes This Week',
      value: 48,
      change: -2.3,
      changeType: 'decrease',
      icon: Calendar,
      color: 'purple'
    },
    {
      title: 'Average Rating',
      value: '4.8',
      change: 0.3,
      changeType: 'increase',
      icon: Star,
      color: 'yellow'
    }
  ];

  // Revenue Chart Data
  const revenueChartData = {
    labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    datasets: [
      {
        label: 'Revenue',
        data: [1200, 1900, 1500, 2100, 2300, 2800, 2400],
        fill: true,
        backgroundColor: 'rgba(59, 130, 246, 0.1)',
        borderColor: 'rgb(59, 130, 246)',
        tension: 0.4
      }
    ]
  };

  // Class Popularity Data
  const classPopularityData = {
    labels: ['Yoga', 'Pilates', 'Dance', 'Meditation', 'Fitness'],
    datasets: [
      {
        label: 'Bookings',
        data: [65, 45, 38, 28, 22],
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

  // Occupancy Rate Data
  const occupancyRateData = {
    labels: ['Occupied', 'Available'],
    datasets: [
      {
        data: [73, 27],
        backgroundColor: ['rgba(34, 197, 94, 0.8)', 'rgba(229, 231, 235, 0.8)'],
        borderWidth: 0
      }
    ]
  };

  // Upcoming Classes
  const upcomingClasses = [
    { id: 1, name: 'Morning Yoga Flow', time: '9:00 AM', enrolled: 12, capacity: 15, instructor: 'Sarah Johnson' },
    { id: 2, name: 'Advanced Pilates', time: '10:30 AM', enrolled: 8, capacity: 10, instructor: 'Mike Chen' },
    { id: 3, name: 'Contemporary Dance', time: '2:00 PM', enrolled: 15, capacity: 20, instructor: 'Emily Davis' },
    { id: 4, name: 'Meditation & Mindfulness', time: '4:00 PM', enrolled: 18, capacity: 18, instructor: 'David Kim' }
  ];

  // Recent Activities
  const recentActivities = [
    { id: 1, type: 'booking', message: 'New booking for Yoga Class by Jane Smith', time: '10 minutes ago' },
    { id: 2, type: 'review', message: '5-star review from Michael Brown', time: '1 hour ago' },
    { id: 3, type: 'payment', message: 'Payment received: $150 from Alex Johnson', time: '2 hours ago' },
    { id: 4, type: 'cancellation', message: 'Cancellation: Dance Class by Emma Wilson', time: '3 hours ago' }
  ];

  const handleRefresh = () => {
    setIsLoading(true);
    setTimeout(() => setIsLoading(false), 1000);
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Dashboard Overview</h1>
          <p className="text-gray-600 mt-1">Welcome back! Here\'s what\'s happening with your studio.</p>
        </div>
        
        <div className="flex items-center gap-3">
          <select
            value={selectedPeriod}
            onChange={(e) => setSelectedPeriod(e.target.value)}
            className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
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

      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
        {kpiData.map((kpi, index) => {
          const Icon = kpi.icon;
          const colorClasses = {
            green: 'bg-green-100 text-green-600',
            blue: 'bg-blue-100 text-blue-600',
            purple: 'bg-purple-100 text-purple-600',
            yellow: 'bg-yellow-100 text-yellow-600'
          };
          
          return (
            <motion.div
              key={kpi.title}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.1 }}
              className="bg-white rounded-xl shadow-sm border p-6 hover:shadow-md transition-shadow"
            >
              <div className="flex items-center justify-between mb-4">
                <div className={`p-3 rounded-lg ${colorClasses[kpi.color as keyof typeof colorClasses]}`}>
                  <Icon className="h-6 w-6" />
                </div>
                <div className={`flex items-center text-sm font-medium ${
                  kpi.changeType === 'increase' ? 'text-green-600' : 'text-red-600'
                }`}>
                  {kpi.changeType === 'increase' ? <TrendingUp className="h-4 w-4 mr-1" /> : <TrendingDown className="h-4 w-4 mr-1" />}
                  {Math.abs(kpi.change)}%
                </div>
              </div>
              <h3 className="text-gray-600 text-sm font-medium">{kpi.title}</h3>
              <p className="text-2xl font-bold text-gray-900 mt-1">{kpi.value}</p>
            </motion.div>
          );
        })}
      </div>

      {/* Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Revenue Chart */}
        <div className="lg:col-span-2 bg-white rounded-xl shadow-sm border p-6">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-lg font-semibold text-gray-900">Revenue Overview</h2>
            <button className="text-sm text-blue-600 hover:text-blue-700 font-medium">
              View Details <ChevronRight className="inline h-4 w-4" />
            </button>
          </div>
          <Line
            data={revenueChartData}
            options={{
              responsive: true,
              maintainAspectRatio: false,
              plugins: {
                legend: { display: false },
                tooltip: {
                  callbacks: {
                    label: (context) => `$${context.parsed.y}`
                  }
                }
              },
              scales: {
                y: {
                  beginAtZero: true,
                  ticks: {
                    callback: (value) => `$${value}`
                  }
                }
              }
            }}
            height={250}
          />
        </div>

        {/* Occupancy Rate */}
        <div className="bg-white rounded-xl shadow-sm border p-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-6">Occupancy Rate</h2>
          <div className="relative">
            <Doughnut
              data={occupancyRateData}
              options={{
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                  legend: { position: 'bottom' },
                  tooltip: {
                    callbacks: {
                      label: (context) => `${context.label}: ${context.parsed}%`
                    }
                  }
                }
              }}
              height={200}
            />
            <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
              <div className="text-center">
                <p className="text-3xl font-bold text-gray-900">73%</p>
                <p className="text-sm text-gray-600">Occupied</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Class Popularity & Upcoming Classes */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Class Popularity */}
        <div className="bg-white rounded-xl shadow-sm border p-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-6">Popular Classes</h2>
          <Bar
            data={classPopularityData}
            options={{
              responsive: true,
              maintainAspectRatio: false,
              plugins: {
                legend: { display: false }
              },
              scales: {
                y: { beginAtZero: true }
              }
            }}
            height={250}
          />
        </div>

        {/* Upcoming Classes */}
        <div className="bg-white rounded-xl shadow-sm border p-6">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-lg font-semibold text-gray-900">Today\'s Classes</h2>
            <span className="text-sm text-gray-500">{upcomingClasses.length} classes</span>
          </div>
          <div className="space-y-4">
            {upcomingClasses.map(cls => (
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
            ))}
          </div>
        </div>
      </div>

      {/* Supabase Connection Test */}
      <div className="mb-8">
        <SupabaseTest />
      </div>

      {/* Recent Activity */}
      <div className="bg-white rounded-xl shadow-sm border p-6">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-lg font-semibold text-gray-900">Recent Activity</h2>
          <button className="text-sm text-blue-600 hover:text-blue-700 font-medium">
            View All <ChevronRight className="inline h-4 w-4" />
          </button>
        </div>
        <div className="space-y-3">
          {recentActivities.map(activity => (
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
          ))}
        </div>
      </div>
    </div>
  );
}