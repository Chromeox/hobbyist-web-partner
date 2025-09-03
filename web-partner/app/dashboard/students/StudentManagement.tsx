'use client';

import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Search,
  Filter,
  Users,
  UserPlus,
  MoreVertical,
  Mail,
  Phone,
  Calendar,
  Star,
  TrendingUp,
  Award,
  AlertCircle,
  CheckCircle,
  Clock,
  Download,
  ChevronDown,
  User,
  Activity,
  BookOpen,
  CreditCard,
  MapPin,
  Hash
} from 'lucide-react';

interface Student {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  joinedDate: string;
  lastActive: string;
  totalClasses: number;
  upcomingClasses: number;
  membershipStatus: 'active' | 'inactive' | 'paused';
  membershipType: 'drop-in' | 'monthly' | 'annual';
  totalSpent: number;
  averageRating: number;
  tags: string[];
  address?: string;
  emergencyContact?: string;
  notes?: string;
  profileImage?: string;
}

// Mock data with realistic student information
const mockStudents: Student[] = [
  {
    id: '1',
    firstName: 'Emma',
    lastName: 'Thompson',
    email: 'emma.t@email.com',
    phone: '(604) 555-0101',
    joinedDate: '2024-06-15',
    lastActive: '2025-08-30',
    totalClasses: 45,
    upcomingClasses: 3,
    membershipStatus: 'active',
    membershipType: 'monthly',
    totalSpent: 1125,
    averageRating: 4.9,
    tags: ['regular', 'yoga', 'pilates'],
    address: '123 Main St, Vancouver, BC',
    profileImage: '/avatars/emma.jpg'
  },
  {
    id: '2',
    firstName: 'Michael',
    lastName: 'Chen',
    email: 'michael.chen@email.com',
    phone: '(604) 555-0102',
    joinedDate: '2024-09-20',
    lastActive: '2025-08-28',
    totalClasses: 28,
    upcomingClasses: 2,
    membershipStatus: 'active',
    membershipType: 'annual',
    totalSpent: 2400,
    averageRating: 4.7,
    tags: ['premium', 'fitness', 'spin'],
    address: '456 Oak Ave, Vancouver, BC'
  },
  {
    id: '3',
    firstName: 'Sarah',
    lastName: 'Johnson',
    email: 'sarah.j@email.com',
    phone: '(604) 555-0103',
    joinedDate: '2025-01-10',
    lastActive: '2025-08-25',
    totalClasses: 12,
    upcomingClasses: 0,
    membershipStatus: 'paused',
    membershipType: 'drop-in',
    totalSpent: 300,
    averageRating: 4.5,
    tags: ['beginner', 'yoga'],
    address: '789 Pine St, Vancouver, BC'
  }
];

export default function StudentManagement() {
  const [students, setStudents] = useState<Student[]>(mockStudents);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState<string>('all');
  const [selectedStudent, setSelectedStudent] = useState<Student | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('list');

  // Skeleton loader component
  const SkeletonLoader = () => (
    <div className="animate-pulse">
      <div className="h-20 bg-gray-200 rounded-lg mb-3"></div>
      <div className="h-20 bg-gray-200 rounded-lg mb-3"></div>
      <div className="h-20 bg-gray-200 rounded-lg mb-3"></div>
    </div>
  );

  // Filter students based on search and status
  const filteredStudents = students.filter(student => {
    const matchesSearch = 
      student.firstName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      student.lastName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      student.email.toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesFilter = filterStatus === 'all' || student.membershipStatus === filterStatus;
    
    return matchesSearch && matchesFilter;
  });

  // Simulate loading
  useEffect(() => {
    setIsLoading(true);
    setTimeout(() => setIsLoading(false), 1000);
  }, []);

  return (
    <div className="space-y-6">
      {/* Header with Actions */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Students</h1>
          <p className="text-base text-gray-600 mt-1">
            Manage your {students.length} registered students
          </p>
        </div>
        <div className="flex gap-3">
          <button className="px-4 py-2 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors flex items-center gap-2 text-sm font-medium">
            <Download className="h-4 w-4" />
            Export
          </button>
          <button className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors flex items-center gap-2 text-sm font-medium">
            <UserPlus className="h-4 w-4" />
            Add Student
          </button>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-white rounded-xl border p-5 hover:shadow-md transition-shadow"
        >
          <div className="flex items-center justify-between mb-3">
            <div className="p-2 bg-blue-100 rounded-lg">
              <Users className="h-5 w-5 text-blue-600" />
            </div>
            <span className="text-sm font-medium text-green-600 flex items-center">
              <TrendingUp className="h-3 w-3 mr-1" />
              12%
            </span>
          </div>
          <p className="text-sm text-gray-600">Total Students</p>
          <p className="text-xl font-bold text-gray-900">{students.length}</p>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="bg-white rounded-xl border p-5 hover:shadow-md transition-shadow"
        >
          <div className="flex items-center justify-between mb-3">
            <div className="p-2 bg-green-100 rounded-lg">
              <CheckCircle className="h-5 w-5 text-green-600" />
            </div>
            <span className="text-sm font-medium text-green-600">Active</span>
          </div>
          <p className="text-sm text-gray-600">Active Members</p>
          <p className="text-xl font-bold text-gray-900">
            {students.filter(s => s.membershipStatus === 'active').length}
          </p>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="bg-white rounded-xl border p-5 hover:shadow-md transition-shadow"
        >
          <div className="flex items-center justify-between mb-3">
            <div className="p-2 bg-purple-100 rounded-lg">
              <Activity className="h-5 w-5 text-purple-600" />
            </div>
            <span className="text-sm font-medium text-gray-600">This week</span>
          </div>
          <p className="text-sm text-gray-600">Class Attendance</p>
          <p className="text-xl font-bold text-gray-900">89%</p>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="bg-white rounded-xl border p-5 hover:shadow-md transition-shadow"
        >
          <div className="flex items-center justify-between mb-3">
            <div className="p-2 bg-yellow-100 rounded-lg">
              <Star className="h-5 w-5 text-yellow-600" />
            </div>
          </div>
          <p className="text-sm text-gray-600">Avg. Satisfaction</p>
          <p className="text-xl font-bold text-gray-900">4.8/5.0</p>
        </motion.div>
      </div>

      {/* Search and Filter Bar */}
      <div className="bg-white rounded-xl border p-4">
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
            <input
              type="text"
              placeholder="Search students by name or email..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent text-sm"
            />
          </div>
          <div className="flex gap-2">
            <select
              value={filterStatus}
              onChange={(e) => setFilterStatus(e.target.value)}
              className="px-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 text-sm"
            >
              <option value="all">All Status</option>
              <option value="active">Active</option>
              <option value="inactive">Inactive</option>
              <option value="paused">Paused</option>
            </select>
            <button className="px-4 py-2.5 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors">
              <Filter className="h-5 w-5 text-gray-600" />
            </button>
          </div>
        </div>
      </div>

      {/* Students List/Grid */}
      <div className="bg-white rounded-xl border overflow-hidden">
        {isLoading ? (
          <div className="p-6">
            <SkeletonLoader />
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50 border-b">
                <tr>
                  <th className="px-6 py-4 text-left text-sm font-medium text-gray-600 uppercase tracking-wider">
                    Student
                  </th>
                  <th className="px-6 py-4 text-left text-sm font-medium text-gray-600 uppercase tracking-wider">
                    Membership
                  </th>
                  <th className="px-6 py-4 text-left text-sm font-medium text-gray-600 uppercase tracking-wider">
                    Classes
                  </th>
                  <th className="px-6 py-4 text-left text-sm font-medium text-gray-600 uppercase tracking-wider">
                    Last Active
                  </th>
                  <th className="px-6 py-4 text-left text-sm font-medium text-gray-600 uppercase tracking-wider">
                    Total Spent
                  </th>
                  <th className="px-6 py-4 text-right text-sm font-medium text-gray-600 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                <AnimatePresence>
                  {filteredStudents.map((student, index) => (
                    <motion.tr
                      key={student.id}
                      initial={{ opacity: 0, x: -20 }}
                      animate={{ opacity: 1, x: 0 }}
                      transition={{ delay: index * 0.05 }}
                      className="hover:bg-gray-50 transition-colors"
                    >
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="flex items-center">
                          <div className="h-10 w-10 flex-shrink-0">
                            <div className="h-10 w-10 rounded-full bg-gradient-to-r from-blue-500 to-indigo-600 flex items-center justify-center text-white font-semibold text-sm">
                              {student.firstName[0]}{student.lastName[0]}
                            </div>
                          </div>
                          <div className="ml-4">
                            <div className="text-sm font-medium text-gray-900">
                              {student.firstName} {student.lastName}
                            </div>
                            <div className="text-sm text-gray-500">{student.email}</div>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-sm font-medium ${
                          student.membershipStatus === 'active' 
                            ? 'bg-green-100 text-green-800'
                            : student.membershipStatus === 'paused'
                            ? 'bg-yellow-100 text-yellow-800'
                            : 'bg-gray-100 text-gray-800'
                        }`}>
                          {student.membershipStatus}
                        </span>
                        <span className="ml-2 text-sm text-gray-500">
                          {student.membershipType}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-gray-900">{student.totalClasses} total</div>
                        <div className="text-sm text-gray-500">{student.upcomingClasses} upcoming</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {new Date(student.lastActive).toLocaleDateString()}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                        ${student.totalSpent.toLocaleString()}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                        <button 
                          onClick={() => setSelectedStudent(student)}
                          className="text-blue-600 hover:text-blue-900 mr-3"
                        >
                          View
                        </button>
                        <button className="text-gray-400 hover:text-gray-600">
                          <MoreVertical className="h-5 w-5" />
                        </button>
                      </td>
                    </motion.tr>
                  ))}
                </AnimatePresence>
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Student Details Modal */}
      <AnimatePresence>
        {selectedStudent && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50"
            onClick={() => setSelectedStudent(null)}
          >
            <motion.div
              initial={{ scale: 0.95, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.95, opacity: 0 }}
              className="bg-white rounded-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto"
              onClick={(e) => e.stopPropagation()}
            >
              <div className="p-6 border-b">
                <h2 className="text-xl font-bold text-gray-900">Student Details</h2>
              </div>
              <div className="p-6 space-y-6">
                <div className="flex items-start gap-4">
                  <div className="h-20 w-20 rounded-full bg-gradient-to-r from-blue-500 to-indigo-600 flex items-center justify-center text-white font-bold text-2xl">
                    {selectedStudent.firstName[0]}{selectedStudent.lastName[0]}
                  </div>
                  <div>
                    <h3 className="text-xl font-semibold text-gray-900">
                      {selectedStudent.firstName} {selectedStudent.lastName}
                    </h3>
                    <p className="text-sm text-gray-600">{selectedStudent.email}</p>
                    <p className="text-sm text-gray-600">{selectedStudent.phone}</p>
                    <div className="flex gap-2 mt-2">
                      {selectedStudent.tags.map(tag => (
                        <span key={tag} className="px-2 py-1 bg-blue-100 text-blue-700 text-xs rounded-full">
                          {tag}
                        </span>
                      ))}
                    </div>
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div className="bg-gray-50 rounded-lg p-4">
                    <p className="text-sm text-gray-600 mb-1">Member Since</p>
                    <p className="text-lg font-semibold text-gray-900">
                      {new Date(selectedStudent.joinedDate).toLocaleDateString()}
                    </p>
                  </div>
                  <div className="bg-gray-50 rounded-lg p-4">
                    <p className="text-sm text-gray-600 mb-1">Total Classes</p>
                    <p className="text-lg font-semibold text-gray-900">
                      {selectedStudent.totalClasses}
                    </p>
                  </div>
                  <div className="bg-gray-50 rounded-lg p-4">
                    <p className="text-sm text-gray-600 mb-1">Total Spent</p>
                    <p className="text-lg font-semibold text-gray-900">
                      ${selectedStudent.totalSpent}
                    </p>
                  </div>
                  <div className="bg-gray-50 rounded-lg p-4">
                    <p className="text-sm text-gray-600 mb-1">Avg. Rating</p>
                    <p className="text-lg font-semibold text-gray-900">
                      {selectedStudent.averageRating}/5.0
                    </p>
                  </div>
                </div>

                <div className="flex gap-3">
                  <button className="flex-1 px-4 py-2.5 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors text-sm font-medium">
                    Send Message
                  </button>
                  <button className="flex-1 px-4 py-2.5 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors text-sm font-medium">
                    View History
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