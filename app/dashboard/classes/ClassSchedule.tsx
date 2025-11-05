'use client';

import React, { useState, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  X,
  Calendar,
  Clock,
  Users,
  ChevronLeft,
  ChevronRight,
  Edit3,
  Eye,
  Trash2,
  User,
  MapPin,
  DollarSign,
  Settings,
  Download
} from 'lucide-react';
import SessionManagement from './SessionManagement';
import type { Class, ClassSession, ClassScheduleProps } from '../../../types/class-management';
import {
  getStatusColor,
  getCapacityColor,
  formatTime,
  formatDate,
  formatDateTime,
  getCalendarDays,
  getSessionsForDate,
  calculateTotalRevenue,
  modalVariants
} from '../../../lib/utils/class-management-utils';

// Mock data - in production this would come from API/props

const mockSessions: ClassSession[] = [
  {
    id: 'session_1',
    classId: '1',
    className: 'Pottery Wheel Basics',
    instructor: 'Sarah Johnson',
    instructorId: 'inst_1',
    date: '2025-09-19',
    startTime: '09:00',
    endTime: '11:00',
    duration: 120,
    capacity: 8,
    enrolled: 7,
    waitlist: 2,
    price: 65,
    creditCost: 3,
    location: 'Ceramics Studio',
    status: 'scheduled',
    revenue: 455,
    bookings: [] // Will be populated with proper BookingDetails in SessionManagement
  },
  {
    id: 'session_2',
    classId: '2',
    className: 'Watercolor Landscapes',
    instructor: 'Mike Chen',
    instructorId: 'inst_2',
    date: '2025-09-19',
    startTime: '10:30',
    endTime: '12:00',
    duration: 90,
    capacity: 12,
    enrolled: 8,
    waitlist: 0,
    price: 45,
    creditCost: 2,
    location: 'Art Studio',
    status: 'scheduled',
    revenue: 360,
    bookings: []
  },
  {
    id: 'session_3',
    classId: '3',
    className: 'Flower Bouquet Workshop',
    instructor: 'Emily Davis',
    instructorId: 'inst_3',
    date: '2025-09-19',
    startTime: '14:00',
    endTime: '15:30',
    duration: 90,
    capacity: 10,
    enrolled: 9,
    waitlist: 1,
    price: 55,
    creditCost: 2,
    location: 'Garden Room',
    status: 'scheduled',
    revenue: 495,
    bookings: []
  },
  {
    id: 'session_4',
    classId: '1',
    className: 'Pottery Wheel Basics',
    instructor: 'Sarah Johnson',
    instructorId: 'inst_1',
    date: '2025-09-20',
    startTime: '09:00',
    endTime: '11:00',
    duration: 120,
    capacity: 8,
    enrolled: 6,
    waitlist: 0,
    price: 65,
    creditCost: 3,
    location: 'Ceramics Studio',
    status: 'scheduled',
    revenue: 390,
    bookings: []
  }
];

export default function ClassSchedule({ classes, onClose, onSave }: ClassScheduleProps) {
  const [currentDate, setCurrentDate] = useState(new Date());
  const [sessions, setSessions] = useState<ClassSession[]>(mockSessions);
  const [selectedSession, setSelectedSession] = useState<ClassSession | null>(null);
  const [isSessionDetailOpen, setIsSessionDetailOpen] = useState(false);
  const [isSessionManagementOpen, setIsSessionManagementOpen] = useState(false);
  const [filterInstructor, setFilterInstructor] = useState('all');
  const [filterStatus, setFilterStatus] = useState('all');

  // Memoized calculations for performance
  const calendarDays = useMemo(() => getCalendarDays(currentDate), [currentDate]);
  const instructors = useMemo(() => Array.from(new Set(sessions.map(s => s.instructor))), [sessions]);
  const totalRevenue = useMemo(() => calculateTotalRevenue(sessions), [sessions]);

  const navigateWeek = (direction: 'prev' | 'next') => {
    const newDate = new Date(currentDate);
    newDate.setDate(currentDate.getDate() + (direction === 'next' ? 7 : -7));
    setCurrentDate(newDate);
  };

  const handleSessionClick = (session: ClassSession) => {
    setSelectedSession(session);
    setIsSessionDetailOpen(true);
  };

  const handleOpenSessionManagement = (session: ClassSession) => {
    setSelectedSession(session);
    setIsSessionDetailOpen(false);
    setIsSessionManagementOpen(true);
  };

  const handleUpdateSession = (updatedSession: ClassSession) => {
    setSessions(prev => prev.map(s => s.id === updatedSession.id ? updatedSession : s));
    setIsSessionManagementOpen(false);
    setSelectedSession(null);
  };

  // Get filtered sessions for a specific date
  const getFilteredSessionsForDate = (date: Date) => {
    return getSessionsForDate(sessions, date, filterInstructor, filterStatus);
  };

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
        className="bg-white rounded-xl shadow-xl max-w-7xl w-full max-h-[90vh] overflow-hidden"
      >
        {/* Header */}
        <div className="p-6 border-b border-gray-200">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-2xl font-bold text-gray-900">Class Schedule</h2>
              <p className="text-gray-600 mt-1">Manage class sessions and track bookings</p>
            </div>

            <div className="flex items-center gap-3">
              <div className="flex items-center gap-2">
                <select
                  value={filterInstructor}
                  onChange={(e) => setFilterInstructor(e.target.value)}
                  className="text-sm border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-blue-500"
                >
                  <option value="all">All Instructors</option>
                  {instructors.map(instructor => (
                    <option key={instructor} value={instructor}>{instructor}</option>
                  ))}
                </select>

                <select
                  value={filterStatus}
                  onChange={(e) => setFilterStatus(e.target.value)}
                  className="text-sm border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-blue-500"
                >
                  <option value="all">All Status</option>
                  <option value="scheduled">Scheduled</option>
                  <option value="completed">Completed</option>
                  <option value="cancelled">Cancelled</option>
                  <option value="in-progress">In Progress</option>
                </select>
              </div>

              <button className="p-2 text-gray-500 hover:text-gray-700 rounded-lg hover:bg-gray-100">
                <Download className="h-5 w-5" />
              </button>

              <button
                onClick={onClose}
                className="p-2 text-gray-500 hover:text-gray-700 rounded-lg hover:bg-gray-100"
              >
                <X className="h-5 w-5" />
              </button>
            </div>
          </div>
        </div>

        {/* Calendar Navigation */}
        <div className="p-6 border-b border-gray-200">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <button
                onClick={() => navigateWeek('prev')}
                className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
              >
                <ChevronLeft className="h-5 w-5" />
              </button>

              <h3 className="text-lg font-semibold text-gray-900">
                {calendarDays[0].toLocaleDateString('en-US', { month: 'long', day: 'numeric' })} - {' '}
                {calendarDays[6].toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' })}
              </h3>

              <button
                onClick={() => navigateWeek('next')}
                className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
              >
                <ChevronRight className="h-5 w-5" />
              </button>
            </div>

            <button
              onClick={() => setCurrentDate(new Date())}
              className="px-4 py-2 text-sm bg-blue-50 text-blue-700 rounded-lg hover:bg-blue-100 transition-colors"
            >
              Today
            </button>
          </div>
        </div>

        {/* Calendar Grid */}
        <div className="overflow-y-auto max-h-[60vh]">
          <div className="grid grid-cols-7 gap-px bg-gray-200">
            {/* Day Headers */}
            {calendarDays.map((day, index) => (
              <div key={index} className="bg-gray-50 p-4 text-center">
                <div className="text-sm font-medium text-gray-700">
                  {day.toLocaleDateString('en-US', { weekday: 'short' })}
                </div>
                <div className={`text-lg font-semibold mt-1 ${
                  day.toDateString() === new Date().toDateString()
                    ? 'text-blue-600'
                    : 'text-gray-900'
                }`}>
                  {day.getDate()}
                </div>
              </div>
            ))}

            {/* Day Cells */}
            {calendarDays.map((day, index) => {
              const daySessions = getFilteredSessionsForDate(day);
              return (
                <div key={index} className="bg-white p-2 min-h-[300px] border-r border-gray-100">
                  <div className="space-y-2">
                    {daySessions.map((session) => (
                      <motion.div
                        key={session.id}
                        whileHover={{ scale: 1.02 }}
                        className={`p-2 rounded-lg border cursor-pointer ${getStatusColor(session.status)}`}
                        onClick={() => handleSessionClick(session)}
                      >
                        <div className="text-xs font-medium truncate">{session.className}</div>
                        <div className="text-xs text-gray-600 mt-1">
                          {formatTime(session.startTime)} - {formatTime(session.endTime)}
                        </div>
                        <div className="flex items-center justify-between mt-2">
                          <div className="text-xs text-gray-600">{session.instructor}</div>
                          <div className={`text-xs font-medium ${getCapacityColor(session.enrolled, session.capacity)}`}>
                            {session.enrolled}/{session.capacity}
                          </div>
                        </div>
                      </motion.div>
                    ))}
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Summary Stats */}
        <div className="p-6 border-t border-gray-200 bg-gray-50">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <div className="text-center">
              <div className="text-2xl font-bold text-blue-600">
                {sessions.filter(s => s.status === 'scheduled').length}
              </div>
              <div className="text-sm text-gray-600">Scheduled</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-green-600">
                {sessions.reduce((sum, s) => sum + s.enrolled, 0)}
              </div>
              <div className="text-sm text-gray-600">Total Enrolled</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-yellow-600">
                {sessions.reduce((sum, s) => sum + s.waitlist, 0)}
              </div>
              <div className="text-sm text-gray-600">Waitlisted</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-purple-600">
                ${totalRevenue.toLocaleString()}
              </div>
              <div className="text-sm text-gray-600">Total Revenue</div>
            </div>
          </div>
        </div>
      </motion.div>

      {/* Session Detail Modal */}
      <AnimatePresence>
        {isSessionDetailOpen && selectedSession && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-60 p-4"
          >
            <motion.div
              initial={{ scale: 0.95, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.95, opacity: 0 }}
              className="bg-white rounded-xl shadow-xl max-w-2xl w-full max-h-[80vh] overflow-hidden"
            >
              {/* Session Header */}
              <div className="p-6 border-b border-gray-200">
                <div className="flex items-center justify-between">
                  <div>
                    <h3 className="text-xl font-bold text-gray-900">{selectedSession.className}</h3>
                    <p className="text-gray-600">
                      {formatDateTime(selectedSession.date)}
                    </p>
                  </div>
                  <button
                    onClick={() => setIsSessionDetailOpen(false)}
                    className="p-2 text-gray-500 hover:text-gray-700 rounded-lg hover:bg-gray-100"
                  >
                    <X className="h-5 w-5" />
                  </button>
                </div>
              </div>

              {/* Session Details */}
              <div className="p-6 overflow-y-auto max-h-[60vh]">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  {/* Session Info */}
                  <div className="space-y-4">
                    <div>
                      <h4 className="font-semibold text-gray-900 mb-3">Session Details</h4>
                      <div className="space-y-2">
                        <div className="flex items-center text-sm">
                          <Clock className="h-4 w-4 mr-2 text-gray-500" />
                          {formatTime(selectedSession.startTime)} - {formatTime(selectedSession.endTime)}
                        </div>
                        <div className="flex items-center text-sm">
                          <User className="h-4 w-4 mr-2 text-gray-500" />
                          {selectedSession.instructor}
                        </div>
                        <div className="flex items-center text-sm">
                          <MapPin className="h-4 w-4 mr-2 text-gray-500" />
                          {selectedSession.location}
                        </div>
                        <div className="flex items-center text-sm">
                          <Users className="h-4 w-4 mr-2 text-gray-500" />
                          {selectedSession.enrolled}/{selectedSession.capacity} enrolled
                        </div>
                        <div className="flex items-center text-sm">
                          <DollarSign className="h-4 w-4 mr-2 text-gray-500" />
                          ${selectedSession.price} / {selectedSession.creditCost} credits
                        </div>
                      </div>
                    </div>

                    <div>
                      <span className={`inline-block px-3 py-1 rounded-full text-sm font-medium ${getStatusColor(selectedSession.status)}`}>
                        {selectedSession.status}
                      </span>
                    </div>
                  </div>

                  {/* Revenue & Stats */}
                  <div className="space-y-4">
                    <div>
                      <h4 className="font-semibold text-gray-900 mb-3">Revenue & Stats</h4>
                      <div className="space-y-2">
                        <div className="flex justify-between">
                          <span className="text-sm text-gray-600">Total Revenue</span>
                          <span className="text-sm font-medium">${selectedSession.revenue}</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-sm text-gray-600">Waitlist</span>
                          <span className="text-sm font-medium">{selectedSession.waitlist} students</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-sm text-gray-600">Capacity Utilization</span>
                          <span className="text-sm font-medium">
                            {Math.round((selectedSession.enrolled / selectedSession.capacity) * 100)}%
                          </span>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Bookings List */}
                <div className="mt-6">
                  <h4 className="font-semibold text-gray-900 mb-3">Recent Bookings</h4>
                  {selectedSession.bookings.length > 0 ? (
                    <div className="space-y-2">
                      {selectedSession.bookings.slice(0, 3).map((booking) => (
                        <div key={booking.id} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                          <div>
                            <div className="font-medium text-sm">
                              {booking.student?.name ?? 'Student'}
                            </div>
                            {booking.student?.email && (
                              <div className="text-xs text-gray-600">
                                {booking.student.email}
                              </div>
                            )}
                          </div>
                          <div className="text-right">
                            <div className={`text-xs px-2 py-1 rounded-full ${
                              booking.paymentStatus === 'paid' ? 'bg-green-100 text-green-700' :
                              booking.paymentStatus === 'pending' ? 'bg-yellow-100 text-yellow-700' :
                              'bg-red-100 text-red-700'
                            }`}>
                              {booking.paymentStatus}
                            </div>
                            <div className="text-xs text-gray-600 mt-1">{booking.paymentMethod}</div>
                          </div>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <p className="text-gray-500 text-sm">No bookings yet</p>
                  )}
                </div>
              </div>

              {/* Session Actions */}
              <div className="p-6 border-t border-gray-200 bg-gray-50">
                <div className="flex items-center gap-3">
                  <button
                    onClick={() => handleOpenSessionManagement(selectedSession)}
                    className="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors flex items-center justify-center"
                  >
                    <Settings className="h-4 w-4 mr-2" />
                    Manage Session
                  </button>
                  <button className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors flex items-center justify-center">
                    <Edit3 className="h-4 w-4 mr-2" />
                    Edit
                  </button>
                  <button className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors">
                    <Eye className="h-4 w-4" />
                  </button>
                  <button className="px-4 py-2 border border-red-300 text-red-700 rounded-lg hover:bg-red-50 transition-colors">
                    <Trash2 className="h-4 w-4" />
                  </button>
                </div>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Session Management Modal */}
      <AnimatePresence>
        {isSessionManagementOpen && selectedSession && (
          <SessionManagement
            session={selectedSession}
            onClose={() => {
              setIsSessionManagementOpen(false);
              setSelectedSession(null);
            }}
            onUpdateSession={handleUpdateSession}
          />
        )}
      </AnimatePresence>
    </motion.div>
  );
}
