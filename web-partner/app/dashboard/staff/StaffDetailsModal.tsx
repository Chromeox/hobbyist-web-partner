'use client'

import React, { useState } from 'react';
import { motion } from 'framer-motion';
import {
  X, Star, Calendar, Clock, DollarSign, TrendingUp,
  Award, Target, Users, CheckCircle, AlertCircle,
  BarChart3, Wallet, CreditCard, PieChart
} from 'lucide-react';

interface StaffDetailsModalProps {
  onClose: () => void;
  staff: any;
  onUpdate?: (staffData: any) => void;
}

export default function StaffDetailsModal({ onClose, staff, onUpdate }: StaffDetailsModalProps) {
  const [activeTab, setActiveTab] = useState('overview');

  const tabs = [
    { id: 'overview', label: 'Overview', icon: Users },
    { id: 'payroll', label: 'Payroll', icon: DollarSign },
    { id: 'performance', label: 'Performance', icon: TrendingUp },
    { id: 'schedule', label: 'Schedule', icon: Calendar },
  ];

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4"
      onClick={onClose}
    >
      <motion.div
        initial={{ scale: 0.95, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        exit={{ scale: 0.95, opacity: 0 }}
        className="bg-white rounded-xl shadow-xl max-w-4xl w-full max-h-[90vh] overflow-hidden"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b bg-gradient-to-r from-blue-50 to-indigo-50">
          <div className="flex items-center gap-4">
            <div className="h-12 w-12 rounded-full bg-gradient-to-r from-blue-500 to-purple-600 flex items-center justify-center text-white font-semibold">
              {staff.firstName.charAt(0)}{staff.lastName.charAt(0)}
            </div>
            <div>
              <h2 className="text-xl font-bold text-gray-900">
                {staff.firstName} {staff.lastName}
              </h2>
              <p className="text-sm text-gray-600">{staff.email}</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <X className="h-5 w-5 text-gray-500" />
          </button>
        </div>

        {/* Tabs */}
        <div className="flex border-b px-6">
          {tabs.map((tab) => {
            const Icon = tab.icon;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`flex items-center gap-2 px-4 py-3 border-b-2 transition-colors ${
                  activeTab === tab.id
                    ? 'border-blue-600 text-blue-600'
                    : 'border-transparent text-gray-600 hover:text-gray-900'
                }`}
              >
                <Icon className="h-4 w-4" />
                <span className="font-medium">{tab.label}</span>
              </button>
            );
          })}
        </div>

        {/* Content */}
        <div className="p-6 overflow-y-auto max-h-[60vh]">
          {/* Overview Tab */}
          {activeTab === 'overview' && (
            <div className="space-y-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <h3 className="text-sm font-medium text-gray-600 mb-2">Basic Information</h3>
                  <div className="bg-gray-50 rounded-lg p-4 space-y-3">
                    <div className="flex justify-between">
                      <span className="text-sm text-gray-600">Role</span>
                      <span className="px-2 py-1 text-sm font-medium rounded-full bg-blue-100 text-blue-700">
                        {staff.role}
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-sm text-gray-600">Status</span>
                      <span className={`px-2 py-1 text-sm font-medium rounded-full ${
                        staff.status === 'active' ? 'bg-green-100 text-green-700' :
                        staff.status === 'pending' ? 'bg-yellow-100 text-yellow-700' :
                        'bg-gray-100 text-gray-700'
                      }`}>
                        {staff.status}
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-sm text-gray-600">Join Date</span>
                      <span className="text-sm font-medium text-gray-900">{staff.joinDate}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-sm text-gray-600">Phone</span>
                      <span className="text-sm font-medium text-gray-900">{staff.phone}</span>
                    </div>
                  </div>
                </div>

                <div>
                  <h3 className="text-sm font-medium text-gray-600 mb-2">Class Information</h3>
                  <div className="bg-gray-50 rounded-lg p-4 space-y-3">
                    <div className="flex justify-between">
                      <span className="text-sm text-gray-600">Total Classes</span>
                      <span className="text-sm font-medium text-gray-900">{staff.totalClasses}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-sm text-gray-600">Rating</span>
                      <div className="flex items-center">
                        <Star className="h-4 w-4 text-yellow-500 mr-1" />
                        <span className="text-sm font-medium text-gray-900">{staff.rating}</span>
                        <span className="text-sm text-gray-500 ml-1">({staff.reviewCount} reviews)</span>
                      </div>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-sm text-gray-600">Next Class</span>
                      <span className="text-sm font-medium text-gray-900">{staff.nextClass}</span>
                    </div>
                  </div>
                </div>
              </div>

              <div>
                <h3 className="text-sm font-medium text-gray-600 mb-2">Specialties</h3>
                <div className="flex flex-wrap gap-2">
                  {staff.specialties.map((specialty: string) => (
                    <span
                      key={specialty}
                      className="px-3 py-1 bg-blue-100 text-blue-700 rounded-full text-sm font-medium"
                    >
                      {specialty}
                    </span>
                  ))}
                </div>
              </div>

              <div>
                <h3 className="text-sm font-medium text-gray-600 mb-2">Permissions</h3>
                <div className="bg-gray-50 rounded-lg p-4">
                  <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
                    {Object.entries(staff.permissions).map(([key, value]) => (
                      <div key={key} className="flex items-center gap-2">
                        {value ? (
                          <CheckCircle className="h-4 w-4 text-green-600" />
                        ) : (
                          <X className="h-4 w-4 text-gray-400" />
                        )}
                        <span className={`text-sm ${value ? 'text-gray-900' : 'text-gray-400'}`}>
                          {key.replace(/([A-Z])/g, ' $1').trim()}
                        </span>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* Payroll Tab */}
          {activeTab === 'payroll' && staff.payroll && (
            <div className="space-y-6">
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div className="bg-gradient-to-br from-green-50 to-emerald-50 rounded-lg p-4">
                  <div className="flex items-center justify-between mb-2">
                    <Wallet className="h-8 w-8 text-green-600" />
                    <span className="text-xs text-green-600 font-medium">This Month</span>
                  </div>
                  <p className="text-2xl font-bold text-gray-900">
                    ${staff.payroll.monthlyEarnings.toLocaleString()}
                  </p>
                  <p className="text-sm text-gray-600 mt-1">Monthly Earnings</p>
                </div>

                <div className="bg-gradient-to-br from-blue-50 to-indigo-50 rounded-lg p-4">
                  <div className="flex items-center justify-between mb-2">
                    <CreditCard className="h-8 w-8 text-blue-600" />
                    <span className="text-xs text-blue-600 font-medium">All Time</span>
                  </div>
                  <p className="text-2xl font-bold text-gray-900">
                    ${staff.payroll.totalEarnings.toLocaleString()}
                  </p>
                  <p className="text-sm text-gray-600 mt-1">Total Earnings</p>
                </div>

                <div className="bg-gradient-to-br from-purple-50 to-pink-50 rounded-lg p-4">
                  <div className="flex items-center justify-between mb-2">
                    <Clock className="h-8 w-8 text-purple-600" />
                    <span className="text-xs text-purple-600 font-medium">This Month</span>
                  </div>
                  <p className="text-2xl font-bold text-gray-900">{staff.payroll.hoursWorked}</p>
                  <p className="text-sm text-gray-600 mt-1">Hours Worked</p>
                </div>
              </div>

              <div className="bg-gray-50 rounded-lg p-4">
                <h3 className="text-sm font-medium text-gray-900 mb-3">Payroll Details</h3>
                <div className="space-y-3">
                  <div className="flex justify-between items-center">
                    <span className="text-sm text-gray-600">Commission Rate</span>
                    <span className="text-sm font-medium text-gray-900">{staff.payroll.commissionRate}%</span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-sm text-gray-600">Bonus Eligible</span>
                    <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                      staff.payroll.bonusEligible 
                        ? 'bg-green-100 text-green-700'
                        : 'bg-gray-100 text-gray-700'
                    }`}>
                      {staff.payroll.bonusEligible ? 'Yes' : 'No'}
                    </span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-sm text-gray-600">Next Pay Date</span>
                    <span className="text-sm font-medium text-gray-900">{staff.payroll.nextPayDate}</span>
                  </div>
                </div>
              </div>

              <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
                <div className="flex items-start gap-3">
                  <AlertCircle className="h-5 w-5 text-yellow-600 mt-0.5" />
                  <div>
                    <h4 className="text-sm font-medium text-yellow-900">Payment Method</h4>
                    <p className="text-sm text-yellow-700 mt-1">
                      Direct deposit to account ending in ****4567
                    </p>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* Performance Tab */}
          {activeTab === 'performance' && staff.performance && (
            <div className="space-y-6">
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                <div className="bg-white border rounded-lg p-4">
                  <div className="flex items-center justify-between mb-2">
                    <Users className="h-5 w-5 text-gray-400" />
                    <span className={`text-xs font-medium ${
                      staff.performance.attendanceRate >= 90 ? 'text-green-600' : 'text-yellow-600'
                    }`}>
                      {staff.performance.attendanceRate}%
                    </span>
                  </div>
                  <p className="text-sm font-medium text-gray-900">Attendance</p>
                  <div className="mt-2 bg-gray-200 rounded-full h-2">
                    <div
                      className={`h-2 rounded-full ${
                        staff.performance.attendanceRate >= 90 ? 'bg-green-500' : 'bg-yellow-500'
                      }`}
                      style={{ width: `${staff.performance.attendanceRate}%` }}
                    />
                  </div>
                </div>

                <div className="bg-white border rounded-lg p-4">
                  <div className="flex items-center justify-between mb-2">
                    <Award className="h-5 w-5 text-gray-400" />
                    <span className={`text-xs font-medium ${
                      staff.performance.studentRetention >= 85 ? 'text-green-600' : 'text-yellow-600'
                    }`}>
                      {staff.performance.studentRetention}%
                    </span>
                  </div>
                  <p className="text-sm font-medium text-gray-900">Retention</p>
                  <div className="mt-2 bg-gray-200 rounded-full h-2">
                    <div
                      className={`h-2 rounded-full ${
                        staff.performance.studentRetention >= 85 ? 'bg-green-500' : 'bg-yellow-500'
                      }`}
                      style={{ width: `${staff.performance.studentRetention}%` }}
                    />
                  </div>
                </div>

                <div className="bg-white border rounded-lg p-4">
                  <div className="flex items-center justify-between mb-2">
                    <BarChart3 className="h-5 w-5 text-gray-400" />
                    <span className={`text-xs font-medium ${
                      staff.performance.classCapacityAvg >= 75 ? 'text-green-600' : 'text-yellow-600'
                    }`}>
                      {staff.performance.classCapacityAvg}%
                    </span>
                  </div>
                  <p className="text-sm font-medium text-gray-900">Capacity</p>
                  <div className="mt-2 bg-gray-200 rounded-full h-2">
                    <div
                      className={`h-2 rounded-full ${
                        staff.performance.classCapacityAvg >= 75 ? 'bg-green-500' : 'bg-yellow-500'
                      }`}
                      style={{ width: `${staff.performance.classCapacityAvg}%` }}
                    />
                  </div>
                </div>

                <div className="bg-white border rounded-lg p-4">
                  <div className="flex items-center justify-between mb-2">
                    <X className="h-5 w-5 text-gray-400" />
                    <span className={`text-xs font-medium ${
                      staff.performance.cancellationRate <= 5 ? 'text-green-600' : 'text-red-600'
                    }`}>
                      {staff.performance.cancellationRate}%
                    </span>
                  </div>
                  <p className="text-sm font-medium text-gray-900">Cancellation</p>
                  <div className="mt-2 bg-gray-200 rounded-full h-2">
                    <div
                      className={`h-2 rounded-full ${
                        staff.performance.cancellationRate <= 5 ? 'bg-green-500' : 'bg-red-500'
                      }`}
                      style={{ width: `${staff.performance.cancellationRate}%` }}
                    />
                  </div>
                </div>
              </div>

              <div className="bg-gradient-to-r from-blue-50 to-indigo-50 rounded-lg p-6">
                <div className="flex items-center justify-between mb-4">
                  <div>
                    <h3 className="text-lg font-semibold text-gray-900">Monthly Goal Progress</h3>
                    <p className="text-sm text-gray-600">Target: ${staff.performance.monthlyGoal.toLocaleString()}</p>
                  </div>
                  <Target className="h-8 w-8 text-blue-600" />
                </div>
                <div className="mb-2">
                  <div className="flex justify-between text-sm mb-1">
                    <span className="text-gray-600">Current Progress</span>
                    <span className="font-medium text-gray-900">
                      ${staff.performance.currentProgress.toLocaleString()} / ${staff.performance.monthlyGoal.toLocaleString()}
                    </span>
                  </div>
                  <div className="bg-white rounded-full h-3">
                    <div
                      className="h-3 rounded-full bg-gradient-to-r from-blue-500 to-indigo-500"
                      style={{ width: `${(staff.performance.currentProgress / staff.performance.monthlyGoal) * 100}%` }}
                    />
                  </div>
                </div>
                <p className="text-sm text-gray-600">
                  {Math.round((staff.performance.currentProgress / staff.performance.monthlyGoal) * 100)}% of monthly goal achieved
                </p>
              </div>
            </div>
          )}

          {/* Schedule Tab */}
          {activeTab === 'schedule' && staff.schedule && (
            <div className="space-y-6">
              <div>
                <h3 className="text-sm font-medium text-gray-600 mb-3">Upcoming Classes</h3>
                <div className="space-y-3">
                  {staff.schedule.upcoming.map((session: any, index: number) => (
                    <div key={index} className="bg-white border rounded-lg p-4">
                      <div className="flex items-center justify-between">
                        <div>
                          <h4 className="font-medium text-gray-900">{session.className}</h4>
                          <div className="flex items-center gap-4 mt-1">
                            <span className="text-sm text-gray-600 flex items-center">
                              <Calendar className="h-4 w-4 mr-1" />
                              {session.date}
                            </span>
                            <span className="text-sm text-gray-600 flex items-center">
                              <Clock className="h-4 w-4 mr-1" />
                              {session.time}
                            </span>
                            <span className="text-sm text-gray-600 flex items-center">
                              <Users className="h-4 w-4 mr-1" />
                              {session.enrolled}/{session.capacity}
                            </span>
                          </div>
                        </div>
                        <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                          session.status === 'confirmed' 
                            ? 'bg-green-100 text-green-700'
                            : 'bg-yellow-100 text-yellow-700'
                        }`}>
                          {session.status}
                        </span>
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              <div>
                <h3 className="text-sm font-medium text-gray-600 mb-3">Weekly Availability</h3>
                <div className="bg-gray-50 rounded-lg p-4">
                  <div className="grid grid-cols-7 gap-2 text-center">
                    {['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day, index) => (
                      <div key={day} className="space-y-2">
                        <p className="text-xs font-medium text-gray-600">{day}</p>
                        <div className={`p-2 rounded ${
                          staff.schedule.availability[index] 
                            ? 'bg-green-100 text-green-700'
                            : 'bg-gray-200 text-gray-400'
                        }`}>
                          <CheckCircle className="h-4 w-4 mx-auto" />
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>

              <div>
                <h3 className="text-sm font-medium text-gray-600 mb-3">Preferred Time Slots</h3>
                <div className="flex flex-wrap gap-2">
                  {staff.schedule.preferredSlots.map((slot: string) => (
                    <span
                      key={slot}
                      className="px-3 py-1 bg-blue-100 text-blue-700 rounded-full text-sm font-medium"
                    >
                      {slot}
                    </span>
                  ))}
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="px-6 py-4 border-t bg-gray-50 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <span className="text-sm text-gray-600">Last updated:</span>
            <span className="text-sm font-medium text-gray-900">2 hours ago</span>
          </div>
          <div className="flex items-center gap-3">
            <button
              onClick={onClose}
              className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
            >
              Close
            </button>
            <button
              onClick={() => onUpdate && onUpdate(staff)}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
            >
              Save Changes
            </button>
          </div>
        </div>
      </motion.div>
    </motion.div>
  );
}