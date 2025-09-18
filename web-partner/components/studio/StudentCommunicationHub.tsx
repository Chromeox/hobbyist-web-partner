'use client';

import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Users,
  Mail,
  MessageSquare,
  Send,
  Search,
  Filter,
  Star,
  Calendar,
  Award,
  TrendingUp,
  Heart,
  Gift,
  Bell,
  Phone,
  MapPin,
  Clock,
  Camera,
  Plus,
  Edit,
  Eye,
  MoreHorizontal,
  Palette,
  Hammer,
  ChefHat,
  Music
} from 'lucide-react';

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { formatCurrency } from '@/lib/utils';

interface Student {
  id: string;
  name: string;
  email: string;
  phone?: string;
  join_date: string;
  total_workshops: number;
  favorite_categories: string[];
  skill_levels: Record<string, 'beginner' | 'intermediate' | 'advanced'>;
  total_spent: number;
  last_workshop_date?: string;
  next_workshop_date?: string;
  status: 'active' | 'inactive' | 'trial' | 'vip';
  notes?: string;
  birthday?: string;
  emergency_contact?: string;
  dietary_restrictions?: string[];
  preferences: {
    communication: 'email' | 'sms' | 'both';
    marketing: boolean;
    reminders: boolean;
  };
  portfolio: StudentProject[];
}

interface StudentProject {
  id: string;
  workshop_id: string;
  workshop_name: string;
  workshop_category: string;
  completion_date: string;
  skill_level: string;
  photos: string[];
  instructor_notes?: string;
  student_reflection?: string;
  rating?: number;
}

interface CommunicationTemplate {
  id: string;
  name: string;
  type: 'welcome' | 'reminder' | 'follow_up' | 'birthday' | 'milestone' | 'promotional';
  category?: string;
  subject: string;
  content: string;
  variables: string[]; // Dynamic variables like {name}, {workshop_name}
  active: boolean;
}

interface Message {
  id: string;
  student_id: string;
  type: 'email' | 'sms' | 'in_app';
  template_id?: string;
  subject?: string;
  content: string;
  sent_at: string;
  status: 'sent' | 'delivered' | 'read' | 'failed';
  scheduled_for?: string;
}

interface StudentSegment {
  id: string;
  name: string;
  description: string;
  criteria: {
    categories?: string[];
    skill_levels?: string[];
    workshop_count?: { min?: number; max?: number };
    spend_amount?: { min?: number; max?: number };
    last_activity?: { days?: number };
    status?: string[];
  };
  student_count: number;
}

interface StudentCommunicationHubProps {
  studioId: string;
}

const CATEGORY_ICONS = {
  pottery: Palette,
  painting: Palette,
  woodworking: Hammer,
  jewelry: Palette,
  cooking: ChefHat,
  music: Music,
};

const CATEGORY_COLORS = {
  pottery: 'bg-amber-100 text-amber-800',
  painting: 'bg-blue-100 text-blue-800',
  woodworking: 'bg-orange-100 text-orange-800',
  jewelry: 'bg-purple-100 text-purple-800',
  cooking: 'bg-green-100 text-green-800',
  music: 'bg-pink-100 text-pink-800',
};

export function StudentCommunicationHub({ studioId }: StudentCommunicationHubProps) {
  const [students, setStudents] = useState<Student[]>([]);
  const [templates, setTemplates] = useState<CommunicationTemplate[]>([]);
  const [messages, setMessages] = useState<Message[]>([]);
  const [segments, setSegments] = useState<StudentSegment[]>([]);
  const [loading, setLoading] = useState(true);
  const [viewMode, setViewMode] = useState<'students' | 'communication' | 'analytics'>('students');
  const [selectedStudent, setSelectedStudent] = useState<Student | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [filterStatus, setFilterStatus] = useState<string>('all');
  const [filterCategory, setFilterCategory] = useState<string>('all');
  const [showMessageModal, setShowMessageModal] = useState(false);
  const [selectedSegment, setSelectedSegment] = useState<StudentSegment | null>(null);

  useEffect(() => {
    fetchStudentData();
  }, [studioId]);

  const fetchStudentData = async () => {
    setLoading(true);
    try {
      // Mock data - replace with actual API calls
      const mockStudents: Student[] = [
        {
          id: '1',
          name: 'Emma Chen',
          email: 'emma.chen@email.com',
          phone: '(604) 555-0123',
          join_date: '2025-06-15',
          total_workshops: 12,
          favorite_categories: ['pottery', 'painting'],
          skill_levels: { pottery: 'intermediate', painting: 'beginner' },
          total_spent: 1240,
          last_workshop_date: '2025-09-10',
          next_workshop_date: '2025-09-25',
          status: 'active',
          preferences: {
            communication: 'email',
            marketing: true,
            reminders: true,
          },
          portfolio: [
            {
              id: '1',
              workshop_id: 'w1',
              workshop_name: 'Beginner Pottery Wheel',
              workshop_category: 'pottery',
              completion_date: '2025-09-10',
              skill_level: 'beginner',
              photos: ['photo1.jpg', 'photo2.jpg'],
              instructor_notes: 'Great progress with centering. Natural talent!',
              rating: 5,
            },
          ],
        },
        {
          id: '2',
          name: 'Michael Rodriguez',
          email: 'michael.r@email.com',
          join_date: '2025-08-20',
          total_workshops: 3,
          favorite_categories: ['woodworking'],
          skill_levels: { woodworking: 'beginner' },
          total_spent: 285,
          last_workshop_date: '2025-09-05',
          status: 'trial',
          preferences: {
            communication: 'both',
            marketing: false,
            reminders: true,
          },
          portfolio: [],
        },
        {
          id: '3',
          name: 'Sarah Kim',
          email: 'sarah.kim@email.com',
          phone: '(604) 555-0789',
          join_date: '2024-12-10',
          total_workshops: 28,
          favorite_categories: ['pottery', 'painting', 'jewelry'],
          skill_levels: { pottery: 'advanced', painting: 'intermediate', jewelry: 'beginner' },
          total_spent: 3580,
          last_workshop_date: '2025-09-12',
          next_workshop_date: '2025-09-20',
          status: 'vip',
          birthday: '1985-10-15',
          preferences: {
            communication: 'email',
            marketing: true,
            reminders: true,
          },
          portfolio: [],
        },
      ];

      const mockTemplates: CommunicationTemplate[] = [
        {
          id: '1',
          name: 'Welcome New Student',
          type: 'welcome',
          subject: 'Welcome to {studio_name}! 🎨',
          content: 'Hi {name}! Welcome to our creative community. We\'re excited to see what you\'ll create in your upcoming {workshop_name} workshop.',
          variables: ['name', 'studio_name', 'workshop_name'],
          active: true,
        },
        {
          id: '2',
          name: 'Workshop Reminder',
          type: 'reminder',
          subject: 'Reminder: {workshop_name} tomorrow',
          content: 'Hi {name}! Just a friendly reminder that your {workshop_name} workshop is tomorrow at {time}. Don\'t forget to bring an apron!',
          variables: ['name', 'workshop_name', 'time'],
          active: true,
        },
        {
          id: '3',
          name: 'Birthday Special',
          type: 'birthday',
          subject: 'Happy Birthday, {name}! 🎂',
          content: 'Happy Birthday {name}! To celebrate, we\'re giving you 20% off your next workshop. Use code BIRTHDAY20.',
          variables: ['name'],
          active: true,
        },
      ];

      const mockSegments: StudentSegment[] = [
        {
          id: '1',
          name: 'VIP Students',
          description: 'Students who have spent over $2000 and taken 20+ workshops',
          criteria: {
            workshop_count: { min: 20 },
            spend_amount: { min: 2000 },
            status: ['vip'],
          },
          student_count: 1,
        },
        {
          id: '2',
          name: 'New Trial Students',
          description: 'Students in their first month with 1-3 workshops',
          criteria: {
            workshop_count: { max: 3 },
            status: ['trial'],
          },
          student_count: 1,
        },
        {
          id: '3',
          name: 'Pottery Enthusiasts',
          description: 'Students who primarily take pottery workshops',
          criteria: {
            categories: ['pottery'],
            workshop_count: { min: 5 },
          },
          student_count: 2,
        },
      ];

      setStudents(mockStudents);
      setTemplates(mockTemplates);
      setSegments(mockSegments);
    } catch (error) {
      console.error('Failed to fetch student data:', error);
    } finally {
      setLoading(false);
    }
  };

  const getFilteredStudents = () => {
    let filtered = students;

    if (filterStatus !== 'all') {
      filtered = filtered.filter(student => student.status === filterStatus);
    }

    if (filterCategory !== 'all') {
      filtered = filtered.filter(student =>
        student.favorite_categories.includes(filterCategory)
      );
    }

    if (searchQuery) {
      filtered = filtered.filter(student =>
        student.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        student.email.toLowerCase().includes(searchQuery.toLowerCase())
      );
    }

    return filtered;
  };

  const getStudentMetrics = () => {
    const activeStudents = students.filter(s => s.status === 'active').length;
    const totalRevenue = students.reduce((sum, s) => sum + s.total_spent, 0);
    const averageWorkshops = students.reduce((sum, s) => sum + s.total_workshops, 0) / students.length;
    const retentionRate = students.filter(s => s.last_workshop_date &&
      new Date(s.last_workshop_date) > new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
    ).length / students.length * 100;

    return { activeStudents, totalRevenue, averageWorkshops, retentionRate };
  };

  const handleSendMessage = (student: Student, template: CommunicationTemplate) => {
    // Logic to send personalized message
    console.log('Sending message to:', student.name, 'using template:', template.name);
  };

  const renderStudentsView = () => {
    const metrics = getStudentMetrics();

    return (
      <div className="space-y-6">
        {/* Student Metrics */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <Card>
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">Active Students</p>
                  <p className="text-2xl font-bold">{metrics.activeStudents}</p>
                </div>
                <Users className="h-8 w-8 text-blue-500" />
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">Total Revenue</p>
                  <p className="text-2xl font-bold">{formatCurrency(metrics.totalRevenue)}</p>
                </div>
                <TrendingUp className="h-8 w-8 text-green-500" />
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">Avg. Workshops</p>
                  <p className="text-2xl font-bold">{Math.round(metrics.averageWorkshops)}</p>
                </div>
                <Calendar className="h-8 w-8 text-purple-500" />
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">Retention Rate</p>
                  <p className="text-2xl font-bold">{Math.round(metrics.retentionRate)}%</p>
                </div>
                <Heart className="h-8 w-8 text-red-500" />
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Filters and Search */}
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="flex-1">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-4 w-4" />
              <input
                type="text"
                placeholder="Search students..."
                className="pl-10 pr-4 py-2 w-full border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />
            </div>
          </div>
          <div className="flex gap-2">
            <select
              className="px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500"
              value={filterStatus}
              onChange={(e) => setFilterStatus(e.target.value)}
            >
              <option value="all">All Status</option>
              <option value="active">Active</option>
              <option value="trial">Trial</option>
              <option value="vip">VIP</option>
              <option value="inactive">Inactive</option>
            </select>
            <select
              className="px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500"
              value={filterCategory}
              onChange={(e) => setFilterCategory(e.target.value)}
            >
              <option value="all">All Categories</option>
              <option value="pottery">Pottery</option>
              <option value="painting">Painting</option>
              <option value="woodworking">Woodworking</option>
              <option value="jewelry">Jewelry</option>
              <option value="cooking">Cooking</option>
              <option value="music">Music</option>
            </select>
          </div>
        </div>

        {/* Students Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {getFilteredStudents().map((student, index) => (
            <motion.div
              key={student.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.1 }}
            >
              <Card className="hover:shadow-md transition-shadow cursor-pointer" onClick={() => setSelectedStudent(student)}>
                <CardContent className="p-4">
                  <div className="flex items-start justify-between">
                    <div className="flex items-center space-x-3">
                      <div className="w-10 h-10 bg-gradient-to-r from-blue-500 to-purple-500 rounded-full flex items-center justify-center text-white font-medium">
                        {student.name.split(' ').map(n => n[0]).join('')}
                      </div>
                      <div>
                        <h3 className="font-medium text-gray-900">{student.name}</h3>
                        <p className="text-sm text-gray-600">{student.email}</p>
                      </div>
                    </div>
                    <Badge
                      variant={
                        student.status === 'vip' ? 'default' :
                        student.status === 'active' ? 'secondary' :
                        student.status === 'trial' ? 'intermediate' : 'outline'
                      }
                      className="text-xs"
                    >
                      {student.status.toUpperCase()}
                    </Badge>
                  </div>

                  <div className="mt-4 space-y-2">
                    <div className="flex justify-between items-center">
                      <span className="text-sm text-gray-600">Workshops:</span>
                      <span className="font-medium">{student.total_workshops}</span>
                    </div>

                    <div className="flex justify-between items-center">
                      <span className="text-sm text-gray-600">Total Spent:</span>
                      <span className="font-medium">{formatCurrency(student.total_spent)}</span>
                    </div>

                    <div className="flex justify-between items-center">
                      <span className="text-sm text-gray-600">Last Visit:</span>
                      <span className="text-sm">
                        {student.last_workshop_date
                          ? new Date(student.last_workshop_date).toLocaleDateString()
                          : 'Never'
                        }
                      </span>
                    </div>

                    {/* Favorite Categories */}
                    <div className="pt-2">
                      <div className="flex flex-wrap gap-1">
                        {student.favorite_categories.slice(0, 3).map(category => {
                          const Icon = CATEGORY_ICONS[category as keyof typeof CATEGORY_ICONS];
                          return (
                            <div key={category} className={`inline-flex items-center px-2 py-1 rounded-full text-xs ${
                              CATEGORY_COLORS[category as keyof typeof CATEGORY_COLORS]
                            }`}>
                              {Icon && <Icon className="h-3 w-3 mr-1" />}
                              {category}
                            </div>
                          );
                        })}
                        {student.favorite_categories.length > 3 && (
                          <span className="text-xs text-gray-500">+{student.favorite_categories.length - 3}</span>
                        )}
                      </div>
                    </div>

                    {/* Quick Actions */}
                    <div className="flex gap-2 pt-2">
                      <Button
                        size="sm"
                        variant="outline"
                        className="flex-1"
                        onClick={(e) => {
                          e.stopPropagation();
                          setShowMessageModal(true);
                        }}
                      >
                        <Mail className="h-3 w-3 mr-1" />
                        Message
                      </Button>
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={(e) => {
                          e.stopPropagation();
                          setSelectedStudent(student);
                        }}
                      >
                        <Eye className="h-3 w-3" />
                      </Button>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </motion.div>
          ))}
        </div>
      </div>
    );
  };

  const renderCommunicationView = () => (
    <div className="space-y-6">
      {/* Communication Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Messages Sent</p>
                <p className="text-2xl font-bold">245</p>
              </div>
              <Send className="h-8 w-8 text-blue-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Open Rate</p>
                <p className="text-2xl font-bold">68%</p>
              </div>
              <Mail className="h-8 w-8 text-green-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Templates</p>
                <p className="text-2xl font-bold">{templates.length}</p>
              </div>
              <MessageSquare className="h-8 w-8 text-purple-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Segments</p>
                <p className="text-2xl font-bold">{segments.length}</p>
              </div>
              <Users className="h-8 w-8 text-orange-500" />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Templates and Segments */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Message Templates */}
        <Card>
          <CardHeader>
            <CardTitle>Message Templates</CardTitle>
            <CardDescription>Pre-built templates for common communications</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {templates.map(template => (
                <div key={template.id} className="flex items-center justify-between p-3 border rounded-lg">
                  <div>
                    <p className="font-medium">{template.name}</p>
                    <p className="text-sm text-gray-600">{template.subject}</p>
                    <Badge variant={template.type as any} className="text-xs mt-1">
                      {template.type}
                    </Badge>
                  </div>
                  <div className="flex gap-2">
                    <Button size="sm" variant="outline">
                      <Edit className="h-3 w-3" />
                    </Button>
                    <Button size="sm" variant="outline">
                      <Send className="h-3 w-3" />
                    </Button>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* Student Segments */}
        <Card>
          <CardHeader>
            <CardTitle>Student Segments</CardTitle>
            <CardDescription>Targeted groups for personalized messaging</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {segments.map(segment => (
                <div key={segment.id} className="p-3 border rounded-lg">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="font-medium">{segment.name}</p>
                      <p className="text-sm text-gray-600">{segment.description}</p>
                    </div>
                    <Badge variant="secondary" className="text-xs">
                      {segment.student_count} students
                    </Badge>
                  </div>
                  <div className="flex gap-2 mt-3">
                    <Button size="sm" variant="outline" className="flex-1">
                      <Mail className="h-3 w-3 mr-1" />
                      Send Campaign
                    </Button>
                    <Button size="sm" variant="outline">
                      <Eye className="h-3 w-3" />
                    </Button>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {[...Array(6)].map((_, i) => (
            <Card key={i} className="animate-pulse">
              <CardContent className="p-6">
                <div className="h-24 bg-gray-200 rounded"></div>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    );
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="space-y-6"
    >
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Student Management</h1>
          <p className="text-gray-600">Build stronger relationships with your creative community</p>
        </div>
        <div className="flex items-center gap-2">
          <Button
            variant={viewMode === 'students' ? 'default' : 'outline'}
            size="sm"
            onClick={() => setViewMode('students')}
          >
            <Users className="h-4 w-4 mr-2" />
            Students
          </Button>
          <Button
            variant={viewMode === 'communication' ? 'default' : 'outline'}
            size="sm"
            onClick={() => setViewMode('communication')}
          >
            <MessageSquare className="h-4 w-4 mr-2" />
            Communication
          </Button>
          <Button
            variant={viewMode === 'analytics' ? 'default' : 'outline'}
            size="sm"
            onClick={() => setViewMode('analytics')}
          >
            <TrendingUp className="h-4 w-4 mr-2" />
            Analytics
          </Button>
          <Button variant="creative">
            <Plus className="h-4 w-4 mr-2" />
            Add Student
          </Button>
        </div>
      </div>

      {/* Main Content */}
      {viewMode === 'students' && renderStudentsView()}
      {viewMode === 'communication' && renderCommunicationView()}
    </motion.div>
  );
}