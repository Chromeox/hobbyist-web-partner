'use client';

import React, { useState, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  X,
  Calendar,
  Clock,
  Users,
  User,
  Mail,
  Phone,
  MapPin,
  DollarSign,
  AlertCircle,
  CheckCircle,
  Plus,
  ArrowUpCircle,
  ArrowDownCircle,
  Search,
  Download,
  MessageSquare,
  Bell,
  Settings,
  MoreVertical,
  Trash2
} from 'lucide-react';
import type {
  Student,
  BookingDetails,
  WaitlistEntry,
  ClassSession,
  SessionManagementProps
} from '../../../types/class-management';
import {
  getStatusColor,
  getPaymentStatusColor,
  formatTime,
  formatDate,
  formatDateTime,
  searchFilter,
  modalVariants
} from '../../../lib/utils/class-management-utils';

// Mock data - in production this would come from API

const mockStudents: Student[] = [
  {
    id: 'student_1',
    name: 'Emma Wilson',
    email: 'emma@example.com',
    phone: '+1-555-0123',
    joinDate: '2025-01-15',
    totalClasses: 12,
    creditsBalance: 8,
    preferredContact: 'email'
  },
  {
    id: 'student_2',
    name: 'John Smith',
    email: 'john@example.com',
    phone: '+1-555-0124',
    joinDate: '2025-02-20',
    totalClasses: 5,
    creditsBalance: 3,
    preferredContact: 'sms'
  },
  {
    id: 'student_3',
    name: 'Maria Garcia',
    email: 'maria@example.com',
    joinDate: '2025-03-10',
    totalClasses: 18,
    creditsBalance: 15,
    preferredContact: 'email'
  }
];

export default function SessionManagement({ session, onClose, onUpdateSession }: SessionManagementProps) {
  const [activeTab, setActiveTab] = useState<'bookings' | 'waitlist' | 'analytics' | 'communication'>('bookings');
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedBookings, setSelectedBookings] = useState<string[]>([]);
  const [showAddBooking, setShowAddBooking] = useState(false);
  const [filterStatus, setFilterStatus] = useState('all');
  const [isLoading, setIsLoading] = useState(false);

  // Mock enhanced session data
  const enhancedSession: ClassSession = {
    ...session,
    bookings: [
      {
        id: 'booking_1',
        studentId: 'student_1',
        student: mockStudents[0],
        bookingDate: '2025-09-15T10:30:00Z',
        paymentStatus: 'paid',
        paymentMethod: 'credits',
        amount: session.creditCost * 15, // assuming $15 per credit
        status: 'confirmed',
        source: 'app',
        confirmationSent: true,
        reminderSent: false
      },
      {
        id: 'booking_2',
        studentId: 'student_2',
        student: mockStudents[1],
        bookingDate: '2025-09-16T14:20:00Z',
        paymentStatus: 'paid',
        paymentMethod: 'cash',
        amount: session.price,
        status: 'confirmed',
        source: 'phone',
        confirmationSent: true,
        reminderSent: true
      },
      {
        id: 'booking_3',
        studentId: 'student_3',
        student: mockStudents[2],
        bookingDate: '2025-09-17T09:15:00Z',
        paymentStatus: 'pending',
        paymentMethod: 'card',
        amount: session.price,
        status: 'pending',
        source: 'web',
        confirmationSent: false,
        reminderSent: false
      }
    ],
    waitlistEntries: [
      {
        id: 'waitlist_1',
        studentId: 'student_1',
        student: mockStudents[0],
        addedDate: '2025-09-17T16:45:00Z',
        position: 1,
        autoEnroll: true,
        maxPrice: session.price,
        notificationsSent: 1
      },
      {
        id: 'waitlist_2',
        studentId: 'student_2',
        student: mockStudents[1],
        addedDate: '2025-09-17T18:30:00Z',
        position: 2,
        autoEnroll: false,
        notificationsSent: 0
      }
    ],
    revenue: session.price * 2 + (session.creditCost * 15),
    expenses: 250,
    profitMargin: 45,
    lastUpdated: new Date().toISOString()
  };

  // Memoized filtered bookings for performance
  const waitlistEntries = enhancedSession.waitlistEntries ?? [];

  const filteredBookings = useMemo(() => {
    const bookings = enhancedSession.bookings;
    if (!searchTerm && filterStatus === 'all') return bookings;

    return searchFilter(bookings, searchTerm, ['student.name', 'student.email'])
      .filter(booking => filterStatus === 'all' || booking.status === filterStatus);
  }, [enhancedSession.bookings, searchTerm, filterStatus]);

  const handleBulkAction = (action: string) => {
    console.log(`Performing ${action} on bookings:`, selectedBookings);
    setSelectedBookings([]);
  };

  // All formatting functions are now imported from shared utilities

  return (
    <motion.div
      initial="hidden"
      animate="visible"
      exit="exit"
      variants={modalVariants}
      className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4"
    >
      <motion.div
        variants={modalVariants}
        className="bg-white rounded-xl shadow-xl max-w-6xl w-full max-h-[90vh] overflow-hidden"
      >
        {/* Header */}
        <div className="p-6 border-b border-gray-200 bg-gradient-to-r from-blue-50 to-indigo-50">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-2xl font-bold text-gray-900">{enhancedSession.className}</h2>
              <div className="flex items-center gap-4 mt-2 text-sm text-gray-600">
                <div className="flex items-center">
                  <Calendar className="h-4 w-4 mr-1" />
                  {formatDateTime(enhancedSession.date)}
                </div>
                <div className="flex items-center">
                  <Clock className="h-4 w-4 mr-1" />
                  {formatTime(enhancedSession.startTime)} - {formatTime(enhancedSession.endTime)}
                </div>
                <div className="flex items-center">
                  <User className="h-4 w-4 mr-1" />
                  {enhancedSession.instructor}
                </div>
              </div>
            </div>

            <div className="flex items-center gap-3">
              <div className="text-right">
                <div className="text-lg font-bold text-blue-600">
                  {enhancedSession.enrolled}/{enhancedSession.capacity}
                </div>
                <div className="text-xs text-gray-600">Enrolled</div>
              </div>

              <button className="p-2 text-gray-500 hover:text-gray-700 rounded-lg hover:bg-white">
                <Settings className="h-5 w-5" />
              </button>

              <button
                onClick={onClose}
                className="p-2 text-gray-500 hover:text-gray-700 rounded-lg hover:bg-white"
              >
                <X className="h-5 w-5" />
              </button>
            </div>
          </div>

          {/* Tab Navigation */}
          <div className="flex gap-1 mt-4">
            {[
              { key: 'bookings', label: 'Bookings', count: enhancedSession.bookings.length },
              { key: 'waitlist', label: 'Waitlist', count: waitlistEntries.length },
              { key: 'analytics', label: 'Analytics' },
              { key: 'communication', label: 'Communication' }
            ].map(tab => (
              <button
                key={tab.key}
                onClick={() => setActiveTab(tab.key as any)}
                className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                  activeTab === tab.key
                    ? 'bg-white text-blue-600 shadow-sm'
                    : 'text-gray-600 hover:text-gray-900 hover:bg-white/50'
                }`}
              >
                {tab.label}
                {tab.count !== undefined && (
                  <span className="ml-2 px-2 py-0.5 bg-blue-100 text-blue-600 rounded-full text-xs">
                    {tab.count}
                  </span>
                )}
              </button>
            ))}
          </div>
        </div>

        {/* Content Area */}
        <div className="p-6 overflow-y-auto max-h-[65vh]">
          {/* Bookings Tab */}
          {activeTab === 'bookings' && (
            <div className="space-y-4">
              {/* Bookings Header */}
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-4">
                  <div className="relative">
                    <Search className="h-4 w-4 absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
                    <input
                      type="text"
                      placeholder="Search students..."
                      value={searchTerm}
                      onChange={(e) => setSearchTerm(e.target.value)}
                      className="pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    />
                  </div>

                  <select
                    value={filterStatus}
                    onChange={(e) => setFilterStatus(e.target.value)}
                    className="border border-gray-300 rounded-lg pl-3 pr-10 py-2 focus:ring-2 focus:ring-blue-500 bg-white appearance-none cursor-pointer"
                    style={{ backgroundImage: 'url("data:image/svg+xml,%3Csvg xmlns=\'http://www.w3.org/2000/svg\' fill=\'none\' viewBox=\'0 0 20 20\'%3E%3Cpath stroke=\'%236b7280\' stroke-linecap=\'round\' stroke-linejoin=\'round\' stroke-width=\'1.5\' d=\'M6 8l4 4 4-4\'/%3E%3C/svg%3E")', backgroundPosition: 'right 0.75rem center', backgroundRepeat: 'no-repeat', backgroundSize: '1.25em 1.25em' }}
                  >
                    <option value="all">All Status</option>
                    <option value="confirmed">Confirmed</option>
                    <option value="pending">Pending</option>
                    <option value="cancelled">Cancelled</option>
                    <option value="noShow">No Show</option>
                  </select>
                </div>

                <div className="flex items-center gap-2">
                  {selectedBookings.length > 0 && (
                    <div className="flex items-center gap-2">
                      <span className="text-sm text-gray-600">
                        {selectedBookings.length} selected
                      </span>
                      <button
                        onClick={() => handleBulkAction('sendReminder')}
                        className="px-3 py-1 text-sm bg-blue-100 text-blue-700 rounded-lg hover:bg-blue-200"
                      >
                        Send Reminder
                      </button>
                      <button
                        onClick={() => handleBulkAction('refund')}
                        className="px-3 py-1 text-sm bg-red-100 text-red-700 rounded-lg hover:bg-red-200"
                      >
                        Refund
                      </button>
                    </div>
                  )}

                  <button
                    onClick={() => setShowAddBooking(true)}
                    className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 flex items-center gap-2"
                  >
                    <Plus className="h-4 w-4" />
                    Add Booking
                  </button>
                </div>
              </div>

              {/* Bookings List */}
              <div className="space-y-3">
                {filteredBookings.map((booking) => (
                  <motion.div
                    key={booking.id}
                    layout
                    className="p-4 border border-gray-200 rounded-lg hover:shadow-md transition-shadow"
                  >
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-4">
                        <input
                          type="checkbox"
                          checked={selectedBookings.includes(booking.id)}
                          onChange={(e) => {
                            if (e.target.checked) {
                              setSelectedBookings([...selectedBookings, booking.id]);
                            } else {
                              setSelectedBookings(selectedBookings.filter(id => id !== booking.id));
                            }
                          }}
                          className="w-4 h-4 text-blue-600 rounded focus:ring-blue-500"
                        />

                        <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center">
                          <User className="h-5 w-5 text-blue-600" />
                        </div>

                        <div>
                          <div className="font-medium text-gray-900">{booking.student.name}</div>
                          <div className="text-sm text-gray-600 flex items-center gap-3">
                            <span className="flex items-center gap-1">
                              <Mail className="h-3 w-3" />
                              {booking.student.email}
                            </span>
                            {booking.student.phone && (
                              <span className="flex items-center gap-1">
                                <Phone className="h-3 w-3" />
                                {booking.student.phone}
                              </span>
                            )}
                          </div>
                        </div>
                      </div>

                      <div className="flex items-center gap-4">
                        <div className="text-right">
                          <div className="font-medium">${booking.amount}</div>
                          <div className="text-xs text-gray-600">{booking.paymentMethod}</div>
                        </div>

                        <div className="flex flex-col gap-1">
                          <span className={`px-2 py-1 rounded-full text-xs font-medium border ${getStatusColor(booking.status)}`}>
                            {booking.status}
                          </span>
                          <span className={`px-2 py-1 rounded-full text-xs ${getPaymentStatusColor(booking.paymentStatus)}`}>
                            {booking.paymentStatus}
                          </span>
                        </div>

                        <div className="flex items-center gap-1">
                          {booking.confirmationSent && (
                            <CheckCircle
                              className="h-4 w-4 text-green-600"
                              aria-label="Confirmation sent"
                            />
                          )}
                          {booking.reminderSent && (
                            <Bell
                              className="h-4 w-4 text-blue-600"
                              aria-label="Reminder sent"
                            />
                          )}
                        </div>

                        <button className="p-1 text-gray-400 hover:text-gray-600 rounded">
                          <MoreVertical className="h-4 w-4" />
                        </button>
                      </div>
                    </div>
                  </motion.div>
                ))}
              </div>
            </div>
          )}

          {/* Waitlist Tab */}
          {activeTab === 'waitlist' && (
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <h3 className="text-lg font-semibold">Waitlist Management</h3>
                <button className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 flex items-center gap-2">
                  <Plus className="h-4 w-4" />
                  Add to Waitlist
                </button>
              </div>

              <div className="space-y-3">
                {waitlistEntries.map((entry, index) => (
                  <div key={entry.id} className="p-4 border border-gray-200 rounded-lg">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-4">
                        <div className="w-8 h-8 bg-yellow-100 rounded-full flex items-center justify-center text-yellow-700 font-medium">
                          {entry.position}
                        </div>

                        <div>
                          <div className="font-medium text-gray-900">{entry.student.name}</div>
                          <div className="text-sm text-gray-600">{entry.student.email}</div>
                          <div className="text-xs text-gray-500">
                            Added {formatDate(entry.addedDate)}
                          </div>
                        </div>
                      </div>

                      <div className="flex items-center gap-4">
                        <div className="text-sm text-gray-600">
                          {entry.autoEnroll ? (
                            <span className="flex items-center gap-1 text-green-600">
                              <CheckCircle className="h-4 w-4" />
                              Auto-enroll
                            </span>
                          ) : (
                            <span className="flex items-center gap-1">
                              <AlertCircle className="h-4 w-4" />
                              Manual approval
                            </span>
                          )}
                        </div>

                        <div className="flex items-center gap-1">
                          <button
                            className="p-1 text-blue-600 hover:bg-blue-100 rounded"
                            title="Move up"
                          >
                            <ArrowUpCircle className="h-4 w-4" />
                          </button>
                          <button
                            className="p-1 text-blue-600 hover:bg-blue-100 rounded"
                            title="Move down"
                          >
                            <ArrowDownCircle className="h-4 w-4" />
                          </button>
                          <button
                            className="p-1 text-green-600 hover:bg-green-100 rounded"
                            title="Enroll now"
                          >
                            <Plus className="h-4 w-4" />
                          </button>
                          <button
                            className="p-1 text-red-600 hover:bg-red-100 rounded"
                            title="Remove"
                          >
                            <Trash2 className="h-4 w-4" />
                          </button>
                        </div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Analytics Tab */}
          {activeTab === 'analytics' && (
            <div className="space-y-6">
              <h3 className="text-lg font-semibold">Session Analytics</h3>

              <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div className="p-4 bg-green-50 border border-green-200 rounded-lg">
                  <div className="text-2xl font-bold text-green-600">${enhancedSession.revenue}</div>
                  <div className="text-sm text-green-700">Total Revenue</div>
                  <div className="text-xs text-gray-600 mt-1">+15% vs last session</div>
                </div>

                <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
                  <div className="text-2xl font-bold text-blue-600">{enhancedSession.profitMargin}%</div>
                  <div className="text-sm text-blue-700">Profit Margin</div>
                  <div className="text-xs text-gray-600 mt-1">After ${enhancedSession.expenses} expenses</div>
                </div>

                <div className="p-4 bg-purple-50 border border-purple-200 rounded-lg">
                  <div className="text-2xl font-bold text-purple-600">
                    {Math.round((enhancedSession.enrolled / enhancedSession.capacity) * 100)}%
                  </div>
                  <div className="text-sm text-purple-700">Capacity Utilization</div>
                  <div className="text-xs text-gray-600 mt-1">{enhancedSession.enrolled} of {enhancedSession.capacity} spots</div>
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="p-4 border border-gray-200 rounded-lg">
                  <h4 className="font-semibold mb-3">Payment Methods</h4>
                  <div className="space-y-2">
                    {[
                      { method: 'Credits', count: 1, percentage: 33 },
                      { method: 'Cash', count: 1, percentage: 33 },
                      { method: 'Card', count: 1, percentage: 34 }
                    ].map(item => (
                      <div key={item.method} className="flex items-center justify-between">
                        <span className="text-sm">{item.method}</span>
                        <div className="flex items-center gap-2">
                          <div className="w-20 bg-gray-200 rounded-full h-2">
                            <div
                              className="bg-blue-600 h-2 rounded-full"
                              style={{ width: `${item.percentage}%` }}
                            />
                          </div>
                          <span className="text-sm text-gray-600">{item.count}</span>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

                <div className="p-4 border border-gray-200 rounded-lg">
                  <h4 className="font-semibold mb-3">Booking Sources</h4>
                  <div className="space-y-2">
                    {[
                      { source: 'Mobile App', count: 1, percentage: 33 },
                      { source: 'Phone', count: 1, percentage: 33 },
                      { source: 'Website', count: 1, percentage: 34 }
                    ].map(item => (
                      <div key={item.source} className="flex items-center justify-between">
                        <span className="text-sm">{item.source}</span>
                        <div className="flex items-center gap-2">
                          <div className="w-20 bg-gray-200 rounded-full h-2">
                            <div
                              className="bg-green-600 h-2 rounded-full"
                              style={{ width: `${item.percentage}%` }}
                            />
                          </div>
                          <span className="text-sm text-gray-600">{item.count}</span>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* Communication Tab */}
          {activeTab === 'communication' && (
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <h3 className="text-lg font-semibold">Communication Center</h3>
                <div className="flex gap-2">
                  <button className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 flex items-center gap-2">
                    <MessageSquare className="h-4 w-4" />
                    Send Message
                  </button>
                  <button className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 flex items-center gap-2">
                    <Bell className="h-4 w-4" />
                    Send Reminder
                  </button>
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
                  <div className="text-lg font-bold text-blue-600">2</div>
                  <div className="text-sm text-blue-700">Confirmations Sent</div>
                </div>
                <div className="p-4 bg-green-50 border border-green-200 rounded-lg">
                  <div className="text-lg font-bold text-green-600">1</div>
                  <div className="text-sm text-green-700">Reminders Sent</div>
                </div>
                <div className="p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
                  <div className="text-lg font-bold text-yellow-600">1</div>
                  <div className="text-sm text-yellow-700">Pending Confirmations</div>
                </div>
              </div>

              <div className="space-y-3">
                <h4 className="font-medium">Quick Actions</h4>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                  <button className="p-3 border border-gray-200 rounded-lg hover:bg-gray-50 text-left">
                    <div className="font-medium">Send Class Reminder</div>
                    <div className="text-sm text-gray-600">Remind all students about upcoming class</div>
                  </button>
                  <button className="p-3 border border-gray-200 rounded-lg hover:bg-gray-50 text-left">
                    <div className="font-medium">Request Feedback</div>
                    <div className="text-sm text-gray-600">Send post-class feedback survey</div>
                  </button>
                  <button className="p-3 border border-gray-200 rounded-lg hover:bg-gray-50 text-left">
                    <div className="font-medium">Notify Waitlist</div>
                    <div className="text-sm text-gray-600">Alert waitlist about available spots</div>
                  </button>
                  <button className="p-3 border border-gray-200 rounded-lg hover:bg-gray-50 text-left">
                    <div className="font-medium">Share Updates</div>
                    <div className="text-sm text-gray-600">Send class updates or announcements</div>
                  </button>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Footer Actions */}
        <div className="p-6 border-t border-gray-200 bg-gray-50">
          <div className="flex items-center justify-between">
            <div className="text-sm text-gray-600">
              Last updated: {enhancedSession.lastUpdated ? formatDate(enhancedSession.lastUpdated) : 'Not available'}
            </div>

            <div className="flex items-center gap-3">
              <button className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50">
                <Download className="h-4 w-4 mr-2 inline" />
                Export Data
              </button>
              <button
                onClick={() => onUpdateSession(enhancedSession)}
                className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
              >
                Save Changes
              </button>
            </div>
          </div>
        </div>
      </motion.div>
    </motion.div>
  );
}
