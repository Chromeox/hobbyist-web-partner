'use client';

import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  TrendingUp,
  TrendingDown,
  Users,
  DollarSign,
  Calendar,
  Activity,
  Target,
  Award,
  AlertTriangle,
  CheckCircle,
  XCircle,
  Clock,
  BarChart3,
  PieChart,
  LineChart,
  Brain,
  Sparkles,
  ArrowUp,
  ArrowDown
} from 'lucide-react';

interface MetricCard {
  label: string;
  value: string | number;
  change: number;
  trend: 'up' | 'down' | 'neutral';
  sparkline?: number[];
  forecast?: number;
}

interface CustomerSegment {
  name: string;
  count: number;
  revenue: number;
  avgSpend: number;
  retention: number;
  growth: number;
}

interface PredictiveMetric {
  metric: string;
  current: number;
  predicted: number;
  confidence: number;
  factors: string[];
}

export default function AdvancedAnalytics() {
  const [activeTab, setActiveTab] = useState('overview');
  const [selectedPeriod, setSelectedPeriod] = useState('30d');
  const [showForecast, setShowForecast] = useState(true);

  const tabs = [
    { id: 'overview', label: 'Overview', icon: BarChart3 },
    { id: 'revenue', label: 'Revenue Analytics', icon: DollarSign },
    { id: 'customers', label: 'Customer Insights', icon: Users },
    { id: 'classes', label: 'Class Performance', icon: Activity },
    { id: 'predictive', label: 'Predictive Analytics', icon: Brain },
    { id: 'cohorts', label: 'Cohort Analysis', icon: PieChart }
  ];

  const keyMetrics: MetricCard[] = [
    { 
      label: 'Total Revenue', 
      value: '$48,352', 
      change: 12.5, 
      trend: 'up',
      sparkline: [30, 35, 32, 40, 42, 45, 48],
      forecast: 52000
    },
    { 
      label: 'Active Students', 
      value: '1,247', 
      change: 8.3, 
      trend: 'up',
      sparkline: [1100, 1120, 1150, 1180, 1200, 1230, 1247],
      forecast: 1350
    },
    { 
      label: 'Avg Class Fill Rate', 
      value: '78%', 
      change: -2.1, 
      trend: 'down',
      sparkline: [80, 82, 79, 78, 77, 76, 78],
      forecast: 75
    },
    { 
      label: 'Customer LTV', 
      value: '$385', 
      change: 15.2, 
      trend: 'up',
      sparkline: [320, 330, 340, 350, 365, 375, 385],
      forecast: 420
    }
  ];

  const customerSegments: CustomerSegment[] = [
    { name: 'Enthusiasts', count: 312, revenue: 18500, avgSpend: 59, retention: 92, growth: 15 },
    { name: 'Regulars', count: 485, revenue: 21000, avgSpend: 43, retention: 78, growth: 8 },
    { name: 'Beginners', count: 892, revenue: 15800, avgSpend: 18, retention: 45, growth: 22 },
    { name: 'VIP Members', count: 47, revenue: 8900, avgSpend: 189, retention: 98, growth: 5 }
  ];

  const predictiveMetrics: PredictiveMetric[] = [
    {
      metric: 'Revenue Next Month',
      current: 48352,
      predicted: 52800,
      confidence: 87,
      factors: ['Seasonal trends', 'New pottery classes', 'Marketing campaign']
    },
    {
      metric: 'Churn Risk',
      current: 8.2,
      predicted: 6.5,
      confidence: 73,
      factors: ['Improved retention program', 'New instructor quality']
    },
    {
      metric: 'Peak Demand Days',
      current: 2,
      predicted: 4,
      confidence: 91,
      factors: ['Holiday season', 'Weekend workshops', 'School breaks']
    }
  ];

  const renderOverview = () => (
    <div className="space-y-6">
      {/* Key Metrics Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {keyMetrics.map((metric, index) => (
          <motion.div
            key={metric.label}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: index * 0.1 }}
            className="bg-white shadow-lg border border-gray-200 p-6 rounded-xl"
          >
            <div className="flex justify-between items-start mb-4">
              <div>
                <p className="text-sm text-gray-400">{metric.label}</p>
                <p className="text-2xl font-bold text-white mt-1">{metric.value}</p>
              </div>
              <div className={`p-2 rounded-lg ${
                metric.trend === 'up' ? 'bg-green-500/20' : 'bg-red-500/20'
              }`}>
                {metric.trend === 'up' ? 
                  <TrendingUp className="w-4 h-4 text-green-400" /> :
                  <TrendingDown className="w-4 h-4 text-red-400" />
                }
              </div>
            </div>
            
            <div className="flex items-center gap-2 mb-3">
              <span className={`text-sm font-medium ${
                metric.change > 0 ? 'text-green-400' : 'text-red-400'
              }`}>
                {metric.change > 0 ? '+' : ''}{metric.change}%
              </span>
              <span className="text-xs text-gray-500">vs last period</span>
            </div>

            {/* Mini Sparkline */}
            {metric.sparkline && (
              <div className="flex items-end gap-1 h-8 mb-3">
                {metric.sparkline.map((value, i) => (
                  <div
                    key={i}
                    className="flex-1 bg-purple-500/50 rounded-t"
                    style={{ height: `${(value / Math.max(...metric.sparkline!)) * 100}%` }}
                  />
                ))}
              </div>
            )}

            {showForecast && metric.forecast && (
              <div className="flex items-center gap-2 pt-3 border-t border-gray-700">
                <Sparkles className="w-3 h-3 text-purple-400" />
                <span className="text-xs text-gray-400">Forecast:</span>
                <span className="text-xs text-purple-400 font-medium">
                  ${metric.forecast.toLocaleString()}
                </span>
              </div>
            )}
          </motion.div>
        ))}
      </div>

      {/* Performance Insights */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white shadow-lg border border-gray-200 p-6 rounded-xl">
          <h3 className="text-lg font-semibold text-white mb-4">Top Performing Classes</h3>
          <div className="space-y-3">
            {[
              { name: 'Pottery Wheel Basics', fill: 95, revenue: 3200, trend: 'up' },
              { name: 'Watercolor Landscapes', fill: 88, revenue: 2800, trend: 'up' },
              { name: 'DJ Mixing Workshop', fill: 92, revenue: 4100, trend: 'up' },
              { name: 'Jewelry Making 101', fill: 76, revenue: 2200, trend: 'down' },
              { name: 'Fencing Fundamentals', fill: 71, revenue: 1900, trend: 'neutral' }
            ].map((cls) => (
              <div key={cls.name} className="flex items-center justify-between">
                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    <span className="text-sm text-white">{cls.name}</span>
                    {cls.trend === 'up' && <ArrowUp className="w-3 h-3 text-green-400" />}
                    {cls.trend === 'down' && <ArrowDown className="w-3 h-3 text-red-400" />}
                  </div>
                  <div className="flex items-center gap-4 mt-1">
                    <span className="text-xs text-gray-400">{cls.fill}% fill rate</span>
                    <span className="text-xs text-green-400">${cls.revenue}</span>
                  </div>
                </div>
                <div className="w-24 bg-gray-700 rounded-full h-2">
                  <div 
                    className="h-2 bg-gradient-to-r from-purple-500 to-pink-500 rounded-full"
                    style={{ width: `${cls.fill}%` }}
                  />
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="bg-white shadow-lg border border-gray-200 p-6 rounded-xl">
          <h3 className="text-lg font-semibold text-white mb-4">Revenue Breakdown</h3>
          <div className="space-y-4">
            <div className="flex justify-center">
              {/* Donut Chart Placeholder */}
              <div className="relative w-48 h-48">
                <svg className="w-48 h-48 transform -rotate-90">
                  <circle cx="96" cy="96" r="72" fill="none" stroke="#374151" strokeWidth="24" />
                  <circle cx="96" cy="96" r="72" fill="none" stroke="#8B5CF6" strokeWidth="24" 
                    strokeDasharray={`${2 * Math.PI * 72 * 0.4} ${2 * Math.PI * 72}`} />
                  <circle cx="96" cy="96" r="72" fill="none" stroke="#EC4899" strokeWidth="24" 
                    strokeDasharray={`${2 * Math.PI * 72 * 0.3} ${2 * Math.PI * 72}`}
                    strokeDashoffset={`-${2 * Math.PI * 72 * 0.4}`} />
                  <circle cx="96" cy="96" r="72" fill="none" stroke="#06B6D4" strokeWidth="24" 
                    strokeDasharray={`${2 * Math.PI * 72 * 0.2} ${2 * Math.PI * 72}`}
                    strokeDashoffset={`-${2 * Math.PI * 72 * 0.7}`} />
                </svg>
                <div className="absolute inset-0 flex items-center justify-center">
                  <div className="text-center">
                    <p className="text-2xl font-bold text-white">$48.3k</p>
                    <p className="text-xs text-gray-400">Total</p>
                  </div>
                </div>
              </div>
            </div>
            <div className="space-y-2">
              <div className="flex justify-between items-center">
                <div className="flex items-center gap-2">
                  <div className="w-3 h-3 bg-purple-500 rounded" />
                  <span className="text-sm text-gray-300">Class Fees</span>
                </div>
                <span className="text-sm text-white font-medium">$19,340 (40%)</span>
              </div>
              <div className="flex justify-between items-center">
                <div className="flex items-center gap-2">
                  <div className="w-3 h-3 bg-pink-500 rounded" />
                  <span className="text-sm text-gray-300">Credit Packs</span>
                </div>
                <span className="text-sm text-white font-medium">$14,505 (30%)</span>
              </div>
              <div className="flex justify-between items-center">
                <div className="flex items-center gap-2">
                  <div className="w-3 h-3 bg-cyan-500 rounded" />
                  <span className="text-sm text-gray-300">Subscriptions</span>
                </div>
                <span className="text-sm text-white font-medium">$9,670 (20%)</span>
              </div>
              <div className="flex justify-between items-center">
                <div className="flex items-center gap-2">
                  <div className="w-3 h-3 bg-gray-500 rounded" />
                  <span className="text-sm text-gray-300">Other</span>
                </div>
                <span className="text-sm text-white font-medium">$4,837 (10%)</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );

  const renderCustomerInsights = () => (
    <div className="space-y-6">
      <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-4 gap-4">
        {customerSegments.map((segment) => (
          <div key={segment.name} className="bg-white shadow-lg border border-gray-200 p-6 rounded-xl">
            <div className="flex justify-between items-start mb-4">
              <div>
                <h4 className="font-semibold text-white">{segment.name}</h4>
                <p className="text-sm text-gray-400 mt-1">{segment.count} customers</p>
              </div>
              <div className={`text-sm font-medium ${
                segment.growth > 10 ? 'text-green-400' : 'text-yellow-400'
              }`}>
                +{segment.growth}%
              </div>
            </div>
            
            <div className="space-y-3">
              <div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-400">Revenue</span>
                  <span className="text-white font-medium">${segment.revenue.toLocaleString()}</span>
                </div>
                <div className="w-full bg-gray-700 rounded-full h-1 mt-1">
                  <div 
                    className="h-1 bg-purple-500 rounded-full"
                    style={{ width: `${(segment.revenue / 25000) * 100}%` }}
                  />
                </div>
              </div>
              
              <div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-400">Avg Spend</span>
                  <span className="text-white">${segment.avgSpend}</span>
                </div>
              </div>
              
              <div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-400">Retention</span>
                  <span className={`font-medium ${
                    segment.retention > 80 ? 'text-green-400' : 
                    segment.retention > 60 ? 'text-yellow-400' : 'text-red-400'
                  }`}>
                    {segment.retention}%
                  </span>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Customer Behavior Patterns */}
      <div className="bg-white shadow-lg border border-gray-200 p-6 rounded-xl">
        <h3 className="text-lg font-semibold text-white mb-4">Behavior Patterns</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div>
            <h4 className="text-sm font-medium text-gray-300 mb-3">Booking Patterns</h4>
            <div className="space-y-2">
              <div className="flex justify-between text-sm">
                <span className="text-gray-400">Peak booking time</span>
                <span className="text-white">Tue 7-9pm</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-gray-400">Avg lead time</span>
                <span className="text-white">3.2 days</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-gray-400">Mobile bookings</span>
                <span className="text-white">67%</span>
              </div>
            </div>
          </div>
          
          <div>
            <h4 className="text-sm font-medium text-gray-300 mb-3">Preferences</h4>
            <div className="space-y-2">
              <div className="flex justify-between text-sm">
                <span className="text-gray-400">Favorite category</span>
                <span className="text-white">Pottery</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-gray-400">Avg class duration</span>
                <span className="text-white">90 min</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-gray-400">Group bookings</span>
                <span className="text-white">23%</span>
              </div>
            </div>
          </div>
          
          <div>
            <h4 className="text-sm font-medium text-gray-300 mb-3">Engagement</h4>
            <div className="space-y-2">
              <div className="flex justify-between text-sm">
                <span className="text-gray-400">Email open rate</span>
                <span className="text-white">42%</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-gray-400">Referral rate</span>
                <span className="text-white">18%</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-gray-400">Review rate</span>
                <span className="text-white">31%</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );

  const renderPredictiveAnalytics = () => (
    <div className="space-y-6">
      <div className="bg-white shadow-lg border border-gray-200 p-6 rounded-xl">
        <div className="flex justify-between items-center mb-6">
          <h3 className="text-lg font-semibold text-white">AI-Powered Predictions</h3>
          <div className="flex items-center gap-2">
            <Brain className="w-5 h-5 text-purple-400" />
            <span className="text-sm text-gray-400">Updated 2 hours ago</span>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {predictiveMetrics.map((metric) => (
            <div key={metric.metric} className="border border-gray-700 rounded-xl p-4">
              <h4 className="font-medium text-white mb-3">{metric.metric}</h4>
              
              <div className="flex items-baseline gap-3 mb-3">
                <div>
                  <p className="text-xs text-gray-400">Current</p>
                  <p className="text-xl font-semibold text-gray-300">
                    {metric.metric.includes('Revenue') ? `$${metric.current.toLocaleString()}` :
                     metric.metric.includes('%') || metric.metric.includes('Risk') ? `${metric.current}%` :
                     metric.current}
                  </p>
                </div>
                <ArrowUp className="w-4 h-4 text-purple-400" />
                <div>
                  <p className="text-xs text-gray-400">Predicted</p>
                  <p className="text-xl font-semibold text-purple-400">
                    {metric.metric.includes('Revenue') ? `$${metric.predicted.toLocaleString()}` :
                     metric.metric.includes('%') || metric.metric.includes('Risk') ? `${metric.predicted}%` :
                     metric.predicted}
                  </p>
                </div>
              </div>

              <div className="mb-3">
                <div className="flex justify-between text-xs mb-1">
                  <span className="text-gray-400">Confidence</span>
                  <span className="text-white">{metric.confidence}%</span>
                </div>
                <div className="w-full bg-gray-700 rounded-full h-2">
                  <div 
                    className={`h-2 rounded-full ${
                      metric.confidence > 80 ? 'bg-green-500' :
                      metric.confidence > 60 ? 'bg-yellow-500' : 'bg-red-500'
                    }`}
                    style={{ width: `${metric.confidence}%` }}
                  />
                </div>
              </div>

              <div>
                <p className="text-xs text-gray-400 mb-2">Key Factors:</p>
                <div className="space-y-1">
                  {metric.factors.map((factor, i) => (
                    <div key={i} className="flex items-center gap-2">
                      <div className="w-1 h-1 bg-purple-400 rounded-full" />
                      <span className="text-xs text-gray-300">{factor}</span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Recommendations */}
      <div className="bg-white shadow-lg border border-gray-200 p-6 rounded-xl">
        <h3 className="text-lg font-semibold text-white mb-4">AI Recommendations</h3>
        <div className="space-y-4">
          {[
            {
              priority: 'high',
              title: 'Schedule more pottery classes on weekends',
              impact: 'Could increase revenue by $3,200/month',
              reason: '87% fill rate with 45% higher pricing tolerance'
            },
            {
              priority: 'medium',
              title: 'Launch beginner-friendly DJ workshop series',
              impact: 'Attract 50-80 new students',
              reason: 'High search volume, low competition in area'
            },
            {
              priority: 'low',
              title: 'Optimize Tuesday evening schedule',
              impact: 'Improve fill rate by 12%',
              reason: 'Current 3-hour gap between popular classes'
            }
          ].map((rec, i) => (
            <div key={i} className="flex gap-4 p-4 border border-gray-700 rounded-lg">
              <div className={`mt-1 p-1 rounded ${
                rec.priority === 'high' ? 'bg-red-500/20' :
                rec.priority === 'medium' ? 'bg-yellow-500/20' :
                'bg-blue-500/20'
              }`}>
                <Target className={`w-4 h-4 ${
                  rec.priority === 'high' ? 'text-red-400' :
                  rec.priority === 'medium' ? 'text-yellow-400' :
                  'text-blue-400'
                }`} />
              </div>
              <div className="flex-1">
                <h4 className="font-medium text-white">{rec.title}</h4>
                <p className="text-sm text-purple-400 mt-1">{rec.impact}</p>
                <p className="text-xs text-gray-400 mt-2">{rec.reason}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );

  return (
    <div className="p-6">
      <div className="mb-8">
        <div className="flex justify-between items-center">
          <div>
            <h1 className="text-3xl font-bold text-white mb-2">Advanced Analytics</h1>
            <p className="text-gray-400">Data-driven insights to grow your hobby studio</p>
          </div>
          
          <div className="flex items-center gap-3">
            <select 
              value={selectedPeriod}
              onChange={(e) => setSelectedPeriod(e.target.value)}
              className="px-4 py-2 bg-gray-800 text-white rounded-lg"
            >
              <option value="7d">Last 7 days</option>
              <option value="30d">Last 30 days</option>
              <option value="90d">Last 90 days</option>
              <option value="1y">Last year</option>
            </select>
            
            <button
              onClick={() => setShowForecast(!showForecast)}
              className={`px-4 py-2 rounded-lg flex items-center gap-2 ${
                showForecast ? 'bg-purple-600 text-white' : 'bg-gray-800 text-gray-400'
              }`}
            >
              <Sparkles className="w-4 h-4" />
              Forecast
            </button>
          </div>
        </div>
      </div>

      <div className="flex gap-2 mb-6 overflow-x-auto">
        {tabs.map(tab => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg whitespace-nowrap transition-colors ${
              activeTab === tab.id
                ? 'bg-purple-600 text-white'
                : 'bg-gray-800 text-gray-400 hover:bg-gray-700'
            }`}
          >
            <tab.icon className="w-4 h-4" />
            {tab.label}
          </button>
        ))}
      </div>

      <AnimatePresence mode="wait">
        <motion.div
          key={activeTab}
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -20 }}
          transition={{ duration: 0.2 }}
        >
          {activeTab === 'overview' && renderOverview()}
          {activeTab === 'customers' && renderCustomerInsights()}
          {activeTab === 'predictive' && renderPredictiveAnalytics()}
          {/* Other tabs would be implemented similarly */}
        </motion.div>
      </AnimatePresence>
    </div>
  );
}