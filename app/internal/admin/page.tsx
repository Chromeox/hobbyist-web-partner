/**
 * Platform Overview Dashboard
 *
 * Admin landing page with platform-wide metrics:
 * - Total revenue across all studios
 * - Total bookings
 * - Active studios/instructors
 * - Pending approvals
 * - Top performers
 * - Revenue trends
 */

'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import {
  TrendingUp,
  TrendingDown,
  Building2,
  Users,
  DollarSign,
  Calendar,
  AlertCircle,
  CheckCircle,
  Clock,
  CreditCard,
} from 'lucide-react';

interface PlatformMetrics {
  revenue: {
    total: number;
    change: number;
    platformCommission: number;
  };
  bookings: {
    total: number;
    change: number;
    completed: number;
    upcoming: number;
  };
  studios: {
    total: number;
    active: number;
    pending: number;
  };
  instructors: {
    total: number;
    active: number;
    pending: number;
  };
  pendingApprovals: number;
}

interface MetricCardProps {
  title: string;
  value: string | number;
  change?: number;
  icon: React.ElementType;
  subtitle?: string;
  trend?: 'up' | 'down';
  color?: string;
}

function MetricCard({ title, value, change, icon: Icon, subtitle, trend, color = 'blue' }: MetricCardProps) {
  const colorClasses = {
    blue: 'bg-blue-50 text-blue-600',
    green: 'bg-green-50 text-green-600',
    purple: 'bg-purple-50 text-purple-600',
    orange: 'bg-orange-50 text-orange-600',
    red: 'bg-red-50 text-red-600',
  };

  return (
    <div className="bg-white rounded-lg shadow p-6">
      <div className="flex items-center justify-between mb-4">
        <div className={`p-3 rounded-lg ${colorClasses[color as keyof typeof colorClasses] || colorClasses.blue}`}>
          <Icon className="h-6 w-6" />
        </div>
        {change !== undefined && (
          <div className={`flex items-center text-sm font-medium ${change >= 0 ? 'text-green-600' : 'text-red-600'}`}>
            {change >= 0 ? <TrendingUp className="h-4 w-4 mr-1" /> : <TrendingDown className="h-4 w-4 mr-1" />}
            {Math.abs(change)}%
          </div>
        )}
      </div>
      <div>
        <p className="text-sm font-medium text-gray-600">{title}</p>
        <p className="text-2xl font-bold text-gray-900 mt-1">{value}</p>
        {subtitle && <p className="text-sm text-gray-500 mt-1">{subtitle}</p>}
      </div>
    </div>
  );
}

export default function AdminDashboard() {
  const [metrics, setMetrics] = useState<PlatformMetrics | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadMetrics();
  }, []);

  const loadMetrics = async () => {
    try {
      setIsLoading(true);
      setError(null);

      const response = await fetch('/api/internal/admin/metrics');

      if (!response.ok) {
        throw new Error('Failed to load platform metrics');
      }

      const data = await response.json();
      setMetrics(data);
    } catch (err: any) {
      console.error('Error loading metrics:', err);
      setError(err.message);
    } finally {
      setIsLoading(false);
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-red-50 border border-red-200 rounded-lg p-4">
        <div className="flex items-center">
          <AlertCircle className="h-5 w-5 text-red-600 mr-2" />
          <p className="text-red-800">{error}</p>
        </div>
      </div>
    );
  }

  if (!metrics) {
    return <div>No data available</div>;
  }

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Platform Overview</h1>
        <p className="text-gray-600 mt-1">Monitor platform-wide performance and metrics</p>
      </div>

      {/* Quick Actions */}
      {metrics.pendingApprovals > 0 && (
        <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center">
              <Clock className="h-5 w-5 text-yellow-600 mr-2" />
              <p className="text-yellow-800 font-medium">
                {metrics.pendingApprovals} pending approval{metrics.pendingApprovals !== 1 ? 's' : ''}
              </p>
            </div>
            <div className="flex space-x-2">
              <Link
                href="/internal/admin/studios/pending"
                className="px-4 py-2 bg-yellow-600 text-white rounded-lg hover:bg-yellow-700 text-sm font-medium"
              >
                Review Studios
              </Link>
              <Link
                href="/internal/admin/instructors/pending"
                className="px-4 py-2 bg-yellow-600 text-white rounded-lg hover:bg-yellow-700 text-sm font-medium"
              >
                Review Instructors
              </Link>
            </div>
          </div>
        </div>
      )}

      {/* Main Metrics Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <MetricCard
          title="Total Revenue"
          value={`$${metrics.revenue.total.toLocaleString()}`}
          change={metrics.revenue.change}
          icon={DollarSign}
          subtitle={`Platform: $${metrics.revenue.platformCommission.toLocaleString()}`}
          color="green"
        />

        <MetricCard
          title="Total Bookings"
          value={metrics.bookings.total.toLocaleString()}
          change={metrics.bookings.change}
          icon={Calendar}
          subtitle={`${metrics.bookings.completed} completed, ${metrics.bookings.upcoming} upcoming`}
          color="blue"
        />

        <MetricCard
          title="Studios"
          value={metrics.studios.active}
          icon={Building2}
          subtitle={`${metrics.studios.pending} pending approval`}
          color="purple"
        />

        <MetricCard
          title="Instructors"
          value={metrics.instructors.active}
          icon={Users}
          subtitle={`${metrics.instructors.pending} pending approval`}
          color="orange"
        />
      </div>

      {/* Additional Sections */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Quick Links */}
        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Quick Actions</h2>
          <div className="space-y-2">
            <Link
              href="/internal/admin/studios"
              className="flex items-center justify-between p-3 rounded-lg hover:bg-gray-50 transition-colors"
            >
              <div className="flex items-center">
                <Building2 className="h-5 w-5 text-gray-400 mr-3" />
                <span className="text-gray-700">Manage Studios</span>
              </div>
              <span className="text-gray-400">→</span>
            </Link>

            <Link
              href="/internal/admin/instructors"
              className="flex items-center justify-between p-3 rounded-lg hover:bg-gray-50 transition-colors"
            >
              <div className="flex items-center">
                <Users className="h-5 w-5 text-gray-400 mr-3" />
                <span className="text-gray-700">Manage Instructors</span>
              </div>
              <span className="text-gray-400">→</span>
            </Link>

            <Link
              href="/internal/admin/payouts"
              className="flex items-center justify-between p-3 rounded-lg hover:bg-gray-50 transition-colors"
            >
              <div className="flex items-center">
                <DollarSign className="h-5 w-5 text-gray-400 mr-3" />
                <span className="text-gray-700">Process Payouts</span>
              </div>
              <span className="text-gray-400">→</span>
            </Link>

            <Link
              href="/internal/admin/revenue"
              className="flex items-center justify-between p-3 rounded-lg hover:bg-gray-50 transition-colors"
            >
              <div className="flex items-center">
                <TrendingUp className="h-5 w-5 text-gray-400 mr-3" />
                <span className="text-gray-700">Revenue Analytics</span>
              </div>
              <span className="text-gray-400">→</span>
            </Link>

            <Link
              href="/internal/admin/stripe"
              className="flex items-center justify-between p-3 rounded-lg hover:bg-gray-50 transition-colors"
            >
              <div className="flex items-center">
                <CreditCard className="h-5 w-5 text-gray-400 mr-3" />
                <span className="text-gray-700">Stripe Connect</span>
              </div>
              <span className="text-gray-400">→</span>
            </Link>
          </div>
        </div>

        {/* Recent Activity Placeholder */}
        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Platform Status</h2>
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <span className="text-gray-600">Active Studios</span>
              <span className="font-semibold text-gray-900">{metrics.studios.active}</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-gray-600">Active Instructors</span>
              <span className="font-semibold text-gray-900">{metrics.instructors.active}</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-gray-600">Completed Bookings</span>
              <span className="font-semibold text-gray-900">{metrics.bookings.completed}</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-gray-600">Platform Commission</span>
              <span className="font-semibold text-green-600">${metrics.revenue.platformCommission.toLocaleString()}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
