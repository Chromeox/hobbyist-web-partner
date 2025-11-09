'use client';

import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  UserPlus,
  Search,
  Filter,
  Mail,
  Phone,
  Edit3,
  Trash2,
  Eye,
  MoreVertical,
  Users,
  Star,
  Calendar,
  Award,
  Clock,
  MapPin,
  Send,
  Copy,
  CheckCircle,
  XCircle,
  AlertCircle,
  Settings,
  Download,
  DollarSign,
  TrendingUp,
  BarChart3,
  CreditCard,
  CalendarCheck,
  Activity
} from 'lucide-react';
import BackButton from '@/components/common/BackButton';
import StaffInviteModal from './StaffInviteModal';
import StaffDetailsModal from './StaffDetailsModal';

interface Staff {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  role: 'instructor' | 'admin' | 'assistant';
  specialties: string[];
  status: 'active' | 'inactive' | 'pending';
  joinDate: string;
  avatar?: string;
  bio?: string;
  certifications: string[];
  languages: string[];
  hourlyRate?: number;
  totalClasses: number;
  rating: number;
  reviewCount: number;
  availability: {
    [key: string]: string[]; // day -> time slots
  };
  permissions: {
    canCreateClasses: boolean;
    canManageBookings: boolean;
    canViewAnalytics: boolean;
    canManageStudents: boolean;
  };
  lastActive: string;
  // Enhanced features for Phase 3
  payroll?: {
    monthlyEarnings: number;
    totalEarnings: number;
    hoursWorked: number;
    commissionRate: number; // percentage
    bonusEligible: boolean;
    nextPayDate: string;
  };
  performance?: {
    attendanceRate: number; // percentage
    studentRetention: number; // percentage
    classCapacityAvg: number; // percentage
    cancellationRate: number; // percentage
    monthlyGoal: number;
    currentProgress: number;
  };
  schedule?: {
    upcomingClasses: number;
    weeklyHours: number;
    preferredSlots: string[];
    blackoutDates: string[];
  };
}

const mockStaff: Staff[] = [
  {
    id: '1',
    firstName: 'Sarah',
    lastName: 'Johnson',
    email: 'sarah.j@studio.com',
    phone: '(555) 123-4567',
    role: 'instructor',
    specialties: ['Yoga', 'Meditation', 'Breathwork'],
    status: 'active',
    joinDate: '2024-01-15',
    bio: 'Certified yoga instructor with 8+ years of experience',
    certifications: ['RYT-500', 'Meditation Teacher Certification'],
    languages: ['English', 'Spanish'],
    hourlyRate: 75,
    totalClasses: 245,
    rating: 4.9,
    reviewCount: 89,
    availability: {
      monday: ['9:00-12:00', '14:00-18:00'],
      wednesday: ['9:00-12:00', '14:00-18:00'],
      friday: ['9:00-12:00', '14:00-18:00'],
      saturday: ['8:00-16:00']
    },
    permissions: {
      canCreateClasses: true,
      canManageBookings: true,
      canViewAnalytics: false,
      canManageStudents: false
    },
    lastActive: '2025-08-08T14:30:00Z',
    payroll: {
      monthlyEarnings: 4875,
      totalEarnings: 28650,
      hoursWorked: 65,
      commissionRate: 70,
      bonusEligible: true,
      nextPayDate: '2025-09-15'
    },
    performance: {
      attendanceRate: 96,
      studentRetention: 89,
      classCapacityAvg: 85,
      cancellationRate: 3,
      monthlyGoal: 5000,
      currentProgress: 4875
    },
    schedule: {
      upcomingClasses: 12,
      weeklyHours: 16,
      preferredSlots: ['morning', 'afternoon'],
      blackoutDates: ['2025-09-20', '2025-09-21']
    }
  },
  {
    id: '2',
    firstName: 'Mike',
    lastName: 'Chen',
    email: 'mike.c@studio.com',
    phone: '(555) 234-5678',
    role: 'instructor',
    specialties: ['Pilates', 'Strength Training', 'Rehabilitation'],
    status: 'active',
    joinDate: '2024-03-20',
    bio: 'Former physical therapist turned pilates instructor',
    certifications: ['PMA Certified', 'Physical Therapy License'],
    languages: ['English', 'Mandarin'],
    hourlyRate: 80,
    totalClasses: 156,
    rating: 4.8,
    reviewCount: 67,
    availability: {
      tuesday: ['10:00-18:00'],
      thursday: ['10:00-18:00'],
      saturday: ['9:00-15:00'],
      sunday: ['10:00-16:00']
    },
    permissions: {
      canCreateClasses: true,
      canManageBookings: true,
      canViewAnalytics: false,
      canManageStudents: false
    },
    lastActive: '2025-08-08T12:15:00Z',
    payroll: {
      monthlyEarnings: 3840,
      totalEarnings: 18720,
      hoursWorked: 48,
      commissionRate: 70,
      bonusEligible: true,
      nextPayDate: '2025-09-15'
    },
    performance: {
      attendanceRate: 94,
      studentRetention: 85,
      classCapacityAvg: 78,
      cancellationRate: 5,
      monthlyGoal: 4000,
      currentProgress: 3840
    },
    schedule: {
      upcomingClasses: 8,
      weeklyHours: 20,
      preferredSlots: ['late-morning', 'afternoon'],
      blackoutDates: []
    }
  },
  {
    id: '3',
    firstName: 'Emily',
    lastName: 'Davis',
    email: 'emily.d@studio.com',
    phone: '(555) 345-6789',
    role: 'admin',
    specialties: ['Dance', 'Movement Therapy'],
    status: 'active',
    joinDate: '2023-11-10',
    bio: 'Studio manager and contemporary dance instructor',
    certifications: ['Dance Movement Therapy', 'Studio Management'],
    languages: ['English', 'French'],
    hourlyRate: 70,
    totalClasses: 203,
    rating: 4.7,
    reviewCount: 124,
    availability: {
      monday: ['9:00-17:00'],
      tuesday: ['9:00-17:00'],
      wednesday: ['9:00-17:00'],
      thursday: ['9:00-17:00'],
      friday: ['9:00-17:00']
    },
    permissions: {
      canCreateClasses: true,
      canManageBookings: true,
      canViewAnalytics: true,
      canManageStudents: true
    },
    lastActive: '2025-08-08T16:45:00Z'
  },
  {
    id: '4',
    firstName: 'Alex',
    lastName: 'Rivera',
    email: 'alex.r@studio.com',
    phone: '(555) 456-7890',
    role: 'instructor',
    specialties: ['Yoga', 'Fitness'],
    status: 'pending',
    joinDate: '2025-08-05',
    bio: 'New instructor specializing in power yoga',
    certifications: ['RYT-200'],
    languages: ['English'],
    hourlyRate: 65,
    totalClasses: 0,
    rating: 0,
    reviewCount: 0,
    availability: {},
    permissions: {
      canCreateClasses: false,
      canManageBookings: false,
      canViewAnalytics: false,
      canManageStudents: false
    },
    lastActive: ''
  }
];

export default function StaffManagement() {
  const [staff, setStaff] = useState<Staff[]>(mockStaff);
  const [filteredStaff, setFilteredStaff] = useState<Staff[]>(mockStaff);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedRole, setSelectedRole] = useState('all');
  const [selectedStatus, setSelectedStatus] = useState('all');
  const [sortBy, setSortBy] = useState('name');
  const [selectedStaff, setSelectedStaff] = useState<Staff | null>(null);
  const [isInviteModalOpen, setIsInviteModalOpen] = useState(false);
  const [isDetailsModalOpen, setIsDetailsModalOpen] = useState(false);
  const [deleteConfirm, setDeleteConfirm] = useState<string | null>(null);

  const roles = ['all', 'instructor', 'admin', 'assistant'];
  const statuses = ['all', 'active', 'inactive', 'pending'];

  // Filter and sort staff
  useEffect(() => {
    let filtered = staff.filter(member => {
      const fullName = `${member.firstName} ${member.lastName}`.toLowerCase();
      const matchesSearch = fullName.includes(searchTerm.toLowerCase()) ||
                           member.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
                           member.specialties.some(s => s.toLowerCase().includes(searchTerm.toLowerCase()));
      const matchesRole = selectedRole === 'all' || member.role === selectedRole;
      const matchesStatus = selectedStatus === 'all' || member.status === selectedStatus;
      
      return matchesSearch && matchesRole && matchesStatus;
    });

    // Sort staff
    filtered.sort((a, b) => {
      switch (sortBy) {
        case 'name':
          return `${a.firstName} ${a.lastName}`.localeCompare(`${b.firstName} ${b.lastName}`);
        case 'role':
          return a.role.localeCompare(b.role);
        case 'joinDate':
          return new Date(b.joinDate).getTime() - new Date(a.joinDate).getTime();
        case 'rating':
          return b.rating - a.rating;
        case 'classes':
          return b.totalClasses - a.totalClasses;
        default:
          return 0;
      }
    });

    setFilteredStaff(filtered);
  }, [staff, searchTerm, selectedRole, selectedStatus, sortBy]);

  const handleInviteStaff = (inviteData: any) => {
    const newStaffMember: Staff = {
      id: Date.now().toString(),
      firstName: inviteData.firstName,
      lastName: inviteData.lastName,
      email: inviteData.email,
      phone: inviteData.phone || '',
      role: inviteData.role,
      specialties: inviteData.specialties || [],
      status: 'pending',
      joinDate: new Date().toISOString().split('T')[0],
      bio: inviteData.bio || '',
      certifications: inviteData.certifications || [],
      languages: ['English'],
      hourlyRate: inviteData.hourlyRate,
      totalClasses: 0,
      rating: 0,
      reviewCount: 0,
      availability: {},
      permissions: inviteData.permissions,
      lastActive: ''
    };
    
    setStaff(prev => [newStaffMember, ...prev]);
    setIsInviteModalOpen(false);
  };

  const handleDeleteStaff = (staffId: string) => {
    setStaff(prev => prev.filter(member => member.id !== staffId));
    setDeleteConfirm(null);
  };

  const handleResendInvite = (member: Staff) => {
    // In a real app, this would send an API request
    alert(`Invitation resent to ${member.email}`);
  };

  const getRoleColor = (role: string) => {
    switch (role) {
      case 'admin': return 'bg-purple-100 text-purple-700';
      case 'instructor': return 'bg-blue-100 text-blue-700';
      case 'assistant': return 'bg-green-100 text-green-700';
      default: return 'bg-gray-100 text-gray-700';
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active': return 'bg-green-100 text-green-700';
      case 'inactive': return 'bg-gray-100 text-gray-700';
      case 'pending': return 'bg-yellow-100 text-yellow-700';
      default: return 'bg-gray-100 text-gray-700';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'active': return CheckCircle;
      case 'inactive': return XCircle;
      case 'pending': return Clock;
      default: return AlertCircle;
    }
  };

  return (
    <div className="space-y-6">
      <BackButton href="/dashboard" className="mb-4" />
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Staff Management</h1>
          <p className="text-gray-600 mt-1">Manage your studio team and permissions</p>
        </div>
        
        <div className="flex items-center gap-3">
          <button className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors flex items-center">
            <Download className="h-4 w-4 mr-2" />
            Export
          </button>
          
          <button
            onClick={() => setIsInviteModalOpen(true)}
            className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors flex items-center"
          >
            <UserPlus className="h-4 w-4 mr-2" />
            Invite Staff
          </button>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
        <div className="bg-white rounded-xl shadow-sm border p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Total Staff</p>
              <p className="text-2xl font-bold text-gray-900 mt-1">{staff.length}</p>
            </div>
            <Users className="h-8 w-8 text-blue-600" />
          </div>
        </div>
        
        <div className="bg-white rounded-xl shadow-sm border p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Active Instructors</p>
              <p className="text-2xl font-bold text-gray-900 mt-1">
                {staff.filter(s => s.role === 'instructor' && s.status === 'active').length}
              </p>
            </div>
            <Award className="h-8 w-8 text-green-600" />
          </div>
        </div>
        
        <div className="bg-white rounded-xl shadow-sm border p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Pending Invites</p>
              <p className="text-2xl font-bold text-gray-900 mt-1">
                {staff.filter(s => s.status === 'pending').length}
              </p>
            </div>
            <Clock className="h-8 w-8 text-yellow-600" />
          </div>
        </div>
        
        <div className="bg-white rounded-xl shadow-sm border p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Avg Rating</p>
              <p className="text-2xl font-bold text-gray-900 mt-1">
                {(staff.filter(s => s.rating > 0).reduce((acc, s) => acc + s.rating, 0) / 
                  staff.filter(s => s.rating > 0).length || 0).toFixed(1)}
              </p>
            </div>
            <Star className="h-8 w-8 text-yellow-500" />
          </div>
        </div>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-lg border p-4">
        <div className="flex flex-col lg:flex-row gap-4 items-center">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
            <input
              type="text"
              placeholder="Search staff by name, email, or specialty..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
          </div>
          
          <div className="flex items-center gap-3">
            <select
              value={selectedRole}
              onChange={(e) => setSelectedRole(e.target.value)}
              className="pl-3 pr-10 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent appearance-none bg-white"
            >
              {roles.map(role => (
                <option key={role} value={role}>
                  {role === 'all' ? 'All Roles' : role.charAt(0).toUpperCase() + role.slice(1)}
                </option>
              ))}
            </select>
            
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
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value)}
              className="pl-3 pr-10 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent appearance-none bg-white"
            >
              <option value="name">Sort by Name</option>
              <option value="role">Sort by Role</option>
              <option value="joinDate">Sort by Join Date</option>
              <option value="rating">Sort by Rating</option>
              <option value="classes">Sort by Classes</option>
            </select>
          </div>
        </div>
      </div>

      {/* Staff List */}
      <div className="bg-white rounded-xl shadow-sm border overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b">
              <tr>
                <th className="text-left py-3 px-6 font-medium text-gray-900">Staff Member</th>
                <th className="text-left py-3 px-6 font-medium text-gray-900">Role</th>
                <th className="text-left py-3 px-6 font-medium text-gray-900">Specialties</th>
                <th className="text-left py-3 px-6 font-medium text-gray-900">Status</th>
                <th className="text-left py-3 px-6 font-medium text-gray-900">Performance</th>
                <th className="text-left py-3 px-6 font-medium text-gray-900">Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredStaff.map((member) => {
                const StatusIcon = getStatusIcon(member.status);
                
                return (
                  <tr key={member.id} className="border-b hover:bg-gray-50">
                    <td className="py-4 px-6">
                      <div className="flex items-center">
                        <div className="h-10 w-10 rounded-full bg-gradient-to-r from-blue-500 to-purple-600 flex items-center justify-center text-white font-semibold mr-3">
                          {member.firstName.charAt(0)}{member.lastName.charAt(0)}
                        </div>
                        <div>
                          <p className="font-medium text-gray-900">
                            {member.firstName} {member.lastName}
                          </p>
                          <p className="text-sm text-gray-600">{member.email}</p>
                        </div>
                      </div>
                    </td>
                    
                    <td className="py-4 px-6">
                      <span className={`px-2 py-1 text-sm font-medium rounded-full ${getRoleColor(member.role)}`}>
                        {member.role}
                      </span>
                    </td>
                    
                    <td className="py-4 px-6">
                      <div className="flex flex-wrap gap-1">
                        {member.specialties.slice(0, 2).map((specialty) => (
                          <span key={specialty} className="px-2 py-1 text-xs bg-gray-100 text-gray-700 rounded">
                            {specialty}
                          </span>
                        ))}
                        {member.specialties.length > 2 && (
                          <span className="px-2 py-1 text-xs bg-gray-100 text-gray-700 rounded">
                            +{member.specialties.length - 2}
                          </span>
                        )}
                      </div>
                    </td>
                    
                    <td className="py-4 px-6">
                      <div className="flex items-center">
                        <StatusIcon className={`h-4 w-4 mr-2 ${
                          member.status === 'active' ? 'text-green-600' :
                          member.status === 'pending' ? 'text-yellow-600' :
                          'text-gray-600'
                        }`} />
                        <span className={`px-2 py-1 text-sm font-medium rounded-full ${getStatusColor(member.status)}`}>
                          {member.status}
                        </span>
                      </div>
                    </td>
                    
                    <td className="py-4 px-6">
                      {member.status === 'active' && member.rating > 0 ? (
                        <div>
                          <div className="flex items-center">
                            <Star className="h-4 w-4 text-yellow-500 mr-1" />
                            <span className="text-sm font-medium">{member.rating}</span>
                            <span className="text-sm text-gray-500 ml-1">({member.reviewCount})</span>
                          </div>
                          <p className="text-sm text-gray-600 mt-1">{member.totalClasses} classes</p>
                        </div>
                      ) : (
                        <span className="text-sm text-gray-400">No data</span>
                      )}
                    </td>
                    
                    <td className="py-4 px-6">
                      <div className="flex items-center gap-2">
                        <button
                          onClick={() => {
                            setSelectedStaff(member);
                            setIsDetailsModalOpen(true);
                          }}
                          className="p-1 text-gray-500 hover:text-blue-600 hover:bg-blue-50 rounded"
                        >
                          <Eye className="h-4 w-4" />
                        </button>
                        
                        <button className="p-1 text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded">
                          <Edit3 className="h-4 w-4" />
                        </button>
                        
                        {member.status === 'pending' && (
                          <button
                            onClick={() => handleResendInvite(member)}
                            className="p-1 text-gray-500 hover:text-green-600 hover:bg-green-50 rounded"
                          >
                            <Send className="h-4 w-4" />
                          </button>
                        )}
                        
                        <button
                          onClick={() => setDeleteConfirm(member.id)}
                          className="p-1 text-gray-500 hover:text-red-600 hover:bg-red-50 rounded"
                        >
                          <Trash2 className="h-4 w-4" />
                        </button>
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
      {filteredStaff.length === 0 && (
        <div className="text-center py-12 bg-white rounded-xl border">
          <Users className="h-16 w-16 text-gray-300 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">No staff members found</h3>
          <p className="text-gray-600 mb-4">
            {searchTerm ? 'Try adjusting your search filters' : 'Get started by inviting your first staff member'}
          </p>
          <button
            onClick={() => setIsInviteModalOpen(true)}
            className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            Invite Staff Member
          </button>
        </div>
      )}

      {/* Modals */}
      <AnimatePresence>
        {isInviteModalOpen && (
          <StaffInviteModal
            onInvite={handleInviteStaff}
            onClose={() => setIsInviteModalOpen(false)}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {isDetailsModalOpen && selectedStaff && (
          <StaffDetailsModal
            staff={selectedStaff}
            onClose={() => setIsDetailsModalOpen(false)}
            onUpdate={(updatedStaff) => {
              setStaff(prev => prev.map(s => s.id === updatedStaff.id ? updatedStaff : s));
              setIsDetailsModalOpen(false);
            }}
          />
        )}
      </AnimatePresence>

      {/* Delete Confirmation */}
      <AnimatePresence>
        {deleteConfirm && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4"
          >
            <motion.div
              initial={{ scale: 0.95, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.95, opacity: 0 }}
              className="bg-white rounded-xl shadow-xl max-w-md w-full p-6"
            >
              <div className="flex items-center mb-4">
                <AlertCircle className="h-6 w-6 text-red-600 mr-3" />
                <h3 className="text-xl font-semibold text-gray-900">Remove Staff Member</h3>
              </div>
              
              <p className="text-gray-600 mb-6">
                Are you sure you want to remove this staff member? This action cannot be undone.
              </p>
              
              <div className="flex items-center gap-3">
                <button
                  onClick={() => setDeleteConfirm(null)}
                  className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={() => handleDeleteStaff(deleteConfirm)}
                  className="flex-1 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
                >
                  Remove
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
