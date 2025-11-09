'use client';

import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { usePaymentModel } from '@/lib/contexts/PaymentModelContext';
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
import BackButton from '@/components/common/BackButton';
import ReservationDetailsModal from './ReservationDetailsModal';
import MessageModal from './MessageModal';
import RefundModal from './RefundModal';

interface Reservation {
  id: string;
  studentId: string;
  studentName: string;
  studentEmail: string;
  studentPhone: string;
  studentCredits: number; // Current credit balance
  classId: string;
  className: string;
  classDate: string;
  classTime: string;
  instructor: string;
  location: string;
  status: 'confirmed' | 'pending' | 'cancelled' | 'completed' | 'no-show';
  paymentStatus: 'paid' | 'pending' | 'failed' | 'refunded';
  creditCost: number; // Credits required for this class
  paymentAmount: number; // For cash payments (if supported)
  paymentMethod: 'credits' | 'cash' | 'mixed'; // Payment type used
  reservationDate: string;
  notes?: string;
  cancellationReason?: string;
  isFirstTime: boolean;
  previousReservations: number;
  studentRating?: number;
  hasSpecialRequirements: boolean;
  specialRequirements?: string;
}

const mockReservations: Reservation[] = [
  {
    id: 'res_1',
    studentId: 'user_123',
    studentName: 'Sarah Wilson',
    studentEmail: 'sarah.w@email.com',
    studentPhone: '(555) 123-4567',
    studentCredits: 12,
    classId: 'class_1',
    className: 'Morning Yoga Flow',
    classDate: '2025-08-09',
    classTime: '09:00',
    instructor: 'Sarah Johnson',
    location: 'Studio A',
    status: 'confirmed',
    paymentStatus: 'paid',
    creditCost: 2,
    paymentAmount: 0,
    paymentMethod: 'credits',
    reservationDate: '2025-08-07T14:30:00Z',
    notes: 'First time student, please provide modifications',
    isFirstTime: true,
    previousReservations: 0,
    hasSpecialRequirements: true,
    specialRequirements: 'Lower back injury - needs modifications'
  },
  {
    id: 'res_2',
    studentId: 'user_456',
    studentName: 'Michael Brown',
    studentEmail: 'mike.b@email.com',
    studentPhone: '(555) 234-5678',
    studentCredits: 25,
    classId: 'class_2',
    className: 'Advanced Pilates',
    classDate: '2025-08-09',
    classTime: '10:30',
    instructor: 'Mike Chen',
    location: 'Studio B',
    status: 'confirmed',
    paymentStatus: 'paid',
    creditCost: 3,
    paymentAmount: 0,
    paymentMethod: 'credits',
    reservationDate: '2025-08-06T09:15:00Z',
    isFirstTime: false,
    previousReservations: 12,
    studentRating: 4.8,
    hasSpecialRequirements: false
  },
  {
    id: 'res_3',
    studentId: 'user_789',
    studentName: 'Emma Davis',
    studentEmail: 'emma.d@email.com',
    studentPhone: '(555) 345-6789',
    studentCredits: 5,
    classId: 'class_3',
    className: 'Contemporary Dance',
    classDate: '2025-08-09',
    classTime: '14:00',
    instructor: 'Emily Davis',
    location: 'Main Studio',
    status: 'pending',
    paymentStatus: 'pending',
    creditCost: 2,
    paymentAmount: 0,
    paymentMethod: 'credits',
    reservationDate: '2025-08-08T11:20:00Z',
    isFirstTime: false,
    previousReservations: 7,
    hasSpecialRequirements: false
  },
  {
    id: 'res_4',
    studentId: 'user_321',
    studentName: 'David Kim',
    studentEmail: 'd.kim@email.com',
    studentPhone: '(555) 456-7890',
    studentCredits: 8,
    classId: 'class_1',
    className: 'Morning Yoga Flow',
    classDate: '2025-08-08',
    classTime: '09:00',
    instructor: 'Sarah Johnson',
    location: 'Studio A',
    status: 'cancelled',
    paymentStatus: 'refunded',
    creditCost: 2,
    paymentAmount: 0,
    paymentMethod: 'credits',
    reservationDate: '2025-08-05T16:45:00Z',
    cancellationReason: 'Schedule conflict',
    isFirstTime: false,
    previousReservations: 3,
    hasSpecialRequirements: false
  }
];

export default function ReservationManagement() {
  const { isCreditsEnabled, isCashEnabled, isHybridMode } = usePaymentModel();
  const [reservations, setReservations] = useState<Reservation[]>(mockReservations);
  const [filteredReservations, setFilteredReservations] = useState<Reservation[]>(mockReservations);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedStatus, setSelectedStatus] = useState('all');
  const [selectedPaymentStatus, setSelectedPaymentStatus] = useState('all');
  const [dateFilter, setDateFilter] = useState('all');
  const [sortBy, setSortBy] = useState('date');
  const [selectedReservation, setSelectedReservation] = useState<Reservation | null>(null);
  const [isDetailsModalOpen, setIsDetailsModalOpen] = useState(false);
  const [isMessageModalOpen, setIsMessageModalOpen] = useState(false);
  const [isRefundModalOpen, setIsRefundModalOpen] = useState(false);
  const [bulkActions, setBulkActions] = useState<string[]>([]);

  const statuses = ['all', 'confirmed', 'pending', 'cancelled', 'completed', 'no-show'];
  const paymentStatuses = ['all', 'paid', 'pending', 'failed', 'refunded'];

  // Filter and sort reservations
  useEffect(() => {
    let filtered = reservations.filter(reservation => {
      const matchesSearch = reservation.studentName.toLowerCase().includes(searchTerm.toLowerCase()) ||
                           reservation.studentEmail.toLowerCase().includes(searchTerm.toLowerCase()) ||
                           reservation.className.toLowerCase().includes(searchTerm.toLowerCase()) ||
                           reservation.instructor.toLowerCase().includes(searchTerm.toLowerCase());
      
      const matchesStatus = selectedStatus === 'all' || reservation.status === selectedStatus;
      const matchesPaymentStatus = selectedPaymentStatus === 'all' || reservation.paymentStatus === selectedPaymentStatus;
      
      let matchesDate = true;
      const reservationDate = new Date(reservation.classDate);
      const today = new Date();
      
      switch (dateFilter) {
        case 'today':
          matchesDate = reservationDate.toDateString() === today.toDateString();
          break;
        case 'tomorrow':
          const tomorrow = new Date(today);
          tomorrow.setDate(today.getDate() + 1);
          matchesDate = reservationDate.toDateString() === tomorrow.toDateString();
          break;
        case 'week':
          const weekFromNow = new Date(today);
          weekFromNow.setDate(today.getDate() + 7);
          matchesDate = reservationDate >= today && reservationDate <= weekFromNow;
          break;
        case 'past':
          matchesDate = reservationDate < today;
          break;
      }
      
      return matchesSearch && matchesStatus && matchesPaymentStatus && matchesDate;
    });

    // Sort reservations
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
          return b.creditCost - a.creditCost;
        case 'booking-date':
          return new Date(b.reservationDate).getTime() - new Date(a.reservationDate).getTime();
        default:
          return 0;
      }
    });

    setFilteredReservations(filtered);
  }, [reservations, searchTerm, selectedStatus, selectedPaymentStatus, dateFilter, sortBy]);

  const handleViewDetails = (reservation: Reservation) => {
    setSelectedReservation(reservation);
    setIsDetailsModalOpen(true);
  };

  const handleSendMessage = (reservation: Reservation) => {
    setSelectedReservation(reservation);
    setIsMessageModalOpen(true);
  };

  const handleProcessRefund = (reservation: Reservation) => {
    setSelectedReservation(reservation);
    setIsRefundModalOpen(true);
  };

  const handleStatusChange = (reservationId: string, newStatus: string) => {
    setReservations(prev => prev.map(reservation => 
      reservation.id === reservationId ? { ...reservation, status: newStatus as any } : reservation
    ));
  };

  const handleBulkAction = (action: string) => {
    switch (action) {
      case 'confirm':
        setReservations(prev => prev.map(reservation => 
          bulkActions.includes(reservation.id) ? { ...reservation, status: 'confirmed' } : reservation
        ));
        break;
      case 'cancel':
        // In a real app, this would show a confirmation dialog
        setReservations(prev => prev.map(reservation => 
          bulkActions.includes(reservation.id) ? { ...reservation, status: 'cancelled' } : reservation
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
      <BackButton href="/dashboard" className="mb-4" />
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Reservation Management</h1>
          <p className="text-gray-600 mt-1">Manage student reservations and credit transactions</p>
        </div>
        
        <div className="flex items-center gap-3">
          <button className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors flex items-center">
            <RefreshCw className="h-4 w-4 mr-2" />
            Refresh
          </button>
          
          <button 
            onClick={() => {
              // Export reservations to CSV
              const csvContent = [
                ['Reservation ID', 'Student', 'Credits', 'Class', 'Credit Cost', 'Date', 'Time', 'Status', 'Payment'],
                ...filteredReservations.map(reservation => [
                  reservation.id,
                  reservation.studentName,
                  reservation.studentCredits,
                  reservation.className,
                  reservation.creditCost,
                  reservation.classDate,
                  reservation.classTime,
                  reservation.status,
                  reservation.paymentStatus
                ])
              ].map(row => row.join(',')).join('\n');
              
              const blob = new Blob([csvContent], { type: 'text/csv' });
              const url = window.URL.createObjectURL(blob);
              const a = document.createElement('a');
              a.href = url;
              a.download = `reservations_${new Date().toISOString().split('T')[0]}.csv`;
              a.click();
              window.URL.revokeObjectURL(url);
            }}
            className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors flex items-center">
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
              <p className="text-sm font-medium text-gray-600">Total Reservations</p>
              <p className="text-2xl font-bold text-gray-900 mt-1">{reservations.length}</p>
            </div>
            <Calendar className="h-6 w-6 text-blue-600" />
          </div>
        </div>
        
        <div className="bg-white rounded-xl shadow-sm border p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Confirmed</p>
              <p className="text-2xl font-bold text-gray-900 mt-1">
                {reservations.filter(r => r.status === 'confirmed').length}
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
                {reservations.filter(r => r.status === 'pending').length}
              </p>
            </div>
            <Clock className="h-6 w-6 text-yellow-600" />
          </div>
        </div>
        
        {isCreditsEnabled ? (
          <div className="bg-white rounded-xl shadow-sm border p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Credits Used</p>
                <p className="text-2xl font-bold text-gray-900 mt-1">
                  {reservations.filter(r => r.paymentStatus === 'paid')
                           .reduce((sum, r) => sum + r.creditCost, 0)}
                </p>
              </div>
              <CreditCard className="h-6 w-6 text-green-600" />
            </div>
          </div>
        ) : (
          <div className="bg-white rounded-xl shadow-sm border p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Revenue</p>
                <p className="text-2xl font-bold text-gray-900 mt-1">
                  ${reservations.filter(r => r.paymentStatus === 'paid')
                           .reduce((sum, r) => sum + r.paymentAmount, 0)}
                </p>
              </div>
              <DollarSign className="h-6 w-6 text-green-600" />
            </div>
          </div>
        )}
        
        <div className="bg-white rounded-xl shadow-sm border p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">First-Time Students</p>
              <p className="text-2xl font-bold text-gray-900 mt-1">
                {reservations.filter(r => r.isFirstTime).length}
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
              placeholder="Search reservations by student, class, or instructor..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
          </div>
          
          <div className="flex flex-wrap items-center gap-3">
            <select
              value={selectedStatus}
              onChange={(e) => setSelectedStatus(e.target.value)}
              className="pl-3 pr-10 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent appearance-none bg-white"
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
              className="pl-3 pr-10 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent appearance-none bg-white"
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
              className="pl-3 pr-10 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent appearance-none bg-white"
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
              className="pl-3 pr-10 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent appearance-none bg-white"
            >
              <option value="date">Sort by Class Date</option>
              <option value="student">Sort by Student</option>
              <option value="class">Sort by Class</option>
              <option value="amount">Sort by Credit Cost</option>
              <option value="booking-date">Sort by Reservation Date</option>
            </select>
          </div>
        </div>

        {/* Bulk Actions */}
        {bulkActions.length > 0 && (
          <div className="mt-4 p-3 bg-blue-50 rounded-lg border border-blue-200">
            <div className="flex items-center justify-between">
              <span className="text-sm text-blue-700">
                {bulkActions.length} reservation{bulkActions.length > 1 ? 's' : ''} selected
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

      {/* Reservations Table */}
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
                        setBulkActions(filteredReservations.map(r => r.id));
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
                {isCreditsEnabled && (
                  <th className="text-left py-3 px-6 font-medium text-gray-900">Credits</th>
                )}
                {isCashEnabled && !isCreditsEnabled && (
                  <th className="text-left py-3 px-6 font-medium text-gray-900">Payment</th>
                )}
                <th className="text-left py-3 px-6 font-medium text-gray-900">Status</th>
                <th className="text-left py-3 px-6 font-medium text-gray-900">Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredReservations.map((reservation) => {
                const StatusIcon = getStatusIcon(reservation.status);
                
                return (
                  <tr key={reservation.id} className="border-b hover:bg-gray-50">
                    <td className="py-4 px-4">
                      <input
                        type="checkbox"
                        checked={bulkActions.includes(reservation.id)}
                        onChange={(e) => {
                          if (e.target.checked) {
                            setBulkActions(prev => [...prev, reservation.id]);
                          } else {
                            setBulkActions(prev => prev.filter(id => id !== reservation.id));
                          }
                        }}
                        className="rounded border-gray-300"
                      />
                    </td>
                    
                    <td className="py-4 px-6">
                      <div className="flex items-center">
                        <div className="h-10 w-10 rounded-full bg-gradient-to-r from-blue-500 to-purple-600 flex items-center justify-center text-white font-semibold mr-3">
                          {reservation.studentName.charAt(0).toUpperCase()}
                        </div>
                        <div>
                          <p className="font-medium text-gray-900">{reservation.studentName}</p>
                          <p className="text-sm text-gray-600">{reservation.studentEmail}</p>
                          {reservation.isFirstTime && (
                            <span className="inline-flex items-center px-2 py-1 rounded-full text-sm font-medium bg-purple-100 text-purple-700 mt-1">
                              <Star className="h-3 w-3 mr-1" />
                              First Time
                            </span>
                          )}
                        </div>
                      </div>
                    </td>
                    
                    <td className="py-4 px-6">
                      <div>
                        <p className="font-medium text-gray-900">{reservation.className}</p>
                        <p className="text-sm text-gray-600">{reservation.instructor}</p>
                        <p className="text-sm text-gray-500">{reservation.location}</p>
                      </div>
                    </td>
                    
                    <td className="py-4 px-6">
                      <div>
                        <p className="font-medium text-gray-900">
                          {new Date(reservation.classDate).toLocaleDateString()}
                        </p>
                        <p className="text-sm text-gray-600">{reservation.classTime}</p>
                      </div>
                    </td>
                    
                    {isCreditsEnabled && (
                      <td className="py-4 px-6">
                        <div>
                          <div className="flex items-center gap-2">
                            <CreditCard className="h-4 w-4 text-blue-600" />
                            <span className="font-medium text-gray-900">{reservation.creditCost} credits</span>
                          </div>
                          <p className="text-sm text-gray-600 mt-1">Balance: {reservation.studentCredits}</p>
                        </div>
                      </td>
                    )}
                    
                    {isCashEnabled && !isCreditsEnabled && (
                      <td className="py-4 px-6">
                        <div className="flex items-center gap-2">
                          <DollarSign className="h-4 w-4 text-green-600" />
                          <span className="font-medium text-gray-900">${reservation.paymentAmount}</span>
                        </div>
                      </td>
                    )}
                    
                    <td className="py-4 px-6">
                      <div className="flex items-center">
                        <StatusIcon className={`h-4 w-4 mr-2 ${
                          reservation.status === 'confirmed' ? 'text-green-600' :
                          reservation.status === 'pending' ? 'text-yellow-600' :
                          reservation.status === 'cancelled' ? 'text-red-600' :
                          'text-gray-600'
                        }`} />
                        <span className={`px-2 py-1 text-sm font-medium rounded-full ${getStatusColor(reservation.status)}`}>
                          {reservation.status}
                        </span>
                      </div>
                      {reservation.hasSpecialRequirements && (
                        <div className="mt-1">
                          <span className="inline-flex items-center px-2 py-1 rounded-full text-sm font-medium bg-orange-100 text-orange-700">
                            <AlertTriangle className="h-3 w-3 mr-1" />
                            Special Requirements
                          </span>
                        </div>
                      )}
                    </td>
                    
                    <td className="py-4 px-6">
                      <div className="flex items-center gap-2">
                        <button
                          onClick={() => handleViewDetails(reservation)}
                          className="p-1 text-gray-500 hover:text-blue-600 hover:bg-blue-50 rounded"
                          title="View Details"
                        >
                          <Eye className="h-4 w-4" />
                        </button>
                        
                        <button
                          onClick={() => handleSendMessage(reservation)}
                          className="p-1 text-gray-500 hover:text-green-600 hover:bg-green-50 rounded"
                          title="Send Message"
                        >
                          <MessageSquare className="h-4 w-4" />
                        </button>
                        
                        {reservation.paymentStatus === 'paid' && (
                          <button
                            onClick={() => handleProcessRefund(reservation)}
                            className="p-1 text-gray-500 hover:text-orange-600 hover:bg-orange-50 rounded"
                            title="Refund Credits"
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
      {filteredReservations.length === 0 && (
        <div className="text-center py-12 bg-white rounded-xl border">
          <Calendar className="h-16 w-16 text-gray-300 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">No reservations found</h3>
          <p className="text-gray-600">
            {searchTerm ? 'Try adjusting your search filters' : 'Reservations will appear here once students start booking classes'}
          </p>
        </div>
      )}

      {/* Modals */}
      <AnimatePresence>
        {isDetailsModalOpen && selectedReservation && (
          <ReservationDetailsModal
            reservation={selectedReservation}
            onClose={() => setIsDetailsModalOpen(false)}
            onStatusChange={handleStatusChange}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {isMessageModalOpen && selectedReservation && (
          <MessageModal
            reservation={selectedReservation}
            onClose={() => setIsMessageModalOpen(false)}
            onSend={(message) => {
              console.log('Sending message:', message);
              setIsMessageModalOpen(false);
            }}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {isRefundModalOpen && selectedReservation && (
          <RefundModal
            reservation={selectedReservation}
            onClose={() => setIsRefundModalOpen(false)}
            onRefund={(refundData) => {
              setReservations(prev => prev.map(reservation => 
                reservation.id === selectedReservation.id 
                  ? { ...reservation, paymentStatus: 'refunded', status: 'cancelled' }
                  : reservation
              ));
              setIsRefundModalOpen(false);
            }}
          />
        )}
      </AnimatePresence>
    </div>
  );
}