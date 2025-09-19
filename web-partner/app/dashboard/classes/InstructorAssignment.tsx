'use client';

import React, { useState, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  X,
  Calendar,
  Clock,
  User,
  Mail,
  Phone,
  Star,
  Award,
  CheckCircle,
  Plus,
  Edit3,
  Search,
  Download,
  TrendingUp,
  BookOpen,
  ChevronDown,
  ChevronUp,
  Settings,
  MessageSquare
} from 'lucide-react';
import type {
  Instructor,
  ClassAssignment,
  InstructorAssignmentProps
} from '../../../types/class-management';
import {
  getStatusColor,
  formatTime,
  formatDate,
  getDayName,
  searchFilter,
  modalVariants,
  listItemVariants
} from '../../../lib/utils/class-management-utils';

// Mock data - in production this would come from API

const mockInstructors: Instructor[] = [
  {
    id: 'inst_1',
    name: 'Sarah Johnson',
    email: 'sarah@studio.com',
    phone: '+1-555-0101',
    specialties: ['Pottery', 'Ceramics', 'Sculpture'],
    yearsExperience: 8,
    rating: 4.9,
    totalClasses: 156,
    totalRevenue: 23400,
    status: 'active',
    joinDate: '2023-01-15',
    hourlyRate: 75,
    commissionRate: 25,
    availability: {
      monday: { available: true, startTime: '09:00', endTime: '17:00' },
      tuesday: { available: true, startTime: '09:00', endTime: '17:00' },
      wednesday: { available: true, startTime: '09:00', endTime: '15:00' },
      thursday: { available: true, startTime: '09:00', endTime: '17:00' },
      friday: { available: true, startTime: '09:00', endTime: '17:00' },
      saturday: { available: true, startTime: '10:00', endTime: '16:00' },
      sunday: { available: false }
    },
    certifications: ['Ceramics Master Craftsperson', 'Teaching Excellence Award'],
    bio: 'Professional potter with 8+ years of experience in wheel throwing and glazing techniques.',
    languages: ['English', 'Spanish'],
    preferredClassTypes: ['Beginner Pottery', 'Advanced Throwing', 'Glazing Workshop'],
    maxClassesPerDay: 3,
    notificationPreferences: {
      email: true,
      sms: true,
      push: false
    }
  },
  {
    id: 'inst_2',
    name: 'Mike Chen',
    email: 'mike@studio.com',
    phone: '+1-555-0102',
    specialties: ['Watercolor', 'Oil Painting', 'Drawing'],
    yearsExperience: 12,
    rating: 4.8,
    totalClasses: 203,
    totalRevenue: 30450,
    status: 'active',
    joinDate: '2022-08-20',
    hourlyRate: 80,
    commissionRate: 30,
    availability: {
      monday: { available: true, startTime: '10:00', endTime: '18:00' },
      tuesday: { available: true, startTime: '10:00', endTime: '18:00' },
      wednesday: { available: false },
      thursday: { available: true, startTime: '10:00', endTime: '18:00' },
      friday: { available: true, startTime: '10:00', endTime: '18:00' },
      saturday: { available: true, startTime: '09:00', endTime: '15:00' },
      sunday: { available: true, startTime: '12:00', endTime: '17:00' }
    },
    certifications: ['Fine Arts Degree', 'Adult Education Certificate'],
    bio: 'Award-winning watercolor artist specializing in landscape and portrait techniques.',
    languages: ['English', 'Mandarin'],
    preferredClassTypes: ['Watercolor Basics', 'Landscape Painting', 'Portrait Workshop'],
    maxClassesPerDay: 4,
    notificationPreferences: {
      email: true,
      sms: false,
      push: true
    }
  },
  {
    id: 'inst_3',
    name: 'Emily Davis',
    email: 'emily@studio.com',
    specialties: ['Floral Design', 'Botanical Art', 'Dried Flowers'],
    yearsExperience: 5,
    rating: 4.7,
    totalClasses: 89,
    totalRevenue: 13350,
    status: 'active',
    joinDate: '2024-01-10',
    hourlyRate: 65,
    commissionRate: 20,
    availability: {
      monday: { available: false },
      tuesday: { available: true, startTime: '09:00', endTime: '15:00' },
      wednesday: { available: true, startTime: '09:00', endTime: '15:00' },
      thursday: { available: true, startTime: '09:00', endTime: '15:00' },
      friday: { available: true, startTime: '09:00', endTime: '15:00' },
      saturday: { available: true, startTime: '08:00', endTime: '14:00' },
      sunday: { available: true, startTime: '10:00', endTime: '16:00' }
    },
    certifications: ['Certified Floral Designer', 'Botanical Art Certificate'],
    bio: 'Creative floral designer with expertise in seasonal arrangements and botanical preservation.',
    languages: ['English', 'French'],
    preferredClassTypes: ['Bouquet Making', 'Dried Flower Art', 'Seasonal Arrangements'],
    maxClassesPerDay: 2,
    notificationPreferences: {
      email: true,
      sms: true,
      push: true
    }
  }
];

const mockAssignments: ClassAssignment[] = [
  {
    id: 'assign_1',
    classId: 'class_1',
    className: 'Pottery Wheel Basics',
    instructorId: 'inst_1',
    date: '2025-09-19',
    startTime: '09:00',
    endTime: '11:00',
    status: 'confirmed',
    students: 7,
    capacity: 8,
    revenue: 455,
    instructorPayout: 150,
    location: 'Ceramics Studio',
    substitutes: ['inst_2']
  },
  {
    id: 'assign_2',
    classId: 'class_2',
    className: 'Watercolor Landscapes',
    instructorId: 'inst_2',
    date: '2025-09-19',
    startTime: '10:30',
    endTime: '12:00',
    status: 'confirmed',
    students: 8,
    capacity: 12,
    revenue: 360,
    instructorPayout: 120,
    location: 'Art Studio'
  },
  {
    id: 'assign_3',
    classId: 'class_3',
    className: 'Flower Bouquet Workshop',
    instructorId: 'inst_3',
    date: '2025-09-19',
    startTime: '14:00',
    endTime: '15:30',
    status: 'confirmed',
    students: 9,
    capacity: 10,
    revenue: 495,
    instructorPayout: 97.5,
    location: 'Garden Room'
  }
];

export default function InstructorAssignment({ onClose, onSave }: InstructorAssignmentProps) {
  const [activeTab, setActiveTab] = useState<'instructors' | 'assignments' | 'availability' | 'performance'>('instructors');
  const [instructors, setInstructors] = useState<Instructor[]>(mockInstructors);
  const [assignments, setAssignments] = useState<ClassAssignment[]>(mockAssignments);
  const [selectedInstructor, setSelectedInstructor] = useState<Instructor | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterSpecialty, setFilterSpecialty] = useState('all');
  const [filterStatus, setFilterStatus] = useState('all');
  const [showAddInstructor, setShowAddInstructor] = useState(false);
  const [expandedInstructor, setExpandedInstructor] = useState<string | null>(null);

  // Memoized calculations for performance
  const allSpecialties = useMemo(() =>
    Array.from(new Set(instructors.flatMap(i => i.specialties))), [instructors]
  );

  const filteredInstructors = useMemo(() => {
    if (!searchTerm && filterSpecialty === 'all' && filterStatus === 'all') {
      return instructors;
    }

    return searchFilter(instructors, searchTerm, ['name', 'email'])
      .filter(instructor => {
        const matchesSpecialty = filterSpecialty === 'all' || instructor.specialties.includes(filterSpecialty);
        const matchesStatus = filterStatus === 'all' || instructor.status === filterStatus;
        return matchesSpecialty && matchesStatus;
      });
  }, [instructors, searchTerm, filterSpecialty, filterStatus]);

  const getAssignmentStatusColor = (status: string) => {
    switch (status) {
      case 'confirmed': return 'bg-green-100 text-green-700';
      case 'assigned': return 'bg-blue-100 text-blue-700';
      case 'completed': return 'bg-purple-100 text-purple-700';
      case 'cancelled': return 'bg-red-100 text-red-700';
      default: return 'bg-gray-100 text-gray-700';
    }
  };

  // All utility functions are now imported from shared utilities

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
        <div className="p-6 border-b border-gray-200 bg-gradient-to-r from-purple-50 to-blue-50">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-2xl font-bold text-gray-900">Instructor Management</h2>
              <p className="text-gray-600 mt-1">Manage instructor assignments, availability, and performance</p>
            </div>

            <div className="flex items-center gap-3">
              <div className="text-right">
                <div className="text-lg font-bold text-purple-600">{instructors.filter(i => i.status === 'active').length}</div>
                <div className="text-xs text-gray-600">Active Instructors</div>
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
              { key: 'instructors', label: 'Instructors', count: instructors.length },
              { key: 'assignments', label: 'Assignments', count: assignments.length },
              { key: 'availability', label: 'Availability' },
              { key: 'performance', label: 'Performance' }
            ].map(tab => (
              <button
                key={tab.key}
                onClick={() => setActiveTab(tab.key as any)}
                className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                  activeTab === tab.key
                    ? 'bg-white text-purple-600 shadow-sm'
                    : 'text-gray-600 hover:text-gray-900 hover:bg-white/50'
                }`}
              >
                {tab.label}
                {tab.count !== undefined && (
                  <span className="ml-2 px-2 py-0.5 bg-purple-100 text-purple-600 rounded-full text-xs">
                    {tab.count}
                  </span>
                )}
              </button>
            ))}
          </div>
        </div>

        {/* Content Area */}
        <div className="p-6 overflow-y-auto max-h-[65vh]">
          {/* Instructors Tab */}
          {activeTab === 'instructors' && (
            <div className="space-y-4">
              {/* Header Controls */}
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-4">
                  <div className="relative">
                    <Search className="h-4 w-4 absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
                    <input
                      type="text"
                      placeholder="Search instructors..."
                      value={searchTerm}
                      onChange={(e) => setSearchTerm(e.target.value)}
                      className="pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-transparent"
                    />
                  </div>

                  <select
                    value={filterSpecialty}
                    onChange={(e) => setFilterSpecialty(e.target.value)}
                    className="border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-purple-500"
                  >
                    <option value="all">All Specialties</option>
                    {allSpecialties.map(specialty => (
                      <option key={specialty} value={specialty}>{specialty}</option>
                    ))}
                  </select>

                  <select
                    value={filterStatus}
                    onChange={(e) => setFilterStatus(e.target.value)}
                    className="border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-purple-500"
                  >
                    <option value="all">All Status</option>
                    <option value="active">Active</option>
                    <option value="inactive">Inactive</option>
                    <option value="on-leave">On Leave</option>
                  </select>
                </div>

                <button
                  onClick={() => setShowAddInstructor(true)}
                  className="px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 flex items-center gap-2"
                >
                  <Plus className="h-4 w-4" />
                  Add Instructor
                </button>
              </div>

              {/* Instructors List */}
              <div className="space-y-3">
                {filteredInstructors.map((instructor) => (
                  <motion.div
                    key={instructor.id}
                    layout
                    className="border border-gray-200 rounded-lg hover:shadow-md transition-shadow"
                  >
                    <div className="p-4">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-4">
                          <div className="w-12 h-12 bg-purple-100 rounded-full flex items-center justify-center">
                            <User className="h-6 w-6 text-purple-600" />
                          </div>

                          <div>
                            <div className="font-medium text-gray-900">{instructor.name}</div>
                            <div className="text-sm text-gray-600 flex items-center gap-3">
                              <span className="flex items-center gap-1">
                                <Mail className="h-3 w-3" />
                                {instructor.email}
                              </span>
                              {instructor.phone && (
                                <span className="flex items-center gap-1">
                                  <Phone className="h-3 w-3" />
                                  {instructor.phone}
                                </span>
                              )}
                            </div>
                            <div className="flex items-center gap-2 mt-1">
                              {instructor.specialties.slice(0, 3).map(specialty => (
                                <span key={specialty} className="px-2 py-1 bg-blue-100 text-blue-700 rounded-full text-xs">
                                  {specialty}
                                </span>
                              ))}
                              {instructor.specialties.length > 3 && (
                                <span className="text-xs text-gray-500">+{instructor.specialties.length - 3} more</span>
                              )}
                            </div>
                          </div>
                        </div>

                        <div className="flex items-center gap-4">
                          <div className="text-right">
                            <div className="flex items-center gap-1">
                              <Star className="h-4 w-4 text-yellow-500" />
                              <span className="font-medium">{instructor.rating}</span>
                            </div>
                            <div className="text-xs text-gray-600">{instructor.totalClasses} classes</div>
                          </div>

                          <div className="text-right">
                            <div className="font-medium">${instructor.hourlyRate}/hr</div>
                            <div className="text-xs text-gray-600">{instructor.commissionRate}% commission</div>
                          </div>

                          <span className={`px-3 py-1 rounded-full text-sm font-medium border ${getStatusColor(instructor.status)}`}>
                            {instructor.status}
                          </span>

                          <button
                            onClick={() => setExpandedInstructor(
                              expandedInstructor === instructor.id ? null : instructor.id
                            )}
                            className="p-1 text-gray-400 hover:text-gray-600 rounded"
                          >
                            {expandedInstructor === instructor.id ? (
                              <ChevronUp className="h-4 w-4" />
                            ) : (
                              <ChevronDown className="h-4 w-4" />
                            )}
                          </button>
                        </div>
                      </div>

                      {/* Expanded Details */}
                      <AnimatePresence>
                        {expandedInstructor === instructor.id && (
                          <motion.div
                            initial={{ height: 0, opacity: 0 }}
                            animate={{ height: 'auto', opacity: 1 }}
                            exit={{ height: 0, opacity: 0 }}
                            className="mt-4 pt-4 border-t border-gray-200"
                          >
                            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                              <div>
                                <h5 className="font-medium text-gray-900 mb-2">Experience & Stats</h5>
                                <div className="space-y-1 text-sm text-gray-600">
                                  <div className="flex justify-between">
                                    <span>Experience:</span>
                                    <span>{instructor.yearsExperience} years</span>
                                  </div>
                                  <div className="flex justify-between">
                                    <span>Total Revenue:</span>
                                    <span>${instructor.totalRevenue.toLocaleString()}</span>
                                  </div>
                                  <div className="flex justify-between">
                                    <span>Max Classes/Day:</span>
                                    <span>{instructor.maxClassesPerDay}</span>
                                  </div>
                                </div>
                              </div>

                              <div>
                                <h5 className="font-medium text-gray-900 mb-2">Certifications</h5>
                                <div className="space-y-1">
                                  {instructor.certifications.map(cert => (
                                    <div key={cert} className="flex items-center gap-1 text-sm text-gray-600">
                                      <Award className="h-3 w-3 text-yellow-500" />
                                      {cert}
                                    </div>
                                  ))}
                                </div>
                              </div>

                              <div>
                                <h5 className="font-medium text-gray-900 mb-2">Languages</h5>
                                <div className="flex flex-wrap gap-1">
                                  {instructor.languages.map(lang => (
                                    <span key={lang} className="px-2 py-1 bg-gray-100 text-gray-700 rounded text-xs">
                                      {lang}
                                    </span>
                                  ))}
                                </div>
                              </div>
                            </div>

                            <div className="mt-4 flex items-center gap-2">
                              <button className="px-3 py-1 bg-blue-100 text-blue-700 rounded-lg hover:bg-blue-200 text-sm">
                                <Edit3 className="h-3 w-3 mr-1 inline" />
                                Edit
                              </button>
                              <button className="px-3 py-1 bg-green-100 text-green-700 rounded-lg hover:bg-green-200 text-sm">
                                <MessageSquare className="h-3 w-3 mr-1 inline" />
                                Message
                              </button>
                              <button className="px-3 py-1 bg-purple-100 text-purple-700 rounded-lg hover:bg-purple-200 text-sm">
                                <TrendingUp className="h-3 w-3 mr-1 inline" />
                                Performance
                              </button>
                            </div>
                          </motion.div>
                        )}
                      </AnimatePresence>
                    </div>
                  </motion.div>
                ))}
              </div>
            </div>
          )}

          {/* Assignments Tab */}
          {activeTab === 'assignments' && (
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <h3 className="text-lg font-semibold">Class Assignments</h3>
                <button className="px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 flex items-center gap-2">
                  <Plus className="h-4 w-4" />
                  Create Assignment
                </button>
              </div>

              <div className="space-y-3">
                {assignments.map((assignment) => (
                  <div key={assignment.id} className="p-4 border border-gray-200 rounded-lg">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-4">
                        <div className="w-10 h-10 bg-purple-100 rounded-lg flex items-center justify-center">
                          <BookOpen className="h-5 w-5 text-purple-600" />
                        </div>

                        <div>
                          <div className="font-medium text-gray-900">{assignment.className}</div>
                          <div className="text-sm text-gray-600">
                            {instructors.find(i => i.id === assignment.instructorId)?.name}
                          </div>
                          <div className="text-xs text-gray-500 flex items-center gap-3">
                            <span className="flex items-center gap-1">
                              <Calendar className="h-3 w-3" />
                              {formatDate(assignment.date)}
                            </span>
                            <span className="flex items-center gap-1">
                              <Clock className="h-3 w-3" />
                              {formatTime(assignment.startTime)} - {formatTime(assignment.endTime)}
                            </span>
                            <span className="flex items-center gap-1">
                              <MapPin className="h-3 w-3" />
                              {assignment.location}
                            </span>
                          </div>
                        </div>
                      </div>

                      <div className="flex items-center gap-4">
                        <div className="text-right">
                          <div className="font-medium">${assignment.revenue}</div>
                          <div className="text-xs text-gray-600">Instructor: ${assignment.instructorPayout}</div>
                        </div>

                        <div className="text-right">
                          <div className="font-medium">{assignment.students}/{assignment.capacity}</div>
                          <div className="text-xs text-gray-600">Students</div>
                        </div>

                        <span className={`px-2 py-1 rounded-full text-xs ${getAssignmentStatusColor(assignment.status)}`}>
                          {assignment.status}
                        </span>

                        <button className="p-1 text-gray-400 hover:text-gray-600 rounded">
                          <Edit3 className="h-4 w-4" />
                        </button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Availability Tab */}
          {activeTab === 'availability' && (
            <div className="space-y-6">
              <h3 className="text-lg font-semibold">Instructor Availability</h3>

              {instructors.filter(i => i.status === 'active').map((instructor) => (
                <div key={instructor.id} className="p-4 border border-gray-200 rounded-lg">
                  <div className="flex items-center justify-between mb-4">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 bg-purple-100 rounded-full flex items-center justify-center">
                        <User className="h-4 w-4 text-purple-600" />
                      </div>
                      <div>
                        <div className="font-medium">{instructor.name}</div>
                        <div className="text-sm text-gray-600">{instructor.specialties.join(', ')}</div>
                      </div>
                    </div>
                    <button className="px-3 py-1 text-sm bg-purple-100 text-purple-700 rounded-lg hover:bg-purple-200">
                      Edit Schedule
                    </button>
                  </div>

                  <div className="grid grid-cols-7 gap-2">
                    {Object.entries(instructor.availability).map(([day, schedule]) => (
                      <div key={day} className={`p-2 rounded text-center text-xs ${
                        schedule.available
                          ? 'bg-green-100 text-green-700'
                          : 'bg-gray-100 text-gray-500'
                      }`}>
                        <div className="font-medium">{getDayName(day).slice(0, 3)}</div>
                        {schedule.available ? (
                          <div className="mt-1">
                            <div>{formatTime(schedule.startTime!)}</div>
                            <div>{formatTime(schedule.endTime!)}</div>
                          </div>
                        ) : (
                          <div className="mt-1">Unavailable</div>
                        )}
                      </div>
                    ))}
                  </div>
                </div>
              ))}
            </div>
          )}

          {/* Performance Tab */}
          {activeTab === 'performance' && (
            <div className="space-y-6">
              <h3 className="text-lg font-semibold">Instructor Performance</h3>

              <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div className="p-4 bg-green-50 border border-green-200 rounded-lg">
                  <div className="text-2xl font-bold text-green-600">
                    ${instructors.reduce((sum, i) => sum + i.totalRevenue, 0).toLocaleString()}
                  </div>
                  <div className="text-sm text-green-700">Total Revenue</div>
                </div>

                <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
                  <div className="text-2xl font-bold text-blue-600">
                    {(instructors.reduce((sum, i) => sum + i.rating, 0) / instructors.length).toFixed(1)}
                  </div>
                  <div className="text-sm text-blue-700">Average Rating</div>
                </div>

                <div className="p-4 bg-purple-50 border border-purple-200 rounded-lg">
                  <div className="text-2xl font-bold text-purple-600">
                    {instructors.reduce((sum, i) => sum + i.totalClasses, 0)}
                  </div>
                  <div className="text-sm text-purple-700">Total Classes</div>
                </div>
              </div>

              <div className="space-y-3">
                <h4 className="font-medium">Individual Performance</h4>
                {instructors.map((instructor) => (
                  <div key={instructor.id} className="p-4 border border-gray-200 rounded-lg">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-3">
                        <div className="w-8 h-8 bg-purple-100 rounded-full flex items-center justify-center">
                          <User className="h-4 w-4 text-purple-600" />
                        </div>
                        <div>
                          <div className="font-medium">{instructor.name}</div>
                          <div className="text-sm text-gray-600">{instructor.specialties[0]}</div>
                        </div>
                      </div>

                      <div className="flex items-center gap-6">
                        <div className="text-center">
                          <div className="font-medium">{instructor.rating}</div>
                          <div className="text-xs text-gray-600">Rating</div>
                        </div>
                        <div className="text-center">
                          <div className="font-medium">{instructor.totalClasses}</div>
                          <div className="text-xs text-gray-600">Classes</div>
                        </div>
                        <div className="text-center">
                          <div className="font-medium">${instructor.totalRevenue.toLocaleString()}</div>
                          <div className="text-xs text-gray-600">Revenue</div>
                        </div>
                        <div className="text-center">
                          <div className="font-medium">${instructor.hourlyRate}</div>
                          <div className="text-xs text-gray-600">Hourly Rate</div>
                        </div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="p-6 border-t border-gray-200 bg-gray-50">
          <div className="flex items-center justify-between">
            <div className="text-sm text-gray-600">
              Showing {filteredInstructors.length} of {instructors.length} instructors
            </div>

            <div className="flex items-center gap-3">
              <button className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50">
                <Download className="h-4 w-4 mr-2 inline" />
                Export Data
              </button>
              <button
                onClick={() => onSave && onSave(assignments)}
                className="px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700"
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