'use client';

import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Send, Mail, MessageSquare, Users, Target, TrendingUp,
  Calendar, Clock, Filter, Search, Plus, Edit3, Trash2,
  Copy, Pause, Play, CheckCircle, AlertCircle, BarChart3,
  Zap, Award, Gift, Heart, Star, Tag, Megaphone,
  Smartphone, Globe, ChevronRight, Eye, Settings,
  UserCheck, UserX, DollarSign, Percent
} from 'lucide-react';
import { usePaymentModel } from '@/lib/contexts/PaymentModelContext';

interface Campaign {
  id: string;
  name: string;
  type: 'email' | 'sms' | 'push' | 'multi';
  status: 'draft' | 'scheduled' | 'active' | 'paused' | 'completed';
  audience: {
    segment: string;
    count: number;
    filters: string[];
  };
  content: {
    subject?: string;
    preview?: string;
    body: string;
    cta?: {
      text: string;
      url: string;
    };
  };
  schedule: {
    type: 'immediate' | 'scheduled' | 'recurring';
    sendAt?: string;
    timezone?: string;
    frequency?: string;
  };
  performance: {
    sent: number;
    delivered: number;
    opened: number;
    clicked: number;
    converted: number;
    revenue: number;
  };
  createdAt: string;
  updatedAt: string;
}

interface Template {
  id: string;
  name: string;
  category: string;
  thumbnail: string;
  variables: string[];
}

export default function MarketingCampaigns() {
  const { isCreditsEnabled } = usePaymentModel();
  const [activeTab, setActiveTab] = useState('campaigns');
  const [selectedCampaign, setSelectedCampaign] = useState<Campaign | null>(null);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState('all');

  const [campaigns] = useState<Campaign[]>([
    {
      id: '1',
      name: 'Summer Yoga Challenge',
      type: 'multi',
      status: 'active',
      audience: {
        segment: 'Active Members',
        count: 342,
        filters: ['Last 30 days active', 'Yoga interest']
      },
      content: {
        subject: '🧘 Join Our 30-Day Summer Yoga Challenge!',
        preview: 'Transform your practice this summer...',
        body: 'Get ready for an amazing journey of flexibility and mindfulness!',
        cta: {
          text: 'Join Challenge',
          url: 'https://studio.com/challenge'
        }
      },
      schedule: {
        type: 'scheduled',
        sendAt: '2025-08-10T09:00:00',
        timezone: 'America/Los_Angeles'
      },
      performance: {
        sent: 342,
        delivered: 338,
        opened: 187,
        clicked: 89,
        converted: 34,
        revenue: 2450
      },
      createdAt: '2025-08-01T10:00:00Z',
      updatedAt: '2025-08-08T14:30:00Z'
    },
    {
      id: '2',
      name: 'Win-Back Campaign',
      type: 'email',
      status: 'scheduled',
      audience: {
        segment: 'Inactive Members',
        count: 128,
        filters: ['No activity 60+ days', 'Previous purchaser']
      },
      content: {
        subject: 'We Miss You! 50% Off Your Next Class',
        preview: 'Come back to your practice with an exclusive offer...',
        body: 'Its been a while! We have an exclusive offer just for you.',
        cta: {
          text: 'Claim Offer',
          url: 'https://studio.com/comeback'
        }
      },
      schedule: {
        type: 'scheduled',
        sendAt: '2025-08-12T10:00:00',
        timezone: 'America/Los_Angeles'
      },
      performance: {
        sent: 0,
        delivered: 0,
        opened: 0,
        clicked: 0,
        converted: 0,
        revenue: 0
      },
      createdAt: '2025-08-05T09:00:00Z',
      updatedAt: '2025-08-05T09:00:00Z'
    }
  ]);

  const templates: Template[] = [
    { id: '1', name: 'Welcome Series', category: 'Onboarding', thumbnail: '📧', variables: ['firstName', 'studioName'] },
    { id: '2', name: 'Class Reminder', category: 'Transactional', thumbnail: '⏰', variables: ['className', 'time', 'instructor'] },
    { id: '3', name: 'Special Offer', category: 'Promotional', thumbnail: '🎁', variables: ['discount', 'expiry'] },
    { id: '4', name: 'Birthday Wishes', category: 'Engagement', thumbnail: '🎂', variables: ['firstName', 'giftCredits'] },
    { id: '5', name: 'Review Request', category: 'Feedback', thumbnail: '⭐', variables: ['className', 'instructor'] }
  ];

  const segments = [
    { id: '1', name: 'New Members', count: 45, growth: 12 },
    { id: '2', name: 'Active Members', count: 342, growth: 5 },
    { id: '3', name: 'VIP Members', count: 89, growth: 8 },
    { id: '4', name: 'Inactive (30+ days)', count: 128, growth: -3 },
    { id: '5', name: 'Birthday This Month', count: 23, growth: 0 }
  ];

  const automations = [
    { 
      id: '1', 
      name: 'Welcome Email Series', 
      trigger: 'New signup', 
      status: 'active',
      emails: 3,
      enrolled: 245,
      conversion: 68
    },
    { 
      id: '2', 
      name: 'Abandoned Booking Recovery', 
      trigger: 'Cart abandonment', 
      status: 'active',
      emails: 2,
      enrolled: 89,
      conversion: 34
    },
    { 
      id: '3', 
      name: 'Post-Class Follow-up', 
      trigger: 'Class completion', 
      status: 'active',
      emails: 1,
      enrolled: 567,
      conversion: 45
    }
  ];

  const stats = {
    totalSent: 12453,
    avgOpenRate: 42,
    avgClickRate: 18,
    totalRevenue: 34500
  };

  const tabs = [
    { id: 'campaigns', label: 'Campaigns', icon: Megaphone },
    { id: 'automations', label: 'Automations', icon: Zap },
    { id: 'templates', label: 'Templates', icon: Mail },
    { id: 'segments', label: 'Segments', icon: Users },
    { id: 'analytics', label: 'Analytics', icon: BarChart3 }
  ];

  const filteredCampaigns = campaigns.filter(campaign => {
    const matchesSearch = campaign.name.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = filterStatus === 'all' || campaign.status === filterStatus;
    return matchesSearch && matchesStatus;
  });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Marketing Campaigns</h1>
          <p className="text-gray-600 mt-1">Engage your students with targeted campaigns</p>
        </div>
        
        <button
          onClick={() => setShowCreateModal(true)}
          className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors flex items-center"
        >
          <Plus className="h-4 w-4 mr-2" />
          Create Campaign
        </button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-white rounded-xl shadow-sm border p-6"
        >
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Total Sent</p>
              <p className="text-2xl font-bold text-gray-900 mt-1">
                {stats.totalSent.toLocaleString()}
              </p>
              <p className="text-xs text-gray-500 mt-1">This month</p>
            </div>
            <div className="h-12 w-12 bg-blue-100 rounded-lg flex items-center justify-center">
              <Send className="h-6 w-6 text-blue-600" />
            </div>
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="bg-white rounded-xl shadow-sm border p-6"
        >
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Open Rate</p>
              <p className="text-2xl font-bold text-gray-900 mt-1">{stats.avgOpenRate}%</p>
              <p className="text-xs text-green-600 mt-1">↑ 5% from last month</p>
            </div>
            <div className="h-12 w-12 bg-green-100 rounded-lg flex items-center justify-center">
              <Eye className="h-6 w-6 text-green-600" />
            </div>
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="bg-white rounded-xl shadow-sm border p-6"
        >
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Click Rate</p>
              <p className="text-2xl font-bold text-gray-900 mt-1">{stats.avgClickRate}%</p>
              <p className="text-xs text-green-600 mt-1">↑ 3% from last month</p>
            </div>
            <div className="h-12 w-12 bg-purple-100 rounded-lg flex items-center justify-center">
              <Target className="h-6 w-6 text-purple-600" />
            </div>
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="bg-white rounded-xl shadow-sm border p-6"
        >
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Revenue</p>
              <p className="text-2xl font-bold text-gray-900 mt-1">
                ${stats.totalRevenue.toLocaleString()}
              </p>
              <p className="text-xs text-gray-500 mt-1">From campaigns</p>
            </div>
            <div className="h-12 w-12 bg-yellow-100 rounded-lg flex items-center justify-center">
              <DollarSign className="h-6 w-6 text-yellow-600" />
            </div>
          </div>
        </motion.div>
      </div>

      {/* Tabs */}
      <div className="bg-white rounded-lg border">
        <div className="flex border-b overflow-x-auto">
          {tabs.map((tab) => {
            const Icon = tab.icon;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`flex items-center gap-2 px-6 py-3 border-b-2 transition-colors whitespace-nowrap ${
                  activeTab === tab.id
                    ? 'border-blue-600 text-blue-600 bg-blue-50'
                    : 'border-transparent text-gray-600 hover:text-gray-900'
                }`}
              >
                <Icon className="h-4 w-4" />
                <span className="font-medium">{tab.label}</span>
              </button>
            );
          })}
        </div>

        {/* Campaigns Tab */}
        {activeTab === 'campaigns' && (
          <div className="p-6">
            {/* Filters */}
            <div className="flex flex-col lg:flex-row gap-4 mb-6">
              <div className="flex-1 relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
                <input
                  type="text"
                  placeholder="Search campaigns..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
              
              <select
                value={filterStatus}
                onChange={(e) => setFilterStatus(e.target.value)}
                className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              >
                <option value="all">All Status</option>
                <option value="draft">Draft</option>
                <option value="scheduled">Scheduled</option>
                <option value="active">Active</option>
                <option value="paused">Paused</option>
                <option value="completed">Completed</option>
              </select>
            </div>

            {/* Campaign List */}
            <div className="space-y-4">
              {filteredCampaigns.map((campaign) => (
                <motion.div
                  key={campaign.id}
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  className="bg-white border rounded-lg p-6 hover:shadow-md transition-shadow"
                >
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <div className="flex items-center gap-3 mb-2">
                        <h3 className="font-semibold text-gray-900">{campaign.name}</h3>
                        <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                          campaign.status === 'active' ? 'bg-green-100 text-green-700' :
                          campaign.status === 'scheduled' ? 'bg-blue-100 text-blue-700' :
                          campaign.status === 'paused' ? 'bg-yellow-100 text-yellow-700' :
                          campaign.status === 'completed' ? 'bg-gray-100 text-gray-700' :
                          'bg-gray-100 text-gray-600'
                        }`}>
                          {campaign.status}
                        </span>
                        <span className="px-2 py-1 text-xs font-medium rounded-full bg-purple-100 text-purple-700">
                          {campaign.type.toUpperCase()}
                        </span>
                      </div>
                      
                      <p className="text-sm text-gray-600 mb-3">{campaign.content.preview}</p>
                      
                      <div className="flex items-center gap-6 text-sm">
                        <span className="flex items-center text-gray-600">
                          <Users className="h-4 w-4 mr-1" />
                          {campaign.audience.count} recipients
                        </span>
                        <span className="flex items-center text-gray-600">
                          <Calendar className="h-4 w-4 mr-1" />
                          {new Date(campaign.schedule.sendAt || campaign.createdAt).toLocaleDateString()}
                        </span>
                        {campaign.performance.sent > 0 && (
                          <>
                            <span className="flex items-center text-gray-600">
                              <Mail className="h-4 w-4 mr-1" />
                              {Math.round((campaign.performance.opened / campaign.performance.sent) * 100)}% opened
                            </span>
                            <span className="flex items-center text-gray-600">
                              <Target className="h-4 w-4 mr-1" />
                              {Math.round((campaign.performance.clicked / campaign.performance.sent) * 100)}% clicked
                            </span>
                            {campaign.performance.revenue > 0 && (
                              <span className="flex items-center text-green-600 font-medium">
                                <DollarSign className="h-4 w-4 mr-1" />
                                ${campaign.performance.revenue.toLocaleString()}
                              </span>
                            )}
                          </>
                        )}
                      </div>
                    </div>
                    
                    <div className="flex items-center gap-2 ml-4">
                      {campaign.status === 'active' ? (
                        <button className="p-2 text-yellow-600 hover:bg-yellow-50 rounded-lg">
                          <Pause className="h-4 w-4" />
                        </button>
                      ) : campaign.status === 'paused' ? (
                        <button className="p-2 text-green-600 hover:bg-green-50 rounded-lg">
                          <Play className="h-4 w-4" />
                        </button>
                      ) : null}
                      
                      <button className="p-2 text-gray-600 hover:bg-gray-100 rounded-lg">
                        <Copy className="h-4 w-4" />
                      </button>
                      <button className="p-2 text-gray-600 hover:bg-gray-100 rounded-lg">
                        <Edit3 className="h-4 w-4" />
                      </button>
                      <button className="p-2 text-red-600 hover:bg-red-50 rounded-lg">
                        <Trash2 className="h-4 w-4" />
                      </button>
                    </div>
                  </div>
                </motion.div>
              ))}
            </div>

            {filteredCampaigns.length === 0 && (
              <div className="text-center py-12">
                <Megaphone className="h-16 w-16 text-gray-300 mx-auto mb-4" />
                <h3 className="text-lg font-medium text-gray-900 mb-2">No campaigns found</h3>
                <p className="text-gray-600 mb-4">
                  {searchTerm ? 'Try adjusting your search' : 'Create your first campaign to get started'}
                </p>
                <button
                  onClick={() => setShowCreateModal(true)}
                  className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                >
                  Create Campaign
                </button>
              </div>
            )}
          </div>
        )}

        {/* Automations Tab */}
        {activeTab === 'automations' && (
          <div className="p-6">
            <div className="space-y-4">
              {automations.map((automation) => (
                <div key={automation.id} className="bg-gray-50 rounded-lg p-6 border">
                  <div className="flex items-center justify-between">
                    <div>
                      <div className="flex items-center gap-3 mb-2">
                        <h3 className="font-semibold text-gray-900">{automation.name}</h3>
                        <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                          automation.status === 'active' 
                            ? 'bg-green-100 text-green-700'
                            : 'bg-gray-100 text-gray-700'
                        }`}>
                          {automation.status}
                        </span>
                      </div>
                      <div className="flex items-center gap-6 text-sm text-gray-600">
                        <span className="flex items-center">
                          <Zap className="h-4 w-4 mr-1" />
                          {automation.trigger}
                        </span>
                        <span className="flex items-center">
                          <Mail className="h-4 w-4 mr-1" />
                          {automation.emails} emails
                        </span>
                        <span className="flex items-center">
                          <Users className="h-4 w-4 mr-1" />
                          {automation.enrolled} enrolled
                        </span>
                        <span className="flex items-center text-green-600 font-medium">
                          <Target className="h-4 w-4 mr-1" />
                          {automation.conversion}% conversion
                        </span>
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      <button className="p-2 text-gray-600 hover:bg-gray-100 rounded-lg">
                        <Settings className="h-4 w-4" />
                      </button>
                      <button className="p-2 text-gray-600 hover:bg-gray-100 rounded-lg">
                        <Edit3 className="h-4 w-4" />
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>

            <button className="mt-6 w-full py-3 border-2 border-dashed border-gray-300 rounded-lg text-gray-600 hover:border-gray-400 hover:text-gray-700 transition-colors">
              <Plus className="h-5 w-5 mx-auto mb-1" />
              Create Automation
            </button>
          </div>
        )}

        {/* Templates Tab */}
        {activeTab === 'templates' && (
          <div className="p-6">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {templates.map((template) => (
                <div key={template.id} className="bg-white border rounded-lg p-4 hover:shadow-md transition-shadow cursor-pointer">
                  <div className="text-4xl mb-3">{template.thumbnail}</div>
                  <h3 className="font-semibold text-gray-900">{template.name}</h3>
                  <p className="text-sm text-gray-600 mb-2">{template.category}</p>
                  <div className="flex flex-wrap gap-1">
                    {template.variables.map((variable) => (
                      <span key={variable} className="px-2 py-1 text-xs bg-gray-100 text-gray-600 rounded">
                        {`{{${variable}}}`}
                      </span>
                    ))}
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Segments Tab */}
        {activeTab === 'segments' && (
          <div className="p-6">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {segments.map((segment) => (
                <div key={segment.id} className="bg-white border rounded-lg p-6">
                  <div className="flex items-center justify-between mb-3">
                    <h3 className="font-semibold text-gray-900">{segment.name}</h3>
                    {segment.growth !== 0 && (
                      <span className={`text-sm font-medium ${
                        segment.growth > 0 ? 'text-green-600' : 'text-red-600'
                      }`}>
                        {segment.growth > 0 ? '+' : ''}{segment.growth}%
                      </span>
                    )}
                  </div>
                  <p className="text-2xl font-bold text-gray-900 mb-1">{segment.count}</p>
                  <p className="text-sm text-gray-600">members</p>
                  <button className="mt-4 w-full py-2 bg-blue-50 text-blue-600 rounded-lg hover:bg-blue-100 transition-colors text-sm font-medium">
                    Create Campaign
                  </button>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Analytics Tab */}
        {activeTab === 'analytics' && (
          <div className="p-6">
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Performance Overview */}
              <div className="bg-white border rounded-lg p-6">
                <h3 className="text-lg font-semibold text-gray-900 mb-4">Performance Overview</h3>
                <div className="space-y-4">
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-gray-600">Email Delivery Rate</span>
                    <div className="flex items-center gap-2">
                      <div className="w-32 bg-gray-200 rounded-full h-2">
                        <div className="bg-green-500 h-2 rounded-full" style={{ width: '98%' }}></div>
                      </div>
                      <span className="text-sm font-medium">98%</span>
                    </div>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-gray-600">SMS Delivery Rate</span>
                    <div className="flex items-center gap-2">
                      <div className="w-32 bg-gray-200 rounded-full h-2">
                        <div className="bg-green-500 h-2 rounded-full" style={{ width: '95%' }}></div>
                      </div>
                      <span className="text-sm font-medium">95%</span>
                    </div>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-gray-600">Push Notification Rate</span>
                    <div className="flex items-center gap-2">
                      <div className="w-32 bg-gray-200 rounded-full h-2">
                        <div className="bg-blue-500 h-2 rounded-full" style={{ width: '72%' }}></div>
                      </div>
                      <span className="text-sm font-medium">72%</span>
                    </div>
                  </div>
                </div>
              </div>

              {/* Top Performing Campaigns */}
              <div className="bg-white border rounded-lg p-6">
                <h3 className="text-lg font-semibold text-gray-900 mb-4">Top Campaigns</h3>
                <div className="space-y-3">
                  {[
                    { name: 'Summer Yoga Challenge', revenue: 2450, roi: 324 },
                    { name: 'New Member Welcome', revenue: 1890, roi: 256 },
                    { name: 'Flash Sale Friday', revenue: 1567, roi: 189 }
                  ].map((item, index) => (
                    <div key={index} className="flex items-center justify-between">
                      <div className="flex items-center gap-3">
                        <div className={`h-8 w-8 rounded-full bg-gradient-to-r ${
                          index === 0 ? 'from-yellow-400 to-yellow-600' :
                          index === 1 ? 'from-gray-300 to-gray-500' :
                          'from-orange-400 to-orange-600'
                        } flex items-center justify-center text-white text-xs font-bold`}>
                          {index + 1}
                        </div>
                        <div>
                          <p className="text-sm font-medium text-gray-900">{item.name}</p>
                          <p className="text-xs text-gray-600">${item.revenue} revenue</p>
                        </div>
                      </div>
                      <span className="text-sm font-medium text-green-600">{item.roi}% ROI</span>
                    </div>
                  ))}
                </div>
              </div>

              {/* Engagement Trends */}
              <div className="bg-gradient-to-br from-blue-50 to-indigo-50 border border-blue-200 rounded-lg p-6">
                <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
                  <TrendingUp className="h-5 w-5 mr-2 text-blue-600" />
                  Engagement Insights
                </h3>
                <div className="space-y-3">
                  <div className="flex items-start gap-3">
                    <CheckCircle className="h-5 w-5 text-green-600 mt-0.5" />
                    <div>
                      <p className="text-sm font-medium text-gray-900">Best send time</p>
                      <p className="text-xs text-gray-600">Tuesday & Thursday, 10 AM</p>
                    </div>
                  </div>
                  <div className="flex items-start gap-3">
                    <Star className="h-5 w-5 text-yellow-600 mt-0.5" />
                    <div>
                      <p className="text-sm font-medium text-gray-900">Top performing subject line</p>
                      <p className="text-xs text-gray-600">Personal name + emoji = 45% open rate</p>
                    </div>
                  </div>
                  <div className="flex items-start gap-3">
                    <Gift className="h-5 w-5 text-purple-600 mt-0.5" />
                    <div>
                      <p className="text-sm font-medium text-gray-900">Most effective offer</p>
                      <p className="text-xs text-gray-600">{isCreditsEnabled ? 'Free credits' : 'BOGO classes'} drive 3x conversions</p>
                    </div>
                  </div>
                </div>
              </div>

              {/* Subscriber Growth */}
              <div className="bg-white border rounded-lg p-6">
                <h3 className="text-lg font-semibold text-gray-900 mb-4">Subscriber Growth</h3>
                <div className="space-y-3">
                  <div className="flex items-center justify-between py-2 border-b">
                    <span className="text-sm text-gray-600">Total Subscribers</span>
                    <span className="font-medium text-gray-900">1,247</span>
                  </div>
                  <div className="flex items-center justify-between py-2 border-b">
                    <span className="text-sm text-gray-600">New This Month</span>
                    <span className="font-medium text-green-600">+89</span>
                  </div>
                  <div className="flex items-center justify-between py-2 border-b">
                    <span className="text-sm text-gray-600">Unsubscribed</span>
                    <span className="font-medium text-red-600">-12</span>
                  </div>
                  <div className="flex items-center justify-between py-2">
                    <span className="text-sm text-gray-600">Growth Rate</span>
                    <span className="font-medium text-green-600">+6.2%</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Create Campaign Modal */}
      <AnimatePresence>
        {showCreateModal && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4"
            onClick={() => setShowCreateModal(false)}
          >
            <motion.div
              initial={{ scale: 0.95, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.95, opacity: 0 }}
              className="bg-white rounded-xl shadow-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto"
              onClick={(e) => e.stopPropagation()}
            >
              <div className="p-6 border-b">
                <h2 className="text-xl font-bold text-gray-900">Create New Campaign</h2>
                <p className="text-sm text-gray-600 mt-1">Choose how you want to reach your audience</p>
              </div>

              <div className="p-6">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
                  {[
                    { 
                      icon: Mail, 
                      title: 'Email Campaign', 
                      description: 'Send beautiful emails to your subscribers',
                      color: 'blue'
                    },
                    { 
                      icon: MessageSquare, 
                      title: 'SMS Campaign', 
                      description: 'Quick text messages for urgent updates',
                      color: 'green'
                    },
                    { 
                      icon: Smartphone, 
                      title: 'Push Notification', 
                      description: 'Instant app notifications',
                      color: 'purple'
                    },
                    { 
                      icon: Globe, 
                      title: 'Multi-Channel', 
                      description: 'Combine email, SMS, and push',
                      color: 'orange'
                    }
                  ].map((option) => {
                    const Icon = option.icon;
                    return (
                      <button
                        key={option.title}
                        className={`p-6 border-2 rounded-lg hover:border-${option.color}-500 hover:bg-${option.color}-50 transition-all text-left`}
                      >
                        <Icon className={`h-8 w-8 text-${option.color}-600 mb-3`} />
                        <h3 className="font-semibold text-gray-900">{option.title}</h3>
                        <p className="text-sm text-gray-600 mt-1">{option.description}</p>
                      </button>
                    );
                  })}
                </div>

                <div className="pt-4 border-t flex items-center justify-between">
                  <button
                    onClick={() => setShowCreateModal(false)}
                    className="px-4 py-2 text-gray-700 hover:text-gray-900"
                  >
                    Cancel
                  </button>
                  <button
                    onClick={() => setShowCreateModal(false)}
                    className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                  >
                    Continue
                  </button>
                </div>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}