'use client';

import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  CreditCard,
  Check,
  X,
  Plus,
  Trash2,
  Users,
  TrendingUp,
  Calendar,
  DollarSign,
  Zap,
  Star,
  Gift,
  Shield,
  Clock,
  RefreshCw,
  AlertCircle,
  ChevronRight,
  Sparkles,
  Crown,
  Award,
  Infinity,
  Heart
} from 'lucide-react';

interface SubscriptionTier {
  id: string;
  name: string;
  description: string;
  price: number;
  interval: 'monthly' | 'quarterly' | 'yearly';
  features: string[];
  limitations: {
    classesPerMonth?: number | 'unlimited';
    bookingWindow?: number; // days in advance
    guestPasses?: number;
    priorityBooking?: boolean;
    exclusiveClasses?: boolean;
  };
  highlightColor: string;
  icon: React.ElementType;
  isPopular?: boolean;
  currentSubscribers: number;
  monthlyRevenue: number;
  churnRate: number;
  averageLTV: number;
}

interface Subscriber {
  id: string;
  name: string;
  email: string;
  tier: string;
  startDate: string;
  nextBilling: string;
  totalSpent: number;
  classesAttended: number;
  status: 'active' | 'paused' | 'cancelled';
}

export default function SubscriptionTiers() {
  const [activeTab, setActiveTab] = useState('tiers');
  const [showAddTierModal, setShowAddTierModal] = useState(false);

  const subscriptionTiers: SubscriptionTier[] = [
    {
      id: '1',
      name: 'Hobbyist Explorer',
      description: 'Perfect for trying new hobbies',
      price: 49,
      interval: 'monthly',
      features: [
        '4 classes per month',
        'Book 7 days in advance',
        'Access to beginner classes',
        'Member community access',
        '10% off workshops'
      ],
      limitations: {
        classesPerMonth: 4,
        bookingWindow: 7,
        guestPasses: 0,
        priorityBooking: false,
        exclusiveClasses: false
      },
      highlightColor: 'from-blue-500 to-cyan-500',
      icon: Star,
      currentSubscribers: 234,
      monthlyRevenue: 11466,
      churnRate: 8.2,
      averageLTV: 245
    },
    {
      id: '2',
      name: 'Creative Enthusiast',
      description: 'For dedicated hobby lovers',
      price: 99,
      interval: 'monthly',
      features: [
        '10 classes per month',
        'Book 14 days in advance',
        'All skill level classes',
        '2 guest passes per month',
        'Priority waitlist',
        '20% off workshops',
        'Exclusive member events'
      ],
      limitations: {
        classesPerMonth: 10,
        bookingWindow: 14,
        guestPasses: 2,
        priorityBooking: true,
        exclusiveClasses: false
      },
      highlightColor: 'from-purple-500 to-pink-500',
      icon: Crown,
      isPopular: true,
      currentSubscribers: 456,
      monthlyRevenue: 45144,
      churnRate: 5.1,
      averageLTV: 495
    },
    {
      id: '3',
      name: 'Unlimited Creator',
      description: 'Unlimited access to everything',
      price: 179,
      interval: 'monthly',
      features: [
        'Unlimited classes',
        'Book 30 days in advance',
        'All classes including premium',
        '4 guest passes per month',
        'Priority booking',
        'Free workshops',
        'VIP events & previews',
        'Personal progress tracking',
        'Free equipment rental'
      ],
      limitations: {
        classesPerMonth: 'unlimited',
        bookingWindow: 30,
        guestPasses: 4,
        priorityBooking: true,
        exclusiveClasses: true
      },
      highlightColor: 'from-yellow-500 to-orange-500',
      icon: Infinity,
      currentSubscribers: 89,
      monthlyRevenue: 15931,
      churnRate: 2.8,
      averageLTV: 1250
    }
  ];

  const subscribers: Subscriber[] = [
    {
      id: '1',
      name: 'Sarah Mitchell',
      email: 'sarah.m@email.com',
      tier: 'Creative Enthusiast',
      startDate: '2024-06-15',
      nextBilling: '2025-02-15',
      totalSpent: 792,
      classesAttended: 67,
      status: 'active'
    },
    {
      id: '2',
      name: 'James Chen',
      email: 'jchen@email.com',
      tier: 'Unlimited Creator',
      startDate: '2024-08-01',
      nextBilling: '2025-02-01',
      totalSpent: 1074,
      classesAttended: 124,
      status: 'active'
    },
    {
      id: '3',
      name: 'Emily Brown',
      email: 'emily.b@email.com',
      tier: 'Hobbyist Explorer',
      startDate: '2024-11-20',
      nextBilling: '2025-02-20',
      totalSpent: 147,
      classesAttended: 8,
      status: 'active'
    }
  ];

  const tabs = [
    { id: 'tiers', label: 'Subscription Tiers', icon: CreditCard },
    { id: 'members', label: 'Members', icon: Users },
    { id: 'analytics', label: 'Analytics', icon: TrendingUp },
    { id: 'automation', label: 'Automation', icon: Zap }
  ];

  const renderTierCard = (tier: SubscriptionTier) => (
    <motion.div
      key={tier.id}
      className={`bg-white shadow-lg border border-gray-200 rounded-xl p-6 ${tier.isPopular ? 'ring-2 ring-purple-500' : ''}`}
      whileHover={{ scale: 1.02 }}
    >
      {tier.isPopular && (
        <div className="absolute -top-3 left-1/2 transform -translate-x-1/2">
          <span className="px-3 py-1 bg-purple-500 text-gray-900 text-xs font-semibold rounded-full">
            Most Popular
          </span>
        </div>
      )}

      <div className="flex items-start justify-between mb-4">
        <div className={`p-3 rounded-xl bg-gradient-to-br ${tier.highlightColor}`}>
          <tier.icon className="w-6 h-6 text-gray-900" />
        </div>
      </div>

      <h3 className="text-xl font-bold text-gray-900 mb-2">{tier.name}</h3>
      <p className="text-sm text-gray-600 mb-4">{tier.description}</p>

      <div className="mb-6">
        <div className="flex items-baseline gap-1">
          <span className="text-3xl font-bold text-gray-900">${tier.price}</span>
          <span className="text-gray-600">/{tier.interval}</span>
        </div>
      </div>

      <div className="space-y-3 mb-6">
        {tier.features.map((feature, i) => (
          <div key={i} className="flex items-start gap-2">
            <Check className="w-4 h-4 text-green-400 mt-0.5 flex-shrink-0" />
            <span className="text-sm text-gray-700">{feature}</span>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-2 gap-3 pt-4 border-t border-gray-200">
        <div>
          <p className="text-2xl font-bold text-gray-900">{tier.currentSubscribers}</p>
          <p className="text-xs text-gray-600">Subscribers</p>
        </div>
        <div>
          <p className="text-2xl font-bold text-green-400">
            ${(tier.monthlyRevenue / 1000).toFixed(1)}k
          </p>
          <p className="text-xs text-gray-600">Monthly</p>
        </div>
        <div>
          <p className="text-2xl font-bold text-gray-900">{tier.churnRate}%</p>
          <p className="text-xs text-gray-600">Churn Rate</p>
        </div>
        <div>
          <p className="text-2xl font-bold text-gray-900">${tier.averageLTV}</p>
          <p className="text-xs text-gray-600">Avg LTV</p>
        </div>
      </div>
    </motion.div>
  );

  const renderTiers = () => (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h3 className="text-lg font-semibold text-gray-900">Active Subscription Plans</h3>
          <p className="text-sm text-gray-600 mt-1">Manage your membership tiers and pricing</p>
        </div>
        <button
          onClick={() => setShowAddTierModal(true)}
          className="px-4 py-2 bg-purple-600 text-gray-900 rounded-lg hover:bg-purple-700 flex items-center gap-2"
        >
          <Plus className="w-4 h-4" />
          Add Tier
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {subscriptionTiers.map(renderTierCard)}
      </div>

      {/* Comparison Table */}
      <div className="bg-white shadow-lg border border-gray-200 rounded-xl p-6 mt-8">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Feature Comparison</h3>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b border-gray-200">
                <th className="text-left py-3 px-4 text-sm text-gray-600">Feature</th>
                {subscriptionTiers.map(tier => (
                  <th key={tier.id} className="text-center py-3 px-4">
                    <span className="text-sm font-medium text-gray-900">{tier.name}</span>
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              <tr className="border-b border-gray-200/50">
                <td className="py-3 px-4 text-sm text-gray-700">Classes per month</td>
                {subscriptionTiers.map(tier => (
                  <td key={tier.id} className="text-center py-3 px-4">
                    <span className="text-sm text-gray-900 font-medium">
                      {tier.limitations.classesPerMonth === 'unlimited' ? '∞' : tier.limitations.classesPerMonth}
                    </span>
                  </td>
                ))}
              </tr>
              <tr className="border-b border-gray-200/50">
                <td className="py-3 px-4 text-sm text-gray-700">Booking window</td>
                {subscriptionTiers.map(tier => (
                  <td key={tier.id} className="text-center py-3 px-4">
                    <span className="text-sm text-gray-900">{tier.limitations.bookingWindow} days</span>
                  </td>
                ))}
              </tr>
              <tr className="border-b border-gray-200/50">
                <td className="py-3 px-4 text-sm text-gray-700">Guest passes</td>
                {subscriptionTiers.map(tier => (
                  <td key={tier.id} className="text-center py-3 px-4">
                    <span className="text-sm text-gray-900">{tier.limitations.guestPasses}</span>
                  </td>
                ))}
              </tr>
              <tr className="border-b border-gray-200/50">
                <td className="py-3 px-4 text-sm text-gray-700">Priority booking</td>
                {subscriptionTiers.map(tier => (
                  <td key={tier.id} className="text-center py-3 px-4">
                    {tier.limitations.priorityBooking ? (
                      <Check className="w-4 h-4 text-green-400 mx-auto" />
                    ) : (
                      <X className="w-4 h-4 text-gray-600 mx-auto" />
                    )}
                  </td>
                ))}
              </tr>
              <tr>
                <td className="py-3 px-4 text-sm text-gray-700">Exclusive classes</td>
                {subscriptionTiers.map(tier => (
                  <td key={tier.id} className="text-center py-3 px-4">
                    {tier.limitations.exclusiveClasses ? (
                      <Check className="w-4 h-4 text-green-400 mx-auto" />
                    ) : (
                      <X className="w-4 h-4 text-gray-600 mx-auto" />
                    )}
                  </td>
                ))}
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );

  const renderMembers = () => (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h3 className="text-lg font-semibold text-gray-900">Subscription Members</h3>
          <p className="text-sm text-gray-600 mt-1">Manage your subscription members</p>
        </div>
        <div className="flex gap-3">
          <button className="px-4 py-2 bg-gray-100 text-gray-900 rounded-lg hover:bg-gray-200">
            Export
          </button>
          <button className="px-4 py-2 bg-purple-600 text-gray-900 rounded-lg hover:bg-purple-700">
            Send Campaign
          </button>
        </div>
      </div>

      <div className="bg-white shadow-lg border border-gray-200 rounded-xl overflow-hidden">
        <table className="w-full">
          <thead className="bg-gray-100/50">
            <tr>
              <th className="text-left py-3 px-4 text-sm text-gray-600">Member</th>
              <th className="text-left py-3 px-4 text-sm text-gray-600">Tier</th>
              <th className="text-left py-3 px-4 text-sm text-gray-600">Status</th>
              <th className="text-left py-3 px-4 text-sm text-gray-600">Next Billing</th>
              <th className="text-left py-3 px-4 text-sm text-gray-600">Total Spent</th>
              <th className="text-left py-3 px-4 text-sm text-gray-600">Classes</th>
              <th className="text-left py-3 px-4 text-sm text-gray-600">Actions</th>
            </tr>
          </thead>
          <tbody>
            {subscribers.map(subscriber => (
              <tr key={subscriber.id} className="border-b border-gray-200/50">
                <td className="py-3 px-4">
                  <div>
                    <p className="text-gray-900 font-medium">{subscriber.name}</p>
                    <p className="text-xs text-gray-600">{subscriber.email}</p>
                  </div>
                </td>
                <td className="py-3 px-4">
                  <span className="px-2 py-1 bg-purple-500/20 text-purple-400 text-xs rounded-full">
                    {subscriber.tier}
                  </span>
                </td>
                <td className="py-3 px-4">
                  <div className={`flex items-center gap-1 ${
                    subscriber.status === 'active' ? 'text-green-400' :
                    subscriber.status === 'paused' ? 'text-yellow-400' : 'text-red-400'
                  }`}>
                    <div className={`w-2 h-2 rounded-full ${
                      subscriber.status === 'active' ? 'bg-green-400' :
                      subscriber.status === 'paused' ? 'bg-yellow-400' : 'bg-red-400'
                    }`} />
                    <span className="text-sm capitalize">{subscriber.status}</span>
                  </div>
                </td>
                <td className="py-3 px-4 text-sm text-gray-700">{subscriber.nextBilling}</td>
                <td className="py-3 px-4 text-sm text-gray-900 font-medium">${subscriber.totalSpent}</td>
                <td className="py-3 px-4 text-sm text-gray-700">{subscriber.classesAttended}</td>
                <td className="py-3 px-4">
                  <button className="text-purple-400 hover:text-purple-300 text-sm">
                    Manage
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );

  const renderAnalytics = () => (
    <div className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-white shadow-lg border border-gray-200 p-4 rounded-xl">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-green-500/20 rounded-lg">
              <DollarSign className="w-5 h-5 text-green-400" />
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-900">$72.5k</p>
              <p className="text-sm text-gray-600">MRR</p>
            </div>
          </div>
        </div>

        <div className="bg-white shadow-lg border border-gray-200 p-4 rounded-xl">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-purple-500/20 rounded-lg">
              <Users className="w-5 h-5 text-purple-400" />
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-900">779</p>
              <p className="text-sm text-gray-600">Active Members</p>
            </div>
          </div>
        </div>

        <div className="bg-white shadow-lg border border-gray-200 p-4 rounded-xl">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-blue-500/20 rounded-lg">
              <TrendingUp className="w-5 h-5 text-blue-400" />
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-900">5.4%</p>
              <p className="text-sm text-gray-600">Avg Churn</p>
            </div>
          </div>
        </div>

        <div className="bg-white shadow-lg border border-gray-200 p-4 rounded-xl">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-yellow-500/20 rounded-lg">
              <Award className="w-5 h-5 text-yellow-400" />
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-900">$485</p>
              <p className="text-sm text-gray-600">Avg LTV</p>
            </div>
          </div>
        </div>
      </div>

      <div className="bg-white shadow-lg border border-gray-200 p-6 rounded-xl">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Subscription Growth</h3>
        <div className="h-64 flex items-center justify-center text-gray-500">
          [Chart showing subscription growth over time]
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white shadow-lg border border-gray-200 p-6 rounded-xl">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Tier Distribution</h3>
          <div className="space-y-3">
            {subscriptionTiers.map(tier => {
              const percentage = (tier.currentSubscribers / 779) * 100;
              return (
                <div key={tier.id}>
                  <div className="flex justify-between items-center mb-1">
                    <span className="text-sm text-gray-700">{tier.name}</span>
                    <span className="text-sm text-gray-900 font-medium">
                      {tier.currentSubscribers} ({percentage.toFixed(1)}%)
                    </span>
                  </div>
                  <div className="w-full bg-gray-700 rounded-full h-2">
                    <div 
                      className={`h-2 rounded-full bg-gradient-to-r ${tier.highlightColor}`}
                      style={{ width: `${percentage}%` }}
                    />
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        <div className="bg-white shadow-lg border border-gray-200 p-6 rounded-xl">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Churn Reasons</h3>
          <div className="space-y-3">
            {[
              { reason: 'Too expensive', count: 45, percentage: 35 },
              { reason: 'Not enough time', count: 32, percentage: 25 },
              { reason: 'Moved away', count: 26, percentage: 20 },
              { reason: 'Found alternative', count: 19, percentage: 15 },
              { reason: 'Other', count: 6, percentage: 5 }
            ].map(item => (
              <div key={item.reason} className="flex items-center justify-between">
                <span className="text-sm text-gray-700">{item.reason}</span>
                <div className="flex items-center gap-3">
                  <div className="w-32 bg-gray-700 rounded-full h-2">
                    <div 
                      className="h-2 bg-red-500 rounded-full"
                      style={{ width: `${item.percentage}%` }}
                    />
                  </div>
                  <span className="text-sm text-gray-900 w-12 text-right">{item.count}</span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );

  const renderAutomation = () => (
    <div className="space-y-6">
      <div>
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Subscription Automations</h3>
        <p className="text-sm text-gray-600">Set up automated workflows for subscription management</p>
      </div>

      <div className="grid gap-4">
        {[
          {
            name: 'Welcome Series',
            description: 'Send onboarding emails to new subscribers',
            icon: Gift,
            isActive: true,
            stats: 'Sent to 89% of new members'
          },
          {
            name: 'Payment Retry',
            description: 'Automatically retry failed payments',
            icon: RefreshCw,
            isActive: true,
            stats: 'Recovered $3,200 last month'
          },
          {
            name: 'Churn Prevention',
            description: 'Engage at-risk members with special offers',
            icon: Shield,
            isActive: false,
            stats: 'Could save 15% of cancellations'
          },
        ].map(automation => (
          <div key={automation.name} className="bg-white shadow-lg border border-gray-200 p-6 rounded-xl">
            <div className="flex items-start justify-between">
              <div className="flex gap-4">
                <div className={`p-3 rounded-lg ${
                  automation.isActive ? 'bg-purple-500/20' : 'bg-gray-700'
                }`}>
                  <automation.icon className={`w-5 h-5 ${
                    automation.isActive ? 'text-purple-400' : 'text-gray-600'
                  }`} />
                </div>
                <div>
                  <h4 className="font-medium text-gray-900">{automation.name}</h4>
                  <p className="text-sm text-gray-600 mt-1">{automation.description}</p>
                  <p className="text-xs text-purple-400 mt-2">{automation.stats}</p>
                </div>
              </div>
              <button
                className={`relative inline-flex h-6 w-11 items-center rounded-full ${
                  automation.isActive ? 'bg-purple-600' : 'bg-gray-600'
                }`}
              >
                <span
                  className={`inline-block h-4 w-4 transform rounded-full bg-white transition ${
                    automation.isActive ? 'translate-x-6' : 'translate-x-1'
                  }`}
                />
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );

  return (
    <div className="p-6">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Subscription Management</h1>
        <p className="text-gray-600">Manage membership tiers and recurring billing</p>
      </div>

      <div className="flex gap-2 mb-6 overflow-x-auto">
        {tabs.map(tab => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg whitespace-nowrap transition-colors ${
              activeTab === tab.id
                ? 'bg-purple-600 text-gray-900'
                : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
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
          {activeTab === 'tiers' && renderTiers()}
          {activeTab === 'members' && renderMembers()}
          {activeTab === 'analytics' && renderAnalytics()}
          {activeTab === 'automation' && renderAutomation()}
        </motion.div>
      </AnimatePresence>
    </div>
  );
}
