'use client';

import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { 
  DollarSign, 
  TrendingUp, 
  CreditCard, 
  Package, 
  Calendar,
  Download,
  RefreshCw,
  BarChart3,
  PieChart,
  Users,
  Eye
} from 'lucide-react';

interface RevenueMetrics {
  total_revenue_cents: number;
  total_commission_cents: number;
  total_instructor_payouts_cents: number;
  total_bookings: number;
  credit_pack_sales: number;
  credit_bookings: number;
  card_bookings: number;
  period_start: string;
  period_end: string;
  total_revenue_formatted: string;
  total_commission_formatted: string;
  credit_pack_revenue_formatted: string;
  commission_rate: string;
  period_days: number;
}

interface BookingTrend {
  date: string;
  total_bookings: number;
  card_bookings: number;
  credit_bookings: number;
  total_revenue_cents: number;
  total_revenue_formatted: string;
}

export default function RevenueReporting() {
  const [activeTab, setActiveTab] = useState('overview');
  const [timeRange, setTimeRange] = useState('30');
  const [metrics, setMetrics] = useState<RevenueMetrics | null>(null);
  const [bookingTrends, setBookingTrends] = useState<BookingTrend[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  useEffect(() => {
    loadRevenueData();
  }, [timeRange]);

  const loadRevenueData = async () => {
    setLoading(true);
    try {
      // Mock data - in real implementation would call Supabase functions
      const mockMetrics: RevenueMetrics = {
        total_revenue_cents: 15750,
        total_commission_cents: 2363,
        total_instructor_payouts_cents: 13387,
        total_bookings: 45,
        credit_pack_sales: 28,
        credit_bookings: 32,
        card_bookings: 13,
        period_start: new Date(Date.now() - parseInt(timeRange) * 24 * 60 * 60 * 1000).toISOString(),
        period_end: new Date().toISOString(),
        total_revenue_formatted: '157.50',
        total_commission_formatted: '23.63',
        credit_pack_revenue_formatted: '1400.00',
        commission_rate: '15.0%',
        period_days: parseInt(timeRange)
      };

      const mockTrends: BookingTrend[] = Array.from({ length: Math.min(parseInt(timeRange), 14) }, (_, i) => {
        const date = new Date(Date.now() - (parseInt(timeRange) - 1 - i) * 24 * 60 * 60 * 1000);
        const totalBookings = Math.floor(Math.random() * 5) + 1;
        const creditBookings = Math.floor(totalBookings * 0.7);
        const cardBookings = totalBookings - creditBookings;
        const revenue = totalBookings * (Math.random() * 30 + 20) * 100;
        
        return {
          date: date.toISOString().split('T')[0],
          total_bookings: totalBookings,
          card_bookings: cardBookings,
          credit_bookings: creditBookings,
          total_revenue_cents: Math.floor(revenue),
          total_revenue_formatted: (revenue / 100).toFixed(2)
        };
      });

      setMetrics(mockMetrics);
      setBookingTrends(mockTrends);
    } catch (error) {
      console.error('Error loading revenue data:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleRefresh = async () => {
    setRefreshing(true);
    await loadRevenueData();
    setRefreshing(false);
  };

  const tabs = [
    { id: 'overview', label: 'Revenue Overview', icon: DollarSign },
    { id: 'trends', label: 'Booking Trends', icon: TrendingUp },
    { id: 'commission', label: 'Commission Details', icon: BarChart3 },
  ];

  if (loading && !metrics) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Revenue Reporting</h1>
          <p className="text-gray-600">Track earnings, commissions, and booking trends</p>
        </div>
        <div className="flex items-center space-x-3">
          <select
            value={timeRange}
            onChange={(e) => setTimeRange(e.target.value)}
            className="px-3 py-2 border border-gray-300 rounded-md text-sm appearance-none bg-white pr-10 cursor-pointer"
            style={{
              backgroundImage: `url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%236b7280' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='M6 8l4 4 4-4'/%3e%3c/svg%3e")`,
              backgroundPosition: 'right 0.5rem center',
              backgroundRepeat: 'no-repeat',
              backgroundSize: '1.5em 1.5em'
            }}
          >
            <option value="7">Last 7 days</option>
            <option value="30">Last 30 days</option>
            <option value="90">Last 90 days</option>
            <option value="365">Last year</option>
          </select>
          <button
            onClick={handleRefresh}
            disabled={refreshing}
            className="px-3 py-2 bg-blue-600 text-white rounded-md text-sm flex items-center space-x-2 hover:bg-blue-700 disabled:opacity-50"
          >
            <RefreshCw className={`h-4 w-4 ${refreshing ? 'animate-spin' : ''}`} />
            <span>Refresh</span>
          </button>
        </div>
      </div>

      {/* Navigation Tabs */}
      <div className="border-b border-gray-200">
        <nav className="-mb-px flex space-x-8">
          {tabs.map((tab) => {
            const IconComponent = tab.icon;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`whitespace-nowrap pb-4 px-1 border-b-2 font-medium text-sm flex items-center space-x-2 ${
                  activeTab === tab.id
                    ? 'border-blue-500 text-blue-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                <IconComponent className="h-4 w-4" />
                <span>{tab.label}</span>
              </button>
            );
          })}
        </nav>
      </div>

      {/* Tab Content */}
      <motion.div
        key={activeTab}
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.3 }}
      >
        {activeTab === 'overview' && (
          <RevenueOverview metrics={metrics} />
        )}
        {activeTab === 'trends' && (
          <BookingTrendsView trends={bookingTrends} />
        )}
        {activeTab === 'commission' && (
          <CommissionDetails metrics={metrics} />
        )}
      </motion.div>
    </div>
  );
}

function RevenueOverview({ metrics }: { metrics: RevenueMetrics | null }) {
  if (!metrics) return null;

  const kpis = [
    {
      label: 'Total Revenue',
      value: `$${metrics.total_revenue_formatted}`,
      icon: DollarSign,
      color: 'blue',
      change: '+12.5%',
      changeType: 'positive'
    },
    {
      label: 'Platform Commission',
      value: `$${metrics.total_commission_formatted}`,
      icon: BarChart3,
      color: 'green',
      change: '+12.5%',
      changeType: 'positive'
    },
    {
      label: 'Instructor Payouts',
      value: `$${(metrics.total_instructor_payouts_cents / 100).toFixed(2)}`,
      icon: Users,
      color: 'purple',
      change: '+12.5%',
      changeType: 'positive'
    },
    {
      label: 'Total Bookings',
      value: metrics.total_bookings.toString(),
      icon: Calendar,
      color: 'orange',
      change: '+8.3%',
      changeType: 'positive'
    }
  ];

  return (
    <div className="space-y-6">
      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {kpis.map((kpi, index) => {
          const IconComponent = kpi.icon;
          const colorClasses = {
            blue: 'bg-blue-100 text-blue-600',
            green: 'bg-green-100 text-green-600',
            purple: 'bg-purple-100 text-purple-600',
            orange: 'bg-orange-100 text-orange-600'
          };
          
          return (
            <motion.div
              key={kpi.label}
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ delay: index * 0.1 }}
              className="bg-white p-6 rounded-xl shadow-sm border border-gray-200"
            >
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">{kpi.label}</p>
                  <p className="text-2xl font-bold text-gray-900 mt-1">{kpi.value}</p>
                  <p className={`text-sm mt-1 ${
                    kpi.changeType === 'positive' ? 'text-green-600' : 'text-red-600'
                  }`}>
                    {kpi.change} from last period
                  </p>
                </div>
                <div className={`p-3 rounded-lg ${colorClasses[kpi.color as keyof typeof colorClasses]}`}>
                  <IconComponent className="h-6 w-6" />
                </div>
              </div>
            </motion.div>
          );
        })}
      </div>

      {/* Payment Method Breakdown */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white rounded-xl shadow-sm border border-gray-200">
          <div className="p-6 border-b border-gray-200">
            <h3 className="text-xl font-semibold text-gray-900">Payment Methods</h3>
          </div>
          <div className="p-6">
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-3">
                  <div className="w-4 h-4 bg-blue-500 rounded-full"></div>
                  <span className="text-gray-700">Credit Bookings</span>
                </div>
                <div className="text-right">
                  <div className="font-medium text-gray-900">{metrics.credit_bookings}</div>
                  <div className="text-sm text-gray-500">
                    {((metrics.credit_bookings / metrics.total_bookings) * 100).toFixed(1)}%
                  </div>
                </div>
              </div>
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-3">
                  <div className="w-4 h-4 bg-green-500 rounded-full"></div>
                  <span className="text-gray-700">Card Bookings</span>
                </div>
                <div className="text-right">
                  <div className="font-medium text-gray-900">{metrics.card_bookings}</div>
                  <div className="text-sm text-gray-500">
                    {((metrics.card_bookings / metrics.total_bookings) * 100).toFixed(1)}%
                  </div>
                </div>
              </div>
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-3">
                  <div className="w-4 h-4 bg-purple-500 rounded-full"></div>
                  <span className="text-gray-700">Credit Pack Sales</span>
                </div>
                <div className="text-right">
                  <div className="font-medium text-gray-900">{metrics.credit_pack_sales}</div>
                  <div className="text-sm text-gray-500">
                    ${metrics.credit_pack_revenue_formatted}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-xl shadow-sm border border-gray-200">
          <div className="p-6 border-b border-gray-200">
            <h3 className="text-xl font-semibold text-gray-900">Revenue Breakdown</h3>
          </div>
          <div className="p-6">
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <span className="text-gray-700">Gross Revenue</span>
                <span className="font-medium text-gray-900">${metrics.total_revenue_formatted}</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-gray-700">Platform Commission ({metrics.commission_rate})</span>
                <span className="font-medium text-red-600">-${metrics.total_commission_formatted}</span>
              </div>
              <div className="border-t border-gray-200 pt-2">
                <div className="flex items-center justify-between">
                  <span className="font-medium text-gray-900">Instructor Earnings</span>
                  <span className="font-medium text-green-600">
                    ${(metrics.total_instructor_payouts_cents / 100).toFixed(2)}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function BookingTrendsView({ trends }: { trends: BookingTrend[] }) {
  return (
    <div className="space-y-6">
      <div className="bg-white rounded-xl shadow-sm border border-gray-200">
        <div className="p-6 border-b border-gray-200">
          <h3 className="text-xl font-semibold text-gray-900">Daily Booking Trends</h3>
          <p className="text-gray-600">Booking volume and payment methods over time</p>
        </div>
        <div className="p-6">
          <div className="h-64 flex items-end space-x-2">
            {trends.map((trend, index) => {
              const maxBookings = Math.max(...trends.map(t => t.total_bookings));
              const height = (trend.total_bookings / maxBookings) * 200;
              
              return (
                <div key={trend.date} className="flex-1 flex flex-col items-center">
                  <div className="w-full flex flex-col justify-end space-y-1" style={{ height: '200px' }}>
                    <div
                      className="w-full bg-blue-500 rounded-t"
                      style={{ height: `${(trend.credit_bookings / maxBookings) * 200}px` }}
                      title={`Credit Bookings: ${trend.credit_bookings}`}
                    ></div>
                    <div
                      className="w-full bg-green-500"
                      style={{ height: `${(trend.card_bookings / maxBookings) * 200}px` }}
                      title={`Card Bookings: ${trend.card_bookings}`}
                    ></div>
                  </div>
                  <div className="text-xs text-gray-500 mt-2 text-center">
                    {new Date(trend.date).getDate()}
                  </div>
                </div>
              );
            })}
          </div>
          <div className="mt-6 flex items-center justify-center space-x-6">
            <div className="flex items-center space-x-2">
              <div className="w-3 h-3 bg-blue-500 rounded"></div>
              <span className="text-sm text-gray-600">Credit Bookings</span>
            </div>
            <div className="flex items-center space-x-2">
              <div className="w-3 h-3 bg-green-500 rounded"></div>
              <span className="text-sm text-gray-600">Card Bookings</span>
            </div>
          </div>
        </div>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-200">
        <div className="p-6 border-b border-gray-200">
          <h3 className="text-xl font-semibold text-gray-900">Detailed Booking Data</h3>
        </div>
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-sm font-medium text-gray-500 uppercase tracking-wider">
                  Date
                </th>
                <th className="px-6 py-3 text-left text-sm font-medium text-gray-500 uppercase tracking-wider">
                  Total Bookings
                </th>
                <th className="px-6 py-3 text-left text-sm font-medium text-gray-500 uppercase tracking-wider">
                  Credit Bookings
                </th>
                <th className="px-6 py-3 text-left text-sm font-medium text-gray-500 uppercase tracking-wider">
                  Card Bookings
                </th>
                <th className="px-6 py-3 text-left text-sm font-medium text-gray-500 uppercase tracking-wider">
                  Revenue
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {trends.map((trend) => (
                <tr key={trend.date}>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {new Date(trend.date).toLocaleDateString()}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {trend.total_bookings}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-blue-600">
                    {trend.credit_bookings}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-green-600">
                    {trend.card_bookings}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                    ${trend.total_revenue_formatted}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

function CommissionDetails({ metrics }: { metrics: RevenueMetrics | null }) {
  if (!metrics) return null;

  return (
    <div className="space-y-6">
      <div className="bg-white rounded-xl shadow-sm border border-gray-200">
        <div className="p-6 border-b border-gray-200">
          <h3 className="text-xl font-semibold text-gray-900">Commission Structure</h3>
          <p className="text-gray-600">Transparent 15% flat rate commission on all transactions</p>
        </div>
        <div className="p-6">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="text-center p-6 bg-gray-50 rounded-lg">
              <div className="text-3xl font-bold text-blue-600">15%</div>
              <div className="text-sm text-gray-600 mt-1">Platform Commission</div>
            </div>
            <div className="text-center p-6 bg-gray-50 rounded-lg">
              <div className="text-3xl font-bold text-green-600">85%</div>
              <div className="text-sm text-gray-600 mt-1">Instructor Earnings</div>
            </div>
            <div className="text-center p-6 bg-gray-50 rounded-lg">
              <div className="text-3xl font-bold text-purple-600">Weekly</div>
              <div className="text-sm text-gray-600 mt-1">Payout Frequency</div>
            </div>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white rounded-xl shadow-sm border border-gray-200">
          <div className="p-6 border-b border-gray-200">
            <h3 className="text-xl font-semibold text-gray-900">Commission Breakdown</h3>
          </div>
          <div className="p-6">
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <span className="text-gray-700">Booking Commissions</span>
                <span className="font-medium text-gray-900">
                  ${((metrics.total_commission_cents - (parseFloat(metrics.credit_pack_revenue_formatted.replace('$', '')) * 0.15)) / 100).toFixed(2)}
                </span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-gray-700">Credit Pack Commissions</span>
                <span className="font-medium text-gray-900">
                  ${(parseFloat(metrics.credit_pack_revenue_formatted.replace('$', '')) * 0.15).toFixed(2)}
                </span>
              </div>
              <div className="border-t border-gray-200 pt-2">
                <div className="flex items-center justify-between">
                  <span className="font-medium text-gray-900">Total Commission</span>
                  <span className="font-medium text-blue-600">
                    ${metrics.total_commission_formatted}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-xl shadow-sm border border-gray-200">
          <div className="p-6 border-b border-gray-200">
            <h3 className="text-xl font-semibold text-gray-900">Payout Summary</h3>
          </div>
          <div className="p-6">
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <span className="text-gray-700">Pending Payouts</span>
                <span className="font-medium text-orange-600">$245.80</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-gray-700">Processed This Month</span>
                <span className="font-medium text-green-600">$1,890.45</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-gray-700">Next Payout Date</span>
                <span className="font-medium text-gray-900">Monday, Dec 11</span>
              </div>
              <div className="border-t border-gray-200 pt-2">
                <div className="flex items-center justify-between">
                  <span className="font-medium text-gray-900">Available Balance</span>
                  <span className="font-medium text-blue-600">
                    ${(metrics.total_instructor_payouts_cents / 100).toFixed(2)}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}