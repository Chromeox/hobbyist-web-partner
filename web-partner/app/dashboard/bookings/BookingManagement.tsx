'use client';

import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Calendar,
  Search,
  Filter,
  CheckCircle,
  XCircle,
  Clock,
  User,
  Mail,
  Phone,
  MessageSquare,
  DollarSign,
  MapPin,
  AlertTriangle,
  RefreshCw,
  Download,
  Send,
  Eye,
  Edit3,
  Trash2,
  MoreVertical,
  Star,
  CreditCard,
  Receipt,
  Ban
} from 'lucide-react';
import BookingDetailsModal from './BookingDetailsModal';
import MessageModal from './MessageModal';
import RefundModal from './RefundModal';

interface Booking {
  id: string;
  studentId: string;
  studentName: string;
  studentEmail: string;
  studentPhone: string;
  classId: string;
  className: string;
  classDate: string;
  classTime: string;
  instructor: string;
  location: string;
  status: 'confirmed' | 'pending' | 'cancelled' | 'completed' | 'no-show';
  paymentStatus: 'paid' | 'pending' | 'failed' | 'refunded';
  paymentAmount: number;
  paymentMethod: string;
  bookingDate: string;
  notes?: string;
  cancellationReason?: string;
  isFirstTime: boolean;
  previousBookings: number;
  studentRating?: number;
  hasSpecialRequirements: boolean;
  specialRequirements?: string;
}

const mockBookings: Booking[] = [
  {
    id: 'book_1',
    studentId: 'user_123',
    studentName: 'Sarah Wilson',
    studentEmail: 'sarah.w@email.com',
    studentPhone: '(555) 123-4567',
    classId: 'class_1',
    className: 'Morning Yoga Flow',
    classDate: '2025-08-09',
    classTime: '09:00',
    instructor: 'Sarah Johnson',
    location: 'Studio A',
    status: 'confirmed',
    paymentStatus: 'paid',
    paymentAmount: 25,
    paymentMethod: 'Credit Card',
    bookingDate: '2025-08-07T14:30:00Z',
    notes: 'First time student, please provide modifications',
    isFirstTime: true,
    previousBookings: 0,
    hasSpecialRequirements: true,
    specialRequirements: 'Lower back injury - needs modifications'
  },
  {
    id: 'book_2',
    studentId: 'user_456',
    studentName: 'Michael Brown',
    studentEmail: 'mike.b@email.com',
    studentPhone: '(555) 234-5678',
    classId: 'class_2',
    className: 'Advanced Pilates',
    classDate: '2025-08-09',
    classTime: '10:30',
    instructor: 'Mike Chen',
    location: 'Studio B',
    status: 'confirmed',
    paymentStatus: 'paid',
    paymentAmount: 35,
    paymentMethod: 'Apple Pay',
    bookingDate: '2025-08-06T09:15:00Z',
    isFirstTime: false,
    previousBookings: 12,
    studentRating: 4.8,
    hasSpecialRequirements: false
  },
  {
    id: 'book_3',
    studentId: 'user_789',
    studentName: 'Emma Davis',
    studentEmail: 'emma.d@email.com',
    studentPhone: '(555) 345-6789',
    classId: 'class_3',
    className: 'Contemporary Dance',
    classDate: '2025-08-09',
    classTime: '14:00',
    instructor: 'Emily Davis',
    location: 'Main Studio',
    status: 'pending',
    paymentStatus: 'pending',
    paymentAmount: 30,
    paymentMethod: 'Credit Card',
    bookingDate: '2025-08-08T11:20:00Z',
    isFirstTime: false,
    previousBookings: 7,
    hasSpecialRequirements: false
  },
  {
    id: 'book_4',
    studentId: 'user_321',
    studentName: 'David Kim',
    studentEmail: 'd.kim@email.com',
    studentPhone: '(555) 456-7890',
    classId: 'class_1',
    className: 'Morning Yoga Flow',
    classDate: '2025-08-08',
    classTime: '09:00',
    instructor: 'Sarah Johnson',
    location: 'Studio A',
    status: 'cancelled',
    paymentStatus: 'refunded',
    paymentAmount: 25,
    paymentMethod: 'Credit Card',
    bookingDate: '2025-08-05T16:45:00Z',
    cancellationReason: 'Schedule conflict',
    isFirstTime: false,
    previousBookings: 3,
    hasSpecialRequirements: false
  }
];

export default function BookingManagement() {
  const [bookings, setBookings] = useState<Booking[]>(mockBookings);
  const [filteredBookings, setFilteredBookings] = useState<Booking[]>(mockBookings);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedStatus, setSelectedStatus] = useState('all');
  const [selectedPaymentStatus, setSelectedPaymentStatus] = useState('all');
  const [dateFilter, setDateFilter] = useState('all');
  const [sortBy, setSortBy] = useState('date');
  const [selectedBooking, setSelectedBooking] = useState<Booking | null>(null);
  const [isDetailsModalOpen, setIsDetailsModalOpen] = useState(false);
  const [isMessageModalOpen, setIsMessageModalOpen] = useState(false);
  const [isRefundModalOpen, setIsRefundModalOpen] = useState(false);
  const [bulkActions, setBulkActions] = useState<string[]>([]);

  const statuses = ['all', 'confirmed', 'pending', 'cancelled', 'completed', 'no-show'];
  const paymentStatuses = ['all', 'paid', 'pending', 'failed', 'refunded'];

  // Filter and sort bookings
  useEffect(() => {
    let filtered = bookings.filter(booking => {
      const matchesSearch = booking.studentName.toLowerCase().includes(searchTerm.toLowerCase()) ||
                           booking.studentEmail.toLowerCase().includes(searchTerm.toLowerCase()) ||
                           booking.className.toLowerCase().includes(searchTerm.toLowerCase()) ||
                           booking.instructor.toLowerCase().includes(searchTerm.toLowerCase());
      
      const matchesStatus = selectedStatus === 'all' || booking.status === selectedStatus;
      const matchesPaymentStatus = selectedPaymentStatus === 'all' || booking.paymentStatus === selectedPaymentStatus;
      
      let matchesDate = true;
      const bookingDate = new Date(booking.classDate);
      const today = new Date();
      
      switch (dateFilter) {
        case 'today':
          matchesDate = bookingDate.toDateString() === today.toDateString();
          break;
        case 'tomorrow':
          const tomorrow = new Date(today);
          tomorrow.setDate(today.getDate() + 1);
          matchesDate = bookingDate.toDateString() === tomorrow.toDateString();
          break;
        case 'week':
          const weekFromNow = new Date(today);
          weekFromNow.setDate(today.getDate() + 7);
          matchesDate = bookingDate >= today && bookingDate <= weekFromNow;
          break;
        case 'past':
          matchesDate = bookingDate < today;
          break;
      }
      
      return matchesSearch && matchesStatus && matchesPaymentStatus && matchesDate;
    });

    // Sort bookings
    filtered.sort((a, b) => {
      switch (sortBy) {
        case 'date':
          return new Date(a.classDate + ' ' + a.classTime).getTime() - 
                 new Date(b.classDate + ' ' + b.classTime).getTime();
        case 'student':
          return a.studentName.localeCompare(b.studentName);
        case 'class':
          return a.className.localeCompare(b.className);
        case 'amount':
          return b.paymentAmount - a.paymentAmount;
        case 'booking-date':
          return new Date(b.bookingDate).getTime() - new Date(a.bookingDate).getTime();
        default:
          return 0;
      }
    });

    setFilteredBookings(filtered);
  }, [bookings, searchTerm, selectedStatus, selectedPaymentStatus, dateFilter, sortBy]);

  const handleViewDetails = (booking: Booking) => {
    setSelectedBooking(booking);
    setIsDetailsModalOpen(true);
  };

  const handleSendMessage = (booking: Booking) => {
    setSelectedBooking(booking);
    setIsMessageModalOpen(true);
  };

  const handleProcessRefund = (booking: Booking) => {
    setSelectedBooking(booking);
    setIsRefundModalOpen(true);
  };

  const handleStatusChange = (bookingId: string, newStatus: string) => {
    setBookings(prev => prev.map(booking => 
      booking.id === bookingId ? { ...booking, status: newStatus as any } : booking
    ));
  };

  const handleBulkAction = (action: string) => {
    switch (action) {
      case 'confirm':
        setBookings(prev => prev.map(booking => 
          bulkActions.includes(booking.id) ? { ...booking, status: 'confirmed' } : booking
        ));
        break;
      case 'cancel':
        // In a real app, this would show a confirmation dialog
        setBookings(prev => prev.map(booking => 
          bulkActions.includes(booking.id) ? { ...booking, status: 'cancelled' } : booking
        ));
        break;
    }
    setBulkActions([]);
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'confirmed': return 'bg-green-100 text-green-700';
      case 'pending': return 'bg-yellow-100 text-yellow-700';
      case 'cancelled': return 'bg-red-100 text-red-700';
      case 'completed': return 'bg-blue-100 text-blue-700';
      case 'no-show': return 'bg-gray-100 text-gray-700';
      default: return 'bg-gray-100 text-gray-700';
    }
  };

  const getPaymentStatusColor = (status: string) => {
    switch (status) {
      case 'paid': return 'bg-green-100 text-green-700';
      case 'pending': return 'bg-yellow-100 text-yellow-700';
      case 'failed': return 'bg-red-100 text-red-700';
      case 'refunded': return 'bg-blue-100 text-blue-700';
      default: return 'bg-gray-100 text-gray-700';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'confirmed': return CheckCircle;
      case 'pending': return Clock;
      case 'cancelled': return XCircle;
      case 'completed': return CheckCircle;
      case 'no-show': return Ban;
      default: return AlertTriangle;
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Booking Management</h1>
          <p className="text-gray-600 mt-1">Manage student bookings and communications</p>
        </div>
        
        <div className="flex items-center gap-3">
          <button className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors flex items-center">
            <RefreshCw className="h-4 w-4 mr-2" />
            Refresh
          </button>
          
          <button className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors flex items-center">
            <Download className="h-4 w-4 mr-2" />
            Export
          </button>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
        <div className="bg-white rounded-xl shadow-sm border p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Total Bookings</p>
              <p className="text-2xl font-bold text-gray-900 mt-1">{bookings.length}</p>
            </div>
            <Calendar className="h-6 w-6 text-blue-600" />
          </div>
        </div>
        
        <div className="bg-white rounded-xl shadow-sm border p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Confirmed</p>
              <p className="text-2xl font-bold text-gray-900 mt-1">
                {bookings.filter(b => b.status === 'confirmed').length}
              </p>
            </div>
            <CheckCircle className="h-6 w-6 text-green-600" />
          </div>
        </div>
        
        <div className="bg-white rounded-xl shadow-sm border p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Pending</p>
              <p className="text-2xl font-bold text-gray-900 mt-1">
                {bookings.filter(b => b.status === 'pending').length}
              </p>
            </div>
            <Clock className="h-6 w-6 text-yellow-600" />
          </div>
        </div>
        
        <div className="bg-white rounded-xl shadow-sm border p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Revenue</p>
              <p className="text-2xl font-bold text-gray-900 mt-1">
                ${bookings.filter(b => b.paymentStatus === 'paid')
                         .reduce((sum, b) => sum + b.paymentAmount, 0)}
              </p>
            </div>
            <DollarSign className="h-6 w-6 text-green-600" />
          </div>
        </div>
        
        <div className="bg-white rounded-xl shadow-sm border p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">First-Time Students</p>
              <p className="text-2xl font-bold text-gray-900 mt-1">
                {bookings.filter(b => b.isFirstTime).length}
              </p>
            </div>
            <Star className="h-6 w-6 text-purple-600" />
          </div>
        </div>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-lg border p-4">
        <div className="flex flex-col xl:flex-row gap-4">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
            <input
              type="text"
              placeholder="Search bookings by student, class, or instructor..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
          </div>
          
          <div className="flex flex-wrap items-center gap-3">
            <select
              value={selectedStatus}
              onChange={(e) => setSelectedStatus(e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              {statuses.map(status => (
                <option key={status} value={status}>
                  {status === 'all' ? 'All Statuses' : status.charAt(0).toUpperCase() + status.slice(1)}
                </option>
              ))}
            </select>
            
            <select
              value={selectedPaymentStatus}
              onChange={(e) => setSelectedPaymentStatus(e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              {paymentStatuses.map(status => (
                <option key={status} value={status}>
                  {status === 'all' ? 'All Payments' : status.charAt(0).toUpperCase() + status.slice(1)}
                </option>
              ))}
            </select>
            
            <select
              value={dateFilter}
              onChange={(e) => setDateFilter(e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              <option value="all">All Dates</option>
              <option value="today">Today</option>
              <option value="tomorrow">Tomorrow</option>
              <option value="week">This Week</option>
              <option value="past">Past Classes</option>
            </select>
            
            <select
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              <option value="date">Sort by Class Date</option>
              <option value="student">Sort by Student</option>
              <option value="class">Sort by Class</option>
              <option value="amount">Sort by Amount</option>
              <option value="booking-date">Sort by Booking Date</option>
            </select>
          </div>
        </div>

        {/* Bulk Actions */}
        {bulkActions.length > 0 && (
          <div className="mt-4 p-3 bg-blue-50 rounded-lg border border-blue-200">
            <div className="flex items-center justify-between">
              <span className="text-sm text-blue-700">
                {bulkActions.length} booking{bulkActions.length > 1 ? 's' : ''} selected
              </span>
              <div className="flex items-center gap-2">
                <button
                  onClick={() => handleBulkAction('confirm')}
                  className="px-3 py-1 text-sm bg-green-600 text-white rounded hover:bg-green-700 transition-colors"
                >
                  Confirm
                </button>
                <button
                  onClick={() => handleBulkAction('cancel')}
                  className="px-3 py-1 text-sm bg-red-600 text-white rounded hover:bg-red-700 transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={() => setBulkActions([])}
                  className="px-3 py-1 text-sm border border-gray-300 text-gray-700 rounded hover:bg-gray-50 transition-colors"
                >
                  Clear
                </button>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Bookings Table */}
      <div className="bg-white rounded-xl shadow-sm border overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b">
              <tr>
                <th className="w-12 py-3 px-4">
                  <input
                    type="checkbox"
                    onChange={(e) => {
                      if (e.target.checked) {
                        setBulkActions(filteredBookings.map(b => b.id));
                      } else {
                        setBulkActions([]);
                      }
                    }}
                    className="rounded border-gray-300"
                  />
                </th>
                <th className="text-left py-3 px-6 font-medium text-gray-900">Student</th>
                <th className="text-left py-3 px-6 font-medium text-gray-900">Class</th>
                <th className="text-left py-3 px-6 font-medium text-gray-900">Date & Time</th>
                <th className="text-left py-3 px-6 font-medium text-gray-900">Status</th>
                <th className="text-left py-3 px-6 font-medium text-gray-900">Payment</th>
                <th className="text-left py-3 px-6 font-medium text-gray-900">Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredBookings.map((booking) => {
                const StatusIcon = getStatusIcon(booking.status);
                
                return (
                  <tr key={booking.id} className="border-b hover:bg-gray-50">
                    <td className="py-4 px-4">
                      <input
                        type="checkbox"
                        checked={bulkActions.includes(booking.id)}
                        onChange={(e) => {
                          if (e.target.checked) {
                            setBulkActions(prev => [...prev, booking.id]);
                          } else {
                            setBulkActions(prev => prev.filter(id => id !== booking.id));
                          }
                        }}
                        className="rounded border-gray-300"
                      />
                    </td>
                    
                    <td className="py-4 px-6">
                      <div className="flex items-center">
                        <div className="h-10 w-10 rounded-full bg-gradient-to-r from-blue-500 to-purple-600 flex items-center justify-center text-white font-semibold mr-3">
                          {booking.studentName.charAt(0).toUpperCase()}
                        </div>
                        <div>
                          <p className="font-medium text-gray-900">{booking.studentName}</p>
                          <p className="text-sm text-gray-600">{booking.studentEmail}</p>
                          {booking.isFirstTime && (
                            <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-purple-100 text-purple-700 mt-1">
                              <Star className="h-3 w-3 mr-1" />
                              First Time
                            </span>
                          )}
                        </div>
                      </div>
                    </td>
                    
                    <td className="py-4 px-6">
                      <div>
                        <p className="font-medium text-gray-900">{booking.className}</p>
                        <p className="text-sm text-gray-600">{booking.instructor}</p>
                        <p className="text-sm text-gray-500">{booking.location}</p>
                      </div>
                    </td>
                    
                    <td className="py-4 px-6">
                      <div>
                        <p className="font-medium text-gray-900">
                          {new Date(booking.classDate).toLocaleDateString()}
                        </p>
                        <p className="text-sm text-gray-600">{booking.classTime}</p>
                      </div>
                    </td>
                    
                    <td className="py-4 px-6">
                      <div className="flex items-center">
                        <StatusIcon className={`h-4 w-4 mr-2 ${
                          booking.status === 'confirmed' ? 'text-green-600' :
                          booking.status === 'pending' ? 'text-yellow-600' :
                          booking.status === 'cancelled' ? 'text-red-600' :
                          'text-gray-600'
                        }`} />
                        <span className={`px-2 py-1 text-xs font-medium rounded-full ${getStatusColor(booking.status)}`}>
                          {booking.status}
                        </span>
                      </div>
                      {booking.hasSpecialRequirements && (
                        <div className="mt-1">
                          <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-orange-100 text-orange-700">
                            <AlertTriangle className="h-3 w-3 mr-1" />
                            Special Requirements
                          </span>
                        </div>
                      )}
                    </td>
                    
                    <td className="py-4 px-6">
                      <div>
                        <div className="flex items-center">
                          <DollarSign className="h-4 w-4 text-gray-500 mr-1" />
                          <span className="font-medium">${booking.paymentAmount}</span>
                        </div>
                        <span className={`inline-block px-2 py-1 text-xs font-medium rounded-full mt-1 ${getPaymentStatusColor(booking.paymentStatus)}`}>
                          {booking.paymentStatus}
                        </span>
                      </div>
                    </td>
                    
                    <td className="py-4 px-6">
                      <div className="flex items-center gap-2">
                        <button
                          onClick={() => handleViewDetails(booking)}
                          className="p-1 text-gray-500 hover:text-blue-600 hover:bg-blue-50 rounded"
                          title="View Details"
                        >
                          <Eye className="h-4 w-4" />
                        </button>
                        
                        <button
                          onClick={() => handleSendMessage(booking)}
                          className="p-1 text-gray-500 hover:text-green-600 hover:bg-green-50 rounded"
                          title="Send Message"
                        >
                          <MessageSquare className="h-4 w-4" />
                        </button>
                        
                        {booking.paymentStatus === 'paid' && (
                          <button
                            onClick={() => handleProcessRefund(booking)}
                            className="p-1 text-gray-500 hover:text-orange-600 hover:bg-orange-50 rounded"
                            title="Process Refund"
                          >
                            <RefreshCw className="h-4 w-4" />
                          </button>
                        )}
                        
                        <div className="relative">
                          <button className="p-1 text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded">
                            <MoreVertical className="h-4 w-4" />
                          </button>
                        </div>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* Empty State */}
      {filteredBookings.length === 0 && (
        <div className="text-center py-12 bg-white rounded-xl border">
          <Calendar className="h-16 w-16 text-gray-300 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">No bookings found</h3>
          <p className="text-gray-600">
            {searchTerm ? 'Try adjusting your search filters' : 'Bookings will appear here once students start booking classes'}
          </p>
        </div>
      )}

      {/* Modals */}
      <AnimatePresence>
        {isDetailsModalOpen && selectedBooking && (
          <BookingDetailsModal
            booking={selectedBooking}
            onClose={() => setIsDetailsModalOpen(false)}
            onStatusChange={handleStatusChange}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {isMessageModalOpen && selectedBooking && (
          <MessageModal
            booking={selectedBooking}
            onClose={() => setIsMessageModalOpen(false)}
            onSend={(message) => {
              console.log('Sending message:', message);
              setIsMessageModalOpen(false);
            }}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {isRefundModalOpen && selectedBooking && (
          <RefundModal
            booking={selectedBooking}
            onClose={() => setIsRefundModalOpen(false)}
            onRefund={(refundData) => {
              setBookings(prev => prev.map(booking => 
                booking.id === selectedBooking.id 
                  ? { ...booking, paymentStatus: 'refunded', status: 'cancelled' }
                  : booking
              ));
              setIsRefundModalOpen(false);
            }}
          />
        )}
      </AnimatePresence>
    </div>
  );
}