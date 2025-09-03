'use client';

import React from 'react';
import { motion } from 'framer-motion';
import {
  X,
  User,
  Mail,
  Phone,
  Calendar,
  MapPin,
  Clock,
  CreditCard,
  AlertTriangle,
  CheckCircle,
  XCircle,
  Receipt,
  Star
} from 'lucide-react';

interface ReservationDetailsModalProps {
  reservation: any;
  onClose: () => void;
  onStatusChange: (reservationId: string, newStatus: string) => void;
}

export default function ReservationDetailsModal({ 
  reservation, 
  onClose, 
  onStatusChange 
}: ReservationDetailsModalProps) {
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
      case 'no-show': return XCircle;
      default: return AlertTriangle;
    }
  };

  const StatusIcon = getStatusIcon(reservation.status);

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <motion.div
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        exit={{ opacity: 0, scale: 0.95 }}
        className="bg-white rounded-xl shadow-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto"
      >
        {/* Header */}
        <div className="px-6 py-4 border-b flex items-center justify-between">
          <div>
            <h2 className="text-xl font-bold text-gray-900">Reservation Details</h2>
            <p className="text-sm text-gray-600 mt-1">ID: {reservation.id}</p>
          </div>
          <button
            onClick={onClose}
            className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <X className="h-5 w-5 text-gray-500" />
          </button>
        </div>

        {/* Content */}
        <div className="p-6 space-y-6">
          {/* Status Section */}
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <StatusIcon className={`h-6 w-6 ${
                reservation.status === 'confirmed' ? 'text-green-600' :
                reservation.status === 'pending' ? 'text-yellow-600' :
                reservation.status === 'cancelled' ? 'text-red-600' :
                'text-gray-600'
              }`} />
              <div>
                <p className="text-sm text-gray-600">Reservation Status</p>
                <span className={`inline-block px-3 py-1 text-sm font-medium rounded-full ${getStatusColor(reservation.status)}`}>
                  {reservation.status}
                </span>
              </div>
            </div>

            <div>
              <p className="text-sm text-gray-600">Payment Status</p>
              <span className={`inline-block px-3 py-1 text-sm font-medium rounded-full ${getPaymentStatusColor(reservation.paymentStatus)}`}>
                {reservation.paymentStatus}
              </span>
            </div>
          </div>

          {/* Student Information */}
          <div className="bg-gray-50 rounded-lg p-4">
            <h3 className="font-semibold text-gray-900 mb-3 flex items-center">
              <User className="h-5 w-5 mr-2 text-gray-600" />
              Student Information
            </h3>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <p className="text-sm text-gray-600">Name</p>
                <p className="font-medium text-gray-900">{reservation.studentName}</p>
                {reservation.isFirstTime && (
                  <span className="inline-flex items-center px-2 py-1 rounded-full text-sm font-medium bg-purple-100 text-purple-700 mt-1">
                    <Star className="h-3 w-3 mr-1" />
                    First Time Student
                  </span>
                )}
              </div>
              <div>
                <p className="text-sm text-gray-600">Email</p>
                <p className="font-medium text-gray-900">{reservation.studentEmail}</p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Phone</p>
                <p className="font-medium text-gray-900">{reservation.studentPhone}</p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Previous Reservations</p>
                <p className="font-medium text-gray-900">{reservation.previousReservations}</p>
              </div>
            </div>
          </div>

          {/* Credit Information */}
          <div className="bg-blue-50 rounded-lg p-4">
            <h3 className="font-semibold text-gray-900 mb-3 flex items-center">
              <CreditCard className="h-5 w-5 mr-2 text-blue-600" />
              Credit Information
            </h3>
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <div>
                <p className="text-sm text-gray-600">Class Credit Cost</p>
                <p className="text-xl font-bold text-blue-600">{reservation.creditCost} credits</p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Student Balance</p>
                <p className="text-xl font-bold text-gray-900">{reservation.studentCredits} credits</p>
              </div>
              <div>
                <p className="text-sm text-gray-600">After Reservation</p>
                <p className="text-xl font-bold text-gray-600">
                  {reservation.studentCredits - reservation.creditCost} credits
                </p>
              </div>
            </div>
            {reservation.paymentMethod === 'credits' && (
              <div className="mt-3 p-2 bg-white rounded border border-blue-200">
                <p className="text-sm text-blue-700">
                  <Receipt className="h-4 w-4 inline mr-1" />
                  Paid with credits from student account
                </p>
              </div>
            )}
          </div>

          {/* Class Information */}
          <div className="bg-gray-50 rounded-lg p-4">
            <h3 className="font-semibold text-gray-900 mb-3 flex items-center">
              <Calendar className="h-5 w-5 mr-2 text-gray-600" />
              Class Information
            </h3>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <p className="text-sm text-gray-600">Class Name</p>
                <p className="font-medium text-gray-900">{reservation.className}</p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Instructor</p>
                <p className="font-medium text-gray-900">{reservation.instructor}</p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Date</p>
                <p className="font-medium text-gray-900">
                  {new Date(reservation.classDate).toLocaleDateString()}
                </p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Time</p>
                <p className="font-medium text-gray-900">{reservation.classTime}</p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Location</p>
                <p className="font-medium text-gray-900 flex items-center">
                  <MapPin className="h-4 w-4 mr-1 text-gray-500" />
                  {reservation.location}
                </p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Reserved On</p>
                <p className="font-medium text-gray-900">
                  {new Date(reservation.reservationDate).toLocaleString()}
                </p>
              </div>
            </div>
          </div>

          {/* Special Requirements */}
          {reservation.hasSpecialRequirements && (
            <div className="bg-orange-50 rounded-lg p-4 border border-orange-200">
              <h3 className="font-semibold text-gray-900 mb-2 flex items-center">
                <AlertTriangle className="h-5 w-5 mr-2 text-orange-600" />
                Special Requirements
              </h3>
              <p className="text-gray-700">{reservation.specialRequirements}</p>
            </div>
          )}

          {/* Notes */}
          {reservation.notes && (
            <div className="bg-gray-50 rounded-lg p-4">
              <h3 className="font-semibold text-gray-900 mb-2">Notes</h3>
              <p className="text-gray-700">{reservation.notes}</p>
            </div>
          )}

          {/* Cancellation Reason */}
          {reservation.cancellationReason && (
            <div className="bg-red-50 rounded-lg p-4 border border-red-200">
              <h3 className="font-semibold text-gray-900 mb-2">Cancellation Reason</h3>
              <p className="text-gray-700">{reservation.cancellationReason}</p>
            </div>
          )}
        </div>

        {/* Footer Actions */}
        <div className="px-6 py-4 border-t bg-gray-50 flex justify-between">
          <div className="flex gap-2">
            {reservation.status === 'pending' && (
              <>
                <button
                  onClick={() => {
                    onStatusChange(reservation.id, 'confirmed');
                    onClose();
                  }}
                  className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
                >
                  Confirm Reservation
                </button>
                <button
                  onClick={() => {
                    onStatusChange(reservation.id, 'cancelled');
                    onClose();
                  }}
                  className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
                >
                  Cancel Reservation
                </button>
              </>
            )}
            {reservation.status === 'confirmed' && (
              <button
                onClick={() => {
                  onStatusChange(reservation.id, 'completed');
                  onClose();
                }}
                className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
              >
                Mark as Completed
              </button>
            )}
          </div>
          <button
            onClick={onClose}
            className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-100 transition-colors"
          >
            Close
          </button>
        </div>
      </motion.div>
    </div>
  );
}