'use client';

import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Plus,
  Search,
  Filter,
  Edit3,
  Trash2,
  Copy,
  Calendar,
  Clock,
  Users,
  DollarSign,
  Star,
  Eye,
  MoreVertical,
  Image as ImageIcon,
  Tag,
  MapPin,
  User,
  AlertCircle,
  CheckCircle,
  X,
  BookOpen,
  CreditCard
} from 'lucide-react';
import ClassEditor from './ClassEditor';
import ClassSchedule from './ClassSchedule';
import InstructorAssignment from './InstructorAssignment';
import RecurringTemplates from './RecurringTemplates';
import BackButton from '@/components/common/BackButton';
import type { Class } from '../../../types/class-management';

// Mock data - in production this would come from API

const mockClasses: Class[] = [
  {
    id: '1',
    name: 'Pottery Wheel Basics',
    description: 'Learn wheel throwing techniques and create your first ceramic pieces',
    instructor: 'Sarah Johnson',
    instructorId: 'inst_1',
    category: 'Pottery',
    level: 'beginner',
    duration: 120,
    capacity: 8,
    price: 65,
    creditCost: 3,
    image: '/images/pottery.jpg',
    tags: ['hands-on', 'creative', 'beginner-friendly'],
    location: 'Ceramics Studio',
    status: 'active',
    rating: 4.8,
    totalBookings: 124,
    nextSession: {
      date: '2025-08-09',
      time: '09:00',
      enrolled: 7
    },
    createdAt: '2025-07-01T10:00:00Z',
    updatedAt: '2025-08-08T14:30:00Z'
  },
  {
    id: '2',
    name: 'Watercolor Landscapes',
    description: 'Master watercolor techniques while painting beautiful landscapes',
    instructor: 'Mike Chen',
    instructorId: 'inst_2',
    category: 'Painting',
    level: 'intermediate',
    duration: 90,
    capacity: 12,
    price: 45,
    creditCost: 2,
    image: '/images/watercolor.jpg',
    tags: ['artistic', 'relaxing', 'landscapes'],
    location: 'Art Studio',
    status: 'active',
    rating: 4.9,
    totalBookings: 89,
    nextSession: {
      date: '2025-08-09',
      time: '10:30',
      enrolled: 8
    },
    createdAt: '2025-06-15T08:00:00Z',
    updatedAt: '2025-08-07T16:45:00Z'
  },
  {
    id: '3',
    name: 'Flower Bouquet Workshop',
    description: 'Create stunning floral arrangements and learn bouquet design principles',
    instructor: 'Emily Davis',
    instructorId: 'inst_3',
    category: 'Flower Arranging',
    level: 'beginner',
    duration: 90,
    capacity: 10,
    price: 55,
    creditCost: 2,
    image: '/images/flowers.jpg',
    tags: ['creative', 'relaxing', 'seasonal'],
    location: 'Garden Room',
    status: 'active',
    rating: 4.9,
    totalBookings: 156,
    nextSession: {
      date: '2025-08-09',
      time: '14:00',
      enrolled: 9
    },
    createdAt: '2025-05-20T12:00:00Z',
    updatedAt: '2025-08-08T09:15:00Z'
  },
  {
    id: '4',
    name: 'DJ Mixing Fundamentals',
    description: 'Learn beat matching, mixing techniques, and DJ equipment basics',
    instructor: 'Alex Rivera',
    instructorId: 'inst_4',
    category: 'DJ Workshops',
    level: 'beginner',
    duration: 120,
    capacity: 6,
    price: 75,
    creditCost: 3,
    image: '/images/dj.jpg',
    tags: ['music', 'electronic', 'hands-on'],
    location: 'Music Lab',
    status: 'active',
    rating: 4.8,
    totalBookings: 67,
    nextSession: {
      date: '2025-08-10',
      time: '18:00',
      enrolled: 5
    },
    createdAt: '2025-06-15T10:00:00Z',
    updatedAt: '2025-08-08T11:30:00Z'
  },
  {
    id: '5',
    name: 'Introduction to Fencing',
    description: 'Learn the basics of foil fencing - footwork, attacks, and defense',
    instructor: 'Marcus Thompson',
    instructorId: 'inst_5',
    category: 'Fencing',
    level: 'beginner',
    duration: 90,
    capacity: 8,
    price: 60,
    creditCost: 2,
    image: '/images/fencing.jpg',
    tags: ['sport', 'strategic', 'unique'],
    location: 'Sports Hall',
    status: 'active',
    rating: 4.7,
    totalBookings: 45,
    nextSession: {
      date: '2025-08-11',
      time: '10:00',
      enrolled: 6
    },
    createdAt: '2025-07-01T08:00:00Z',
    updatedAt: '2025-08-07T14:20:00Z'
  },
  {
    id: '6',
    name: 'Jewelry Making: Wire Wrapping',
    description: 'Create beautiful pendants and rings using wire wrapping techniques',
    instructor: 'Lisa Chang',
    instructorId: 'inst_6',
    category: 'Jewelry Making',
    level: 'beginner',
    duration: 150,
    capacity: 8,
    price: 70,
    creditCost: 3,
    image: '/images/jewelry.jpg',
    tags: ['crafts', 'detailed', 'take-home'],
    location: 'Craft Workshop',
    status: 'active',
    rating: 4.9,
    totalBookings: 92,
    nextSession: {
      date: '2025-08-09',
      time: '13:00',
      enrolled: 8
    },
    createdAt: '2025-06-10T09:00:00Z',
    updatedAt: '2025-08-08T10:00:00Z'
  }
];

export default function ClassManagement() {
  const [classes, setClasses] = useState<Class[]>(mockClasses);
  const [filteredClasses, setFilteredClasses] = useState<Class[]>(mockClasses);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [selectedStatus, setSelectedStatus] = useState('all');
  const [sortBy, setSortBy] = useState('name');
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');
  const [selectedClass, setSelectedClass] = useState<Class | null>(null);
  const [isEditorOpen, setIsEditorOpen] = useState(false);
  const [isScheduleOpen, setIsScheduleOpen] = useState(false);
  const [isInstructorAssignmentOpen, setIsInstructorAssignmentOpen] = useState(false);
  const [isRecurringTemplatesOpen, setIsRecurringTemplatesOpen] = useState(false);
  const [deleteConfirm, setDeleteConfirm] = useState<string | null>(null);

  const categories = ['all', 'Yoga', 'Pilates', 'Dance', 'Fitness', 'Meditation'];
  const statuses = ['all', 'active', 'inactive', 'draft'];

  // Filter and sort classes
  useEffect(() => {
    let filtered = classes.filter(cls => {
      const matchesSearch = cls.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                           cls.instructor.toLowerCase().includes(searchTerm.toLowerCase()) ||
                           cls.category.toLowerCase().includes(searchTerm.toLowerCase());
      const matchesCategory = selectedCategory === 'all' || cls.category === selectedCategory;
      const matchesStatus = selectedStatus === 'all' || cls.status === selectedStatus;
      
      return matchesSearch && matchesCategory && matchesStatus;
    });

    // Sort classes
    filtered.sort((a, b) => {
      switch (sortBy) {
        case 'name':
          return a.name.localeCompare(b.name);
        case 'instructor':
          return a.instructor.localeCompare(b.instructor);
        case 'price':
          return b.price - a.price;
        case 'rating':
          return b.rating - a.rating;
        case 'bookings':
          return b.totalBookings - a.totalBookings;
        case 'updated':
          return new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime();
        default:
          return 0;
      }
    });

    setFilteredClasses(filtered);
  }, [classes, searchTerm, selectedCategory, selectedStatus, sortBy]);

  const handleCreateClass = () => {
    setSelectedClass(null);
    setIsEditorOpen(true);
  };

  const handleEditClass = (cls: Class) => {
    setSelectedClass(cls);
    setIsEditorOpen(true);
  };

  const handleDuplicateClass = (cls: Class) => {
    const newClass: Class = {
      ...cls,
      id: Date.now().toString(),
      name: `${cls.name} (Copy)`,
      status: 'draft',
      totalBookings: 0,
      nextSession: undefined,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
    setClasses(prev => [newClass, ...prev]);
  };

  const handleDeleteClass = (classId: string) => {
    setClasses(prev => prev.filter(cls => cls.id !== classId));
    setDeleteConfirm(null);
  };

  const handleSaveClass = (classData: Partial<Class>) => {
    if (selectedClass) {
      // Update existing class
      setClasses(prev => prev.map(cls => 
        cls.id === selectedClass.id 
          ? { ...cls, ...classData, updatedAt: new Date().toISOString() }
          : cls
      ));
    } else {
      // Create new class
      const newClass: Class = {
        id: Date.now().toString(),
        name: classData.name || '',
        description: classData.description || '',
        instructor: classData.instructor || '',
        instructorId: classData.instructorId || '',
        category: classData.category || 'Yoga',
        level: classData.level || 'beginner',
        duration: classData.duration || 60,
        capacity: classData.capacity || 15,
        price: classData.price || 25,
        image: classData.image || '',
        tags: classData.tags || [],
        location: classData.location || '',
        status: classData.status || 'draft',
        rating: 0,
        totalBookings: 0,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      };
      setClasses(prev => [newClass, ...prev]);
    }
    setIsEditorOpen(false);
  };

  const getLevelColor = (level: string) => {
    switch (level) {
      case 'beginner': return 'bg-green-100 text-green-700';
      case 'intermediate': return 'bg-yellow-100 text-yellow-700';
      case 'advanced': return 'bg-red-100 text-red-700';
      default: return 'bg-gray-100 text-gray-700';
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active': return 'bg-green-100 text-green-700';
      case 'inactive': return 'bg-gray-100 text-gray-700';
      case 'draft': return 'bg-yellow-100 text-yellow-700';
      default: return 'bg-gray-100 text-gray-700';
    }
  };

  return (
    <div className="space-y-6">
      <BackButton href="/dashboard" className="mb-4" />
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Class Management</h1>
          <p className="text-gray-600 mt-1">Manage your studio classes and schedules</p>
        </div>
        
        <div className="flex items-center gap-3">
          <button
            onClick={() => setIsScheduleOpen(true)}
            className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors flex items-center"
          >
            <Calendar className="h-4 w-4 mr-2" />
            Schedule View
          </button>

          <button
            onClick={() => setIsInstructorAssignmentOpen(true)}
            className="px-4 py-2 border border-purple-300 text-purple-700 rounded-lg hover:bg-purple-50 transition-colors flex items-center"
          >
            <User className="h-4 w-4 mr-2" />
            Instructors
          </button>

          <button
            onClick={() => setIsRecurringTemplatesOpen(true)}
            className="px-4 py-2 border border-green-300 text-green-700 rounded-lg hover:bg-green-50 transition-colors flex items-center"
          >
            <Copy className="h-4 w-4 mr-2" />
            Templates
          </button>

          <button
            onClick={handleCreateClass}
            className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors flex items-center"
          >
            <Plus className="h-4 w-4 mr-2" />
            New Class
          </button>
        </div>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-lg border p-4">
        <div className="flex flex-col lg:flex-row gap-4 items-center">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
            <input
              type="text"
              placeholder="Search classes, instructors, or categories..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
          </div>
          
          <div className="flex items-center gap-3">
            <select
              value={selectedCategory}
              onChange={(e) => setSelectedCategory(e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              {categories.map(category => (
                <option key={category} value={category}>
                  {category === 'all' ? 'All Categories' : category}
                </option>
              ))}
            </select>
            
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
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              <option value="name">Sort by Name</option>
              <option value="instructor">Sort by Instructor</option>
              <option value="price">Sort by Price</option>
              <option value="rating">Sort by Rating</option>
              <option value="bookings">Sort by Bookings</option>
              <option value="updated">Sort by Updated</option>
            </select>
          </div>
        </div>
      </div>

      {/* Classes Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {filteredClasses.map((cls) => (
          <motion.div
            key={cls.id}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="bg-white rounded-xl shadow-sm border hover:shadow-md transition-shadow overflow-hidden group"
          >
            {/* Class Image */}
            <div className="relative h-48 bg-gradient-to-br from-blue-500 to-purple-600">
              <div className="absolute inset-0 flex items-center justify-center">
                <ImageIcon className="h-12 w-12 text-white opacity-50" />
              </div>
              
              <div className="absolute top-3 right-3 flex items-center gap-2">
                <span className={`px-2 py-1 text-sm font-medium rounded-full ${getStatusColor(cls.status)}`}>
                  {cls.status}
                </span>
              </div>
              
              <div className="absolute top-3 left-3">
                <span className={`px-2 py-1 text-sm font-medium rounded-full ${getLevelColor(cls.level)}`}>
                  {cls.level}
                </span>
              </div>
            </div>

            {/* Class Content */}
            <div className="p-4">
              <div className="flex items-start justify-between mb-2">
                <h3 className="font-semibold text-gray-900 text-lg">{cls.name}</h3>
                <div className="relative">
                  <button className="p-1 hover:bg-gray-100 rounded-full opacity-0 group-hover:opacity-100 transition-opacity">
                    <MoreVertical className="h-4 w-4 text-gray-500" />
                  </button>
                </div>
              </div>
              
              <p className="text-gray-600 text-sm mb-3 line-clamp-2">{cls.description}</p>
              
              <div className="space-y-2 mb-4">
                <div className="flex items-center text-sm text-gray-600">
                  <User className="h-4 w-4 mr-2" />
                  {cls.instructor}
                </div>
                
                <div className="flex items-center text-sm text-gray-600">
                  <Clock className="h-4 w-4 mr-2" />
                  {cls.duration} minutes
                </div>
                
                <div className="flex items-center text-sm text-gray-600">
                  <Users className="h-4 w-4 mr-2" />
                  {cls.capacity} max capacity
                </div>
                
                <div className="flex items-center text-sm text-gray-600">
                  <DollarSign className="h-4 w-4 mr-2" />
                  ${cls.price} per class
                </div>
                
                <div className="flex items-center text-sm font-medium text-blue-600">
                  <CreditCard className="h-4 w-4 mr-2" />
                  {cls.creditCost} credits required
                </div>
                
                <div className="flex items-center text-sm text-gray-600">
                  <Star className="h-4 w-4 mr-2" />
                  {cls.rating} ({cls.totalBookings} bookings)
                </div>
              </div>

              {/* Next Session */}
              {cls.nextSession && (
                <div className="bg-blue-50 rounded-lg p-3 mb-4">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-sm font-medium text-blue-900">Next Session</p>
                      <p className="text-sm text-blue-700">
                        {new Date(cls.nextSession.date).toLocaleDateString()} at {cls.nextSession.time}
                      </p>
                    </div>
                    <div className="text-right">
                      <p className="text-sm font-medium text-blue-900">
                        {cls.nextSession.enrolled}/{cls.capacity}
                      </p>
                      <p className="text-xs text-blue-700">enrolled</p>
                    </div>
                  </div>
                </div>
              )}

              {/* Actions */}
              <div className="flex items-center gap-2">
                <button
                  onClick={() => handleEditClass(cls)}
                  className="flex-1 px-3 py-2 text-sm bg-blue-50 text-blue-700 rounded-lg hover:bg-blue-100 transition-colors flex items-center justify-center"
                >
                  <Edit3 className="h-4 w-4 mr-1" />
                  Edit
                </button>
                
                <button
                  onClick={() => handleDuplicateClass(cls)}
                  className="px-3 py-2 text-sm border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
                >
                  <Copy className="h-4 w-4" />
                </button>
                
                <button
                  onClick={() => setDeleteConfirm(cls.id)}
                  className="px-3 py-2 text-sm border border-red-300 text-red-700 rounded-lg hover:bg-red-50 transition-colors"
                >
                  <Trash2 className="h-4 w-4" />
                </button>
              </div>
            </div>
          </motion.div>
        ))}
      </div>

      {/* Empty State */}
      {filteredClasses.length === 0 && (
        <div className="text-center py-12">
          <BookOpen className="h-16 w-16 text-gray-300 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">No classes found</h3>
          <p className="text-gray-600 mb-4">
            {searchTerm ? 'Try adjusting your search filters' : 'Get started by creating your first class'}
          </p>
          <button
            onClick={handleCreateClass}
            className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            Create Class
          </button>
        </div>
      )}

      {/* Class Editor Modal */}
      <AnimatePresence>
        {isEditorOpen && (
          <ClassEditor
            class={selectedClass}
            onSave={handleSaveClass}
            onClose={() => setIsEditorOpen(false)}
          />
        )}
      </AnimatePresence>

      {/* Schedule Modal */}
      <AnimatePresence>
        {isScheduleOpen && (
          <ClassSchedule
            classes={classes}
            onClose={() => setIsScheduleOpen(false)}
          />
        )}

        {isInstructorAssignmentOpen && (
          <InstructorAssignment
            onClose={() => setIsInstructorAssignmentOpen(false)}
          />
        )}

        {isRecurringTemplatesOpen && (
          <RecurringTemplates
            onClose={() => setIsRecurringTemplatesOpen(false)}
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
                <h3 className="text-xl font-semibold text-gray-900">Delete Class</h3>
              </div>
              
              <p className="text-gray-600 mb-6">
                Are you sure you want to delete this class? This action cannot be undone.
              </p>
              
              <div className="flex items-center gap-3">
                <button
                  onClick={() => setDeleteConfirm(null)}
                  className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={() => handleDeleteClass(deleteConfirm)}
                  className="flex-1 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
                >
                  Delete
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}