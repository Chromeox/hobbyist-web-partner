'use client';

import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Users, Clock, Calendar, CheckCircle, X, AlertCircle,
  Send, Phone, Mail, MessageSquare, TrendingUp, Filter,
  Search, Settings, Bell, Zap, RefreshCw, UserPlus,
  ChevronRight, Activity, Target, Award
} from 'lucide-react';
import { usePaymentModel } from '@/lib/contexts/PaymentModelContext';

interface WaitlistEntry {
  id: string;
  studentId: string;
  studentName: string;
  studentEmail: string;
  studentPhone: string;
  classId: string;
  className: string;
  classDate: string;
  classTime: string;
  position: number;
  joinedAt: string;
  notificationPreference: 'email' | 'sms' | 'both' | 'app';
  creditBalance?: number;
  priority: 'standard' | 'vip' | 'premium';
  autoEnroll: boolean;
  expiresAt?: string;
}

interface WaitlistSettings {
  autoPromote: boolean;
  promotionWindow: number; // hours before class
  expirationTime: number; // hours to respond
  maxWaitlistSize: number;
  priorityRules: {
    vipFirst: boolean;
    creditBalanceRequired: boolean;
    loyaltyBonus: boolean;
  };
  notifications: {
    sendPromotionAlert: boolean;
    sendReminder: boolean;
    sendExpiration: boolean;
  };
}

export default function WaitlistManagement() {
  const { isCreditsEnabled } = usePaymentModel();
  const [activeTab, setActiveTab] = useState('current');
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedClass, setSelectedClass] = useState('all');
  const [selectedDate, setSelectedDate] = useState('all');
  const [showSettings, setShowSettings] = useState(false);
  
  const [waitlistEntries, setWaitlistEntries] = useState<WaitlistEntry[]>([
    {
      id: '1',
      studentId: 'stu_1',
      studentName: 'Emma Wilson',
      studentEmail: 'emma@example.com',
      studentPhone: '+1 (555) 123-4567',
      classId: 'class_1',
      className: 'Morning Yoga Flow',
      classDate: '2025-08-10',
      classTime: '09:00',
      position: 1,
      joinedAt: '2025-08-08T14:30:00Z',
      notificationPreference: 'both',
      creditBalance: 15,
      priority: 'vip',
      autoEnroll: true
    },
    {
      id: '2',
      studentId: 'stu_2',
      studentName: 'James Chen',
      studentEmail: 'james@example.com',
      studentPhone: '+1 (555) 234-5678',
      classId: 'class_1',
      className: 'Morning Yoga Flow',
      classDate: '2025-08-10',
      classTime: '09:00',
      position: 2,
      joinedAt: '2025-08-08T15:00:00Z',
      notificationPreference: 'email',
      creditBalance: 8,
      priority: 'standard',
      autoEnroll: true
    },
    {
      id: '3',
      studentId: 'stu_3',
      studentName: 'Sofia Martinez',
      studentEmail: 'sofia@example.com',
      studentPhone: '+1 (555) 345-6789',
      classId: 'class_2',
      className: 'Advanced Pilates',
      classDate: '2025-08-11',
      classTime: '18:00',
      position: 1,
      joinedAt: '2025-08-08T16:00:00Z',
      notificationPreference: 'sms',
      creditBalance: 25,
      priority: 'premium',
      autoEnroll: false
    }
  ]);

  const [settings, setSettings] = useState<WaitlistSettings>({
    autoPromote: true,
    promotionWindow: 24,
    expirationTime: 2,
    maxWaitlistSize: 10,
    priorityRules: {
      vipFirst: true,
      creditBalanceRequired: true,
      loyaltyBonus: true
    },
    notifications: {
      sendPromotionAlert: true,
      sendReminder: true,
      sendExpiration: true
    }
  });

  // Statistics
  const stats = {
    totalWaitlisted: waitlistEntries.length,
    autoPromotions: 12,
    avgWaitTime: '3.5 hours',
    conversionRate: 78
  };

  const handlePromoteStudent = (entry: WaitlistEntry) => {
    // Simulate promoting student to class
    alert(`Promoting ${entry.studentName} to ${entry.className}`);
    setWaitlistEntries(prev => prev.filter(e => e.id !== entry.id));
  };

  const handleRemoveFromWaitlist = (entryId: string) => {
    setWaitlistEntries(prev => prev.filter(e => e.id !== entryId));
  };

  const handleSendNotification = (entry: WaitlistEntry) => {
    alert(`Sending notification to ${entry.studentName} via ${entry.notificationPreference}`);
  };

  const filteredEntries = waitlistEntries.filter(entry => {
    const matchesSearch = entry.studentName.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         entry.className.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesClass = selectedClass === 'all' || entry.classId === selectedClass;
    const matchesDate = selectedDate === 'all' || entry.classDate === selectedDate;
    
    return matchesSearch && matchesClass && matchesDate;
  });

  const tabs = [
    { id: 'current', label: 'Current Waitlist', icon: Users, count: filteredEntries.length },
    { id: 'automation', label: 'Automation Rules', icon: Zap },
    { id: 'analytics', label: 'Analytics', icon: TrendingUp }
  ];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Waitlist Management</h1>
          <p className="text-gray-600 mt-1">Automate class enrollment and maximize capacity</p>
        </div>
        
        <button
          onClick={() => setShowSettings(!showSettings)}
          className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors flex items-center"
        >
          <Settings className="h-4 w-4 mr-2" />
          Settings
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
              <p className="text-sm font-medium text-gray-600">Currently Waitlisted</p>
              <p className="text-2xl font-bold text-gray-900 mt-1">{stats.totalWaitlisted}</p>
              <p className="text-xs text-gray-500 mt-1">Across all classes</p>
            </div>
            <div className="h-12 w-12 bg-blue-100 rounded-lg flex items-center justify-center">
              <Users className="h-6 w-6 text-blue-600" />
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
              <p className="text-sm font-medium text-gray-600">Auto-Promotions</p>
              <p className="text-2xl font-bold text-gray-900 mt-1">{stats.autoPromotions}</p>
              <p className="text-xs text-gray-500 mt-1">This week</p>
            </div>
            <div className="h-12 w-12 bg-green-100 rounded-lg flex items-center justify-center">
              <Zap className="h-6 w-6 text-green-600" />
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
              <p className="text-sm font-medium text-gray-600">Avg Wait Time</p>
              <p className="text-2xl font-bold text-gray-900 mt-1">{stats.avgWaitTime}</p>
              <p className="text-xs text-gray-500 mt-1">Until enrollment</p>
            </div>
            <div className="h-12 w-12 bg-purple-100 rounded-lg flex items-center justify-center">
              <Clock className="h-6 w-6 text-purple-600" />
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
              <p className="text-sm font-medium text-gray-600">Conversion Rate</p>
              <p className="text-2xl font-bold text-gray-900 mt-1">{stats.conversionRate}%</p>
              <p className="text-xs text-gray-500 mt-1">Waitlist to enrolled</p>
            </div>
            <div className="h-12 w-12 bg-yellow-100 rounded-lg flex items-center justify-center">
              <Target className="h-6 w-6 text-yellow-600" />
            </div>
          </div>
        </motion.div>
      </div>

      {/* Tabs */}
      <div className="bg-white rounded-lg border">
        <div className="flex border-b">
          {tabs.map((tab) => {
            const Icon = tab.icon;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`flex items-center gap-2 px-6 py-3 border-b-2 transition-colors ${
                  activeTab === tab.id
                    ? 'border-blue-600 text-blue-600 bg-blue-50'
                    : 'border-transparent text-gray-600 hover:text-gray-900'
                }`}
              >
                <Icon className="h-4 w-4" />
                <span className="font-medium">{tab.label}</span>
                {tab.count !== undefined && (
                  <span className="ml-2 px-2 py-0.5 text-xs font-medium rounded-full bg-gray-100 text-gray-600">
                    {tab.count}
                  </span>
                )}
              </button>
            );
          })}
        </div>

        {/* Current Waitlist Tab */}
        {activeTab === 'current' && (
          <div className="p-6">
            {/* Filters */}
            <div className="flex flex-col lg:flex-row gap-4 mb-6">
              <div className="flex-1 relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
                <input
                  type="text"
                  placeholder="Search by student or class name..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
              
              <select
                value={selectedClass}
                onChange={(e) => setSelectedClass(e.target.value)}
                className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              >
                <option value="all">All Classes</option>
                <option value="class_1">Morning Yoga Flow</option>
                <option value="class_2">Advanced Pilates</option>
              </select>
              
              <select
                value={selectedDate}
                onChange={(e) => setSelectedDate(e.target.value)}
                className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              >
                <option value="all">All Dates</option>
                <option value="2025-08-10">Aug 10, 2025</option>
                <option value="2025-08-11">Aug 11, 2025</option>
              </select>
            </div>

            {/* Waitlist Entries */}
            <div className="space-y-4">
              {filteredEntries.map((entry) => (
                <motion.div
                  key={entry.id}
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  className="bg-gray-50 rounded-lg p-4 border border-gray-200"
                >
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-4">
                      {/* Position Badge */}
                      <div className={`h-12 w-12 rounded-full flex items-center justify-center font-bold text-lg ${
                        entry.position === 1 ? 'bg-gold text-white' :
                        entry.position === 2 ? 'bg-silver text-white' :
                        entry.position === 3 ? 'bg-bronze text-white' :
                        'bg-gray-200 text-gray-700'
                      }`}
                        style={{
                          background: entry.position === 1 ? 'linear-gradient(135deg, #FFD700, #FFA500)' :
                                    entry.position === 2 ? 'linear-gradient(135deg, #C0C0C0, #808080)' :
                                    entry.position === 3 ? 'linear-gradient(135deg, #CD7F32, #8B4513)' :
                                    undefined
                        }}
                      >
                        #{entry.position}
                      </div>

                      {/* Student Info */}
                      <div>
                        <div className="flex items-center gap-2">
                          <h3 className="font-semibold text-gray-900">{entry.studentName}</h3>
                          {entry.priority !== 'standard' && (
                            <span className={`px-2 py-0.5 text-xs font-medium rounded-full ${
                              entry.priority === 'vip' ? 'bg-purple-100 text-purple-700' :
                              'bg-gold-100 text-gold-700'
                            }`}>
                              {entry.priority.toUpperCase()}
                            </span>
                          )}
                          {entry.autoEnroll && (
                            <span className="px-2 py-0.5 text-xs font-medium rounded-full bg-green-100 text-green-700">
                              AUTO-ENROLL
                            </span>
                          )}
                        </div>
                        <div className="flex items-center gap-4 mt-1 text-sm text-gray-600">
                          <span className="flex items-center">
                            <Mail className="h-3 w-3 mr-1" />
                            {entry.studentEmail}
                          </span>
                          <span className="flex items-center">
                            <Phone className="h-3 w-3 mr-1" />
                            {entry.studentPhone}
                          </span>
                          {isCreditsEnabled && entry.creditBalance !== undefined && (
                            <span className="flex items-center">
                              <CreditCard className="h-3 w-3 mr-1" />
                              {entry.creditBalance} credits
                            </span>
                          )}
                        </div>
                      </div>
                    </div>

                    {/* Class Info & Actions */}
                    <div className="flex items-center gap-6">
                      <div className="text-right">
                        <p className="font-medium text-gray-900">{entry.className}</p>
                        <div className="flex items-center gap-2 text-sm text-gray-600">
                          <Calendar className="h-3 w-3" />
                          <span>{entry.classDate}</span>
                          <Clock className="h-3 w-3 ml-1" />
                          <span>{entry.classTime}</span>
                        </div>
                      </div>

                      <div className="flex items-center gap-2">
                        <button
                          onClick={() => handlePromoteStudent(entry)}
                          className="p-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
                          title="Promote to class"
                        >
                          <UserPlus className="h-4 w-4" />
                        </button>
                        <button
                          onClick={() => handleSendNotification(entry)}
                          className="p-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                          title="Send notification"
                        >
                          <Send className="h-4 w-4" />
                        </button>
                        <button
                          onClick={() => handleRemoveFromWaitlist(entry.id)}
                          className="p-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
                          title="Remove from waitlist"
                        >
                          <X className="h-4 w-4" />
                        </button>
                      </div>
                    </div>
                  </div>

                  {/* Wait Time Info */}
                  <div className="mt-3 pt-3 border-t border-gray-200">
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-gray-600">
                        Joined waitlist: {new Date(entry.joinedAt).toLocaleString()}
                      </span>
                      <span className="flex items-center text-gray-600">
                        <Bell className="h-3 w-3 mr-1" />
                        Notification preference: {entry.notificationPreference}
                      </span>
                    </div>
                  </div>
                </motion.div>
              ))}
            </div>

            {filteredEntries.length === 0 && (
              <div className="text-center py-12">
                <Users className="h-16 w-16 text-gray-300 mx-auto mb-4" />
                <h3 className="text-lg font-medium text-gray-900 mb-2">No waitlist entries</h3>
                <p className="text-gray-600">
                  {searchTerm ? 'Try adjusting your search filters' : 'All classes have available spots'}
                </p>
              </div>
            )}
          </div>
        )}

        {/* Automation Rules Tab */}
        {activeTab === 'automation' && (
          <div className="p-6">
            <div className="space-y-6">
              {/* Auto-Promotion Settings */}
              <div className="bg-white border rounded-lg p-6">
                <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
                  <Zap className="h-5 w-5 mr-2 text-yellow-500" />
                  Auto-Promotion Settings
                </h3>
                
                <div className="space-y-4">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="font-medium text-gray-900">Enable Auto-Promotion</p>
                      <p className="text-sm text-gray-600">Automatically promote waitlisted students when spots open</p>
                    </div>
                    <label className="relative inline-flex items-center cursor-pointer">
                      <input
                        type="checkbox"
                        checked={settings.autoPromote}
                        onChange={(e) => setSettings({...settings, autoPromote: e.target.checked})}
                        className="sr-only peer"
                      />
                      <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                    </label>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Promotion Window (hours before class)
                    </label>
                    <input
                      type="number"
                      value={settings.promotionWindow}
                      onChange={(e) => setSettings({...settings, promotionWindow: parseInt(e.target.value)})}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Response Time Limit (hours)
                    </label>
                    <input
                      type="number"
                      value={settings.expirationTime}
                      onChange={(e) => setSettings({...settings, expirationTime: parseInt(e.target.value)})}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    />
                    <p className="text-xs text-gray-500 mt-1">
                      Time students have to confirm their spot before it's offered to the next person
                    </p>
                  </div>
                </div>
              </div>

              {/* Priority Rules */}
              <div className="bg-white border rounded-lg p-6">
                <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
                  <Award className="h-5 w-5 mr-2 text-purple-500" />
                  Priority Rules
                </h3>
                
                <div className="space-y-4">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="font-medium text-gray-900">VIP Priority</p>
                      <p className="text-sm text-gray-600">VIP members get priority on waitlists</p>
                    </div>
                    <label className="relative inline-flex items-center cursor-pointer">
                      <input
                        type="checkbox"
                        checked={settings.priorityRules.vipFirst}
                        onChange={(e) => setSettings({
                          ...settings,
                          priorityRules: {...settings.priorityRules, vipFirst: e.target.checked}
                        })}
                        className="sr-only peer"
                      />
                      <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                    </label>
                  </div>

                  {isCreditsEnabled && (
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="font-medium text-gray-900">Credit Balance Required</p>
                        <p className="text-sm text-gray-600">Only promote students with sufficient credits</p>
                      </div>
                      <label className="relative inline-flex items-center cursor-pointer">
                        <input
                          type="checkbox"
                          checked={settings.priorityRules.creditBalanceRequired}
                          onChange={(e) => setSettings({
                            ...settings,
                            priorityRules: {...settings.priorityRules, creditBalanceRequired: e.target.checked}
                          })}
                          className="sr-only peer"
                        />
                        <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                      </label>
                    </div>
                  )}

                  <div className="flex items-center justify-between">
                    <div>
                      <p className="font-medium text-gray-900">Loyalty Bonus</p>
                      <p className="text-sm text-gray-600">Give priority to long-term members</p>
                    </div>
                    <label className="relative inline-flex items-center cursor-pointer">
                      <input
                        type="checkbox"
                        checked={settings.priorityRules.loyaltyBonus}
                        onChange={(e) => setSettings({
                          ...settings,
                          priorityRules: {...settings.priorityRules, loyaltyBonus: e.target.checked}
                        })}
                        className="sr-only peer"
                      />
                      <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                    </label>
                  </div>
                </div>
              </div>

              {/* Notification Settings */}
              <div className="bg-white border rounded-lg p-6">
                <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
                  <Bell className="h-5 w-5 mr-2 text-blue-500" />
                  Notification Settings
                </h3>
                
                <div className="space-y-4">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="font-medium text-gray-900">Promotion Alerts</p>
                      <p className="text-sm text-gray-600">Notify students when promoted from waitlist</p>
                    </div>
                    <label className="relative inline-flex items-center cursor-pointer">
                      <input
                        type="checkbox"
                        checked={settings.notifications.sendPromotionAlert}
                        onChange={(e) => setSettings({
                          ...settings,
                          notifications: {...settings.notifications, sendPromotionAlert: e.target.checked}
                        })}
                        className="sr-only peer"
                      />
                      <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                    </label>
                  </div>

                  <div className="flex items-center justify-between">
                    <div>
                      <p className="font-medium text-gray-900">Reminder Notifications</p>
                      <p className="text-sm text-gray-600">Send reminders to confirm enrollment</p>
                    </div>
                    <label className="relative inline-flex items-center cursor-pointer">
                      <input
                        type="checkbox"
                        checked={settings.notifications.sendReminder}
                        onChange={(e) => setSettings({
                          ...settings,
                          notifications: {...settings.notifications, sendReminder: e.target.checked}
                        })}
                        className="sr-only peer"
                      />
                      <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                    </label>
                  </div>

                  <div className="flex items-center justify-between">
                    <div>
                      <p className="font-medium text-gray-900">Expiration Warnings</p>
                      <p className="text-sm text-gray-600">Warn before spot expires</p>
                    </div>
                    <label className="relative inline-flex items-center cursor-pointer">
                      <input
                        type="checkbox"
                        checked={settings.notifications.sendExpiration}
                        onChange={(e) => setSettings({
                          ...settings,
                          notifications: {...settings.notifications, sendExpiration: e.target.checked}
                        })}
                        className="sr-only peer"
                      />
                      <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                    </label>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Analytics Tab */}
        {activeTab === 'analytics' && (
          <div className="p-6">
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Waitlist Trends */}
              <div className="bg-white border rounded-lg p-6">
                <h3 className="text-lg font-semibold text-gray-900 mb-4">Waitlist Trends</h3>
                <div className="space-y-4">
                  <div className="flex items-center justify-between py-2 border-b">
                    <span className="text-sm text-gray-600">Average wait time</span>
                    <span className="font-medium text-gray-900">3.5 hours</span>
                  </div>
                  <div className="flex items-center justify-between py-2 border-b">
                    <span className="text-sm text-gray-600">Peak waitlist times</span>
                    <span className="font-medium text-gray-900">Mon-Wed 6-8pm</span>
                  </div>
                  <div className="flex items-center justify-between py-2 border-b">
                    <span className="text-sm text-gray-600">Most waitlisted class</span>
                    <span className="font-medium text-gray-900">Morning Yoga Flow</span>
                  </div>
                  <div className="flex items-center justify-between py-2">
                    <span className="text-sm text-gray-600">Auto-promotion success rate</span>
                    <span className="font-medium text-green-600">92%</span>
                  </div>
                </div>
              </div>

              {/* Conversion Metrics */}
              <div className="bg-white border rounded-lg p-6">
                <h3 className="text-lg font-semibold text-gray-900 mb-4">Conversion Metrics</h3>
                <div className="space-y-4">
                  <div className="flex items-center justify-between py-2 border-b">
                    <span className="text-sm text-gray-600">Waitlist to enrollment</span>
                    <span className="font-medium text-gray-900">78%</span>
                  </div>
                  <div className="flex items-center justify-between py-2 border-b">
                    <span className="text-sm text-gray-600">No-show after promotion</span>
                    <span className="font-medium text-red-600">8%</span>
                  </div>
                  <div className="flex items-center justify-between py-2 border-b">
                    <span className="text-sm text-gray-600">VIP conversion rate</span>
                    <span className="font-medium text-purple-600">95%</span>
                  </div>
                  <div className="flex items-center justify-between py-2">
                    <span className="text-sm text-gray-600">Revenue from waitlist</span>
                    <span className="font-medium text-green-600">$2,450/week</span>
                  </div>
                </div>
              </div>

              {/* Popular Classes */}
              <div className="bg-white border rounded-lg p-6">
                <h3 className="text-lg font-semibold text-gray-900 mb-4">Classes with Most Waitlists</h3>
                <div className="space-y-3">
                  {[
                    { name: 'Morning Yoga Flow', count: 45, trend: 'up' },
                    { name: 'Advanced Pilates', count: 32, trend: 'up' },
                    { name: 'HIIT Bootcamp', count: 28, trend: 'down' },
                    { name: 'Meditation & Mindfulness', count: 18, trend: 'up' },
                  ].map((item, index) => (
                    <div key={index} className="flex items-center justify-between">
                      <div className="flex items-center gap-3">
                        <div className={`h-8 w-8 rounded-full bg-gradient-to-r ${
                          index === 0 ? 'from-blue-500 to-purple-600' :
                          index === 1 ? 'from-green-500 to-teal-600' :
                          index === 2 ? 'from-orange-500 to-red-600' :
                          'from-pink-500 to-rose-600'
                        } flex items-center justify-center text-white text-xs font-bold`}>
                          {index + 1}
                        </div>
                        <span className="text-sm font-medium text-gray-900">{item.name}</span>
                      </div>
                      <div className="flex items-center gap-2">
                        <span className="text-sm text-gray-600">{item.count}</span>
                        {item.trend === 'up' ? (
                          <ChevronRight className="h-4 w-4 text-green-500 rotate-[-90deg]" />
                        ) : (
                          <ChevronRight className="h-4 w-4 text-red-500 rotate-90" />
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Optimization Suggestions */}
              <div className="bg-gradient-to-br from-blue-50 to-indigo-50 border border-blue-200 rounded-lg p-6">
                <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
                  <Activity className="h-5 w-5 mr-2 text-blue-600" />
                  Optimization Suggestions
                </h3>
                <div className="space-y-3">
                  <div className="flex items-start gap-3">
                    <CheckCircle className="h-5 w-5 text-green-600 mt-0.5" />
                    <div>
                      <p className="text-sm font-medium text-gray-900">Add morning yoga sessions</p>
                      <p className="text-xs text-gray-600">45 people waitlisted this week</p>
                    </div>
                  </div>
                  <div className="flex items-start gap-3">
                    <AlertCircle className="h-5 w-5 text-yellow-600 mt-0.5" />
                    <div>
                      <p className="text-sm font-medium text-gray-900">Increase HIIT class capacity</p>
                      <p className="text-xs text-gray-600">Room can accommodate 5 more</p>
                    </div>
                  </div>
                  <div className="flex items-start gap-3">
                    <Target className="h-5 w-5 text-blue-600 mt-0.5" />
                    <div>
                      <p className="text-sm font-medium text-gray-900">Launch premium waitlist tier</p>
                      <p className="text-xs text-gray-600">Potential $500/month revenue</p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Settings Modal */}
      <AnimatePresence>
        {showSettings && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4"
            onClick={() => setShowSettings(false)}
          >
            <motion.div
              initial={{ scale: 0.95, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.95, opacity: 0 }}
              className="bg-white rounded-xl shadow-xl max-w-md w-full p-6"
              onClick={(e) => e.stopPropagation()}
            >
              <h2 className="text-xl font-bold text-gray-900 mb-4">Waitlist Settings</h2>
              
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Maximum Waitlist Size
                  </label>
                  <input
                    type="number"
                    value={settings.maxWaitlistSize}
                    onChange={(e) => setSettings({...settings, maxWaitlistSize: parseInt(e.target.value)})}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  />
                </div>

                <div className="pt-4 border-t">
                  <button
                    onClick={() => setShowSettings(false)}
                    className="w-full px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                  >
                    Save Settings
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