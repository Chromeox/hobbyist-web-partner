'use client';

import React, { useState, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  X,
  Calendar,
  Clock,
  Users,
  User,
  Copy,
  Plus,
  Edit3,
  Trash2,
  Play,
  Pause,
  RotateCcw,
  Settings,
  AlertCircle,
  CheckCircle,
  Search,
  Filter,
  Download,
  RefreshCw,
  MapPin,
  DollarSign,
  Star,
  Zap,
  Save,
  ChevronDown,
  ChevronUp,
  Calendar as CalendarIcon,
  Repeat,
  Target,
  TrendingUp
} from 'lucide-react';
import type {
  ClassTemplate,
  RecurrenceRule,
  GeneratedSession,
  RecurringTemplatesProps
} from '../../../types/class-management';
import {
  getStatusColor,
  getLevelColor,
  formatFrequency,
  formatTime,
  formatDate,
  searchFilter,
  modalVariants
} from '../../../lib/utils/class-management-utils';

// Mock data - in production this would come from API

const mockTemplates: ClassTemplate[] = [
  {
    id: 'template_1',
    name: 'Morning Pottery Wheel',
    description: 'Beginner-friendly pottery wheel session focusing on centering and basic forms',
    category: 'Pottery',
    level: 'beginner',
    duration: 120,
    capacity: 8,
    price: 65,
    creditCost: 3,
    location: 'Ceramics Studio',
    instructorId: 'inst_1',
    instructorName: 'Sarah Johnson',
    materials: ['Clay', 'Tools', 'Aprons'],
    prerequisites: [],
    tags: ['pottery', 'wheel', 'beginner', 'morning'],
    status: 'active',
    createdDate: '2025-01-15',
    lastUsed: '2025-09-18',
    timesUsed: 24
  },
  {
    id: 'template_2',
    name: 'Watercolor Landscape Workshop',
    description: 'Learn landscape painting techniques with watercolors',
    category: 'Painting',
    level: 'intermediate',
    duration: 90,
    capacity: 12,
    price: 55,
    creditCost: 2,
    location: 'Art Studio',
    instructorId: 'inst_2',
    instructorName: 'Mike Chen',
    materials: ['Watercolor paints', 'Brushes', 'Paper'],
    prerequisites: ['Basic painting experience'],
    tags: ['watercolor', 'landscape', 'painting', 'intermediate'],
    status: 'active',
    createdDate: '2025-02-01',
    lastUsed: '2025-09-16',
    timesUsed: 18
  },
  {
    id: 'template_3',
    name: 'Seasonal Flower Arrangement',
    description: 'Create beautiful seasonal arrangements with fresh flowers',
    category: 'Floral Design',
    level: 'beginner',
    duration: 90,
    capacity: 10,
    price: 55,
    creditCost: 2,
    location: 'Garden Room',
    instructorId: 'inst_3',
    instructorName: 'Emily Davis',
    materials: ['Fresh flowers', 'Vase', 'Floral foam'],
    prerequisites: [],
    tags: ['flowers', 'arrangement', 'seasonal', 'beginner'],
    status: 'active',
    createdDate: '2025-03-01',
    timesUsed: 12
  }
];

const mockRecurrenceRules: RecurrenceRule[] = [
  {
    id: 'rule_1',
    templateId: 'template_1',
    frequency: 'weekly',
    interval: 1,
    daysOfWeek: [1, 3, 5], // Monday, Wednesday, Friday
    startDate: '2025-09-16',
    startTime: '09:00',
    endTime: '11:00',
    exceptions: ['2025-12-25', '2025-01-01'],
    generateAhead: 4, // 4 weeks ahead
    autoConfirm: false,
    requireInstructorConfirmation: true,
    status: 'active',
    createdDate: '2025-09-01',
    lastGenerated: '2025-09-15',
    nextGeneration: '2025-09-22',
    totalGenerated: 36
  },
  {
    id: 'rule_2',
    templateId: 'template_2',
    frequency: 'weekly',
    interval: 1,
    daysOfWeek: [2, 4], // Tuesday, Thursday
    startDate: '2025-09-17',
    startTime: '14:00',
    endTime: '15:30',
    exceptions: [],
    generateAhead: 6, // 6 weeks ahead
    autoConfirm: true,
    requireInstructorConfirmation: false,
    status: 'active',
    createdDate: '2025-09-05',
    lastGenerated: '2025-09-16',
    nextGeneration: '2025-09-23',
    totalGenerated: 24
  }
];

export default function RecurringTemplates({ onClose, onSave }: RecurringTemplatesProps) {
  const [activeTab, setActiveTab] = useState<'templates' | 'rules' | 'sessions' | 'automation'>('templates');
  const [templates, setTemplates] = useState<ClassTemplate[]>(mockTemplates);
  const [recurrenceRules, setRecurrenceRules] = useState<RecurrenceRule[]>(mockRecurrenceRules);
  const [selectedTemplate, setSelectedTemplate] = useState<ClassTemplate | null>(null);
  const [selectedRule, setSelectedRule] = useState<RecurrenceRule | null>(null);
  const [showCreateTemplate, setShowCreateTemplate] = useState(false);
  const [showCreateRule, setShowCreateRule] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterCategory, setFilterCategory] = useState('all');
  const [filterStatus, setFilterStatus] = useState('all');
  const [expandedTemplate, setExpandedTemplate] = useState<string | null>(null);

  const filteredTemplates = templates.filter(template => {
    const matchesSearch = template.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         template.description.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesCategory = filterCategory === 'all' || template.category === filterCategory;
    const matchesStatus = filterStatus === 'all' || template.status === filterStatus;
    return matchesSearch && matchesCategory && matchesStatus;
  });

  const categories = Array.from(new Set(templates.map(t => t.category)));

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active': return 'bg-green-100 text-green-700 border-green-200';
      case 'inactive': return 'bg-gray-100 text-gray-700 border-gray-200';
      case 'paused': return 'bg-yellow-100 text-yellow-700 border-yellow-200';
      case 'completed': return 'bg-blue-100 text-blue-700 border-blue-200';
      case 'draft': return 'bg-purple-100 text-purple-700 border-purple-200';
      default: return 'bg-gray-100 text-gray-700 border-gray-200';
    }
  };

  const getLevelColor = (level: string) => {
    switch (level) {
      case 'beginner': return 'bg-green-100 text-green-700';
      case 'intermediate': return 'bg-yellow-100 text-yellow-700';
      case 'advanced': return 'bg-red-100 text-red-700';
      default: return 'bg-gray-100 text-gray-700';
    }
  };

  const formatFrequency = (rule: RecurrenceRule) => {
    const { frequency, interval, daysOfWeek } = rule;
    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    if (frequency === 'weekly' && daysOfWeek) {
      const days = daysOfWeek.map(d => dayNames[d]).join(', ');
      return `Every ${interval > 1 ? interval + ' weeks' : 'week'} on ${days}`;
    }

    return `Every ${interval > 1 ? interval : ''} ${frequency.slice(0, -2)}${interval > 1 ? 's' : ''}`;
  };

  const formatTime = (time: string) => {
    return new Date(`2000-01-01T${time}:00`).toLocaleTimeString('en-US', {
      hour: 'numeric',
      minute: '2-digit',
      hour12: true
    });
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    });
  };

  const handleToggleRuleStatus = (ruleId: string) => {
    setRecurrenceRules(prev => prev.map(rule => {
      if (rule.id === ruleId) {
        const newStatus = rule.status === 'active' ? 'paused' : 'active';
        return { ...rule, status: newStatus };
      }
      return rule;
    }));
  };

  const handleDuplicateTemplate = (template: ClassTemplate) => {
    const newTemplate = {
      ...template,
      id: `template_${Date.now()}`,
      name: `${template.name} (Copy)`,
      createdDate: new Date().toISOString().split('T')[0],
      timesUsed: 0,
      lastUsed: undefined
    };
    setTemplates(prev => [...prev, newTemplate]);
  };

  return (
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
        className="bg-white rounded-xl shadow-xl max-w-7xl w-full max-h-[90vh] overflow-hidden"
      >
        {/* Header */}
        <div className="p-6 border-b border-gray-200 bg-gradient-to-r from-green-50 to-teal-50">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-2xl font-bold text-gray-900">Recurring Class Templates</h2>
              <p className="text-gray-600 mt-1">Create templates and automate recurring class schedules</p>
            </div>

            <div className="flex items-center gap-3">
              <div className="text-right">
                <div className="text-lg font-bold text-green-600">{templates.filter(t => t.status === 'active').length}</div>
                <div className="text-xs text-gray-600">Active Templates</div>
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
              { key: 'templates', label: 'Templates', count: templates.length },
              { key: 'rules', label: 'Recurrence Rules', count: recurrenceRules.length },
              { key: 'sessions', label: 'Generated Sessions' },
              { key: 'automation', label: 'Automation Settings' }
            ].map(tab => (
              <button
                key={tab.key}
                onClick={() => setActiveTab(tab.key as any)}
                className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                  activeTab === tab.key
                    ? 'bg-white text-green-600 shadow-sm'
                    : 'text-gray-600 hover:text-gray-900 hover:bg-white/50'
                }`}
              >
                {tab.label}
                {tab.count !== undefined && (
                  <span className="ml-2 px-2 py-0.5 bg-green-100 text-green-600 rounded-full text-xs">
                    {tab.count}
                  </span>
                )}
              </button>
            ))}
          </div>
        </div>

        {/* Content Area */}
        <div className="p-6 overflow-y-auto max-h-[65vh]">
          {/* Templates Tab */}
          {activeTab === 'templates' && (
            <div className="space-y-4">
              {/* Header Controls */}
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-4">
                  <div className="relative">
                    <Search className="h-4 w-4 absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
                    <input
                      type="text"
                      placeholder="Search templates..."
                      value={searchTerm}
                      onChange={(e) => setSearchTerm(e.target.value)}
                      className="pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                    />
                  </div>

                  <select
                    value={filterCategory}
                    onChange={(e) => setFilterCategory(e.target.value)}
                    className="border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-green-500"
                  >
                    <option value="all">All Categories</option>
                    {categories.map(category => (
                      <option key={category} value={category}>{category}</option>
                    ))}
                  </select>

                  <select
                    value={filterStatus}
                    onChange={(e) => setFilterStatus(e.target.value)}
                    className="border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-green-500"
                  >
                    <option value="all">All Status</option>
                    <option value="active">Active</option>
                    <option value="inactive">Inactive</option>
                    <option value="draft">Draft</option>
                  </select>
                </div>

                <button
                  onClick={() => setShowCreateTemplate(true)}
                  className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 flex items-center gap-2"
                >
                  <Plus className="h-4 w-4" />
                  Create Template
                </button>
              </div>

              {/* Templates List */}
              <div className="space-y-3">
                {filteredTemplates.map((template) => (
                  <motion.div
                    key={template.id}
                    layout
                    className="border border-gray-200 rounded-lg hover:shadow-md transition-shadow"
                  >
                    <div className="p-4">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-4">
                          <div className="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
                            <Copy className="h-6 w-6 text-green-600" />
                          </div>

                          <div>
                            <div className="font-medium text-gray-900">{template.name}</div>
                            <div className="text-sm text-gray-600">{template.description}</div>
                            <div className="flex items-center gap-2 mt-1">
                              <span className={`px-2 py-1 rounded-full text-xs ${getLevelColor(template.level)}`}>
                                {template.level}
                              </span>
                              <span className="px-2 py-1 bg-blue-100 text-blue-700 rounded-full text-xs">
                                {template.category}
                              </span>
                              <span className="text-xs text-gray-500">
                                Used {template.timesUsed} times
                              </span>
                            </div>
                          </div>
                        </div>

                        <div className="flex items-center gap-4">
                          <div className="text-right">
                            <div className="font-medium">${template.price}</div>
                            <div className="text-xs text-gray-600">{template.creditCost} credits</div>
                          </div>

                          <div className="text-right">
                            <div className="font-medium">{template.duration} min</div>
                            <div className="text-xs text-gray-600">Capacity: {template.capacity}</div>
                          </div>

                          <span className={`px-3 py-1 rounded-full text-sm font-medium border ${getStatusColor(template.status)}`}>
                            {template.status}
                          </span>

                          <div className="flex items-center gap-1">
                            <button
                              onClick={() => handleDuplicateTemplate(template)}
                              className="p-1 text-gray-400 hover:text-blue-600 rounded"
                              title="Duplicate template"
                            >
                              <Copy className="h-4 w-4" />
                            </button>
                            <button
                              onClick={() => setExpandedTemplate(
                                expandedTemplate === template.id ? null : template.id
                              )}
                              className="p-1 text-gray-400 hover:text-gray-600 rounded"
                            >
                              {expandedTemplate === template.id ? (
                                <ChevronUp className="h-4 w-4" />
                              ) : (
                                <ChevronDown className="h-4 w-4" />
                              )}
                            </button>
                          </div>
                        </div>
                      </div>

                      {/* Expanded Details */}
                      <AnimatePresence>
                        {expandedTemplate === template.id && (
                          <motion.div
                            initial={{ height: 0, opacity: 0 }}
                            animate={{ height: 'auto', opacity: 1 }}
                            exit={{ height: 0, opacity: 0 }}
                            className="mt-4 pt-4 border-t border-gray-200"
                          >
                            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                              <div>
                                <h5 className="font-medium text-gray-900 mb-2">Details</h5>
                                <div className="space-y-1 text-sm text-gray-600">
                                  <div className="flex justify-between">
                                    <span>Instructor:</span>
                                    <span>{template.instructorName || 'Not assigned'}</span>
                                  </div>
                                  <div className="flex justify-between">
                                    <span>Location:</span>
                                    <span>{template.location}</span>
                                  </div>
                                  <div className="flex justify-between">
                                    <span>Created:</span>
                                    <span>{formatDate(template.createdDate)}</span>
                                  </div>
                                  <div className="flex justify-between">
                                    <span>Last Used:</span>
                                    <span>{template.lastUsed ? formatDate(template.lastUsed) : 'Never'}</span>
                                  </div>
                                </div>
                              </div>

                              <div>
                                <h5 className="font-medium text-gray-900 mb-2">Materials</h5>
                                <div className="space-y-1">
                                  {template.materials.map(material => (
                                    <div key={material} className="text-sm text-gray-600">• {material}</div>
                                  ))}
                                </div>
                              </div>

                              <div>
                                <h5 className="font-medium text-gray-900 mb-2">Tags</h5>
                                <div className="flex flex-wrap gap-1">
                                  {template.tags.map(tag => (
                                    <span key={tag} className="px-2 py-1 bg-gray-100 text-gray-700 rounded text-xs">
                                      {tag}
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
                                <Repeat className="h-3 w-3 mr-1 inline" />
                                Create Rule
                              </button>
                              <button className="px-3 py-1 bg-purple-100 text-purple-700 rounded-lg hover:bg-purple-200 text-sm">
                                <TrendingUp className="h-3 w-3 mr-1 inline" />
                                Analytics
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

          {/* Recurrence Rules Tab */}
          {activeTab === 'rules' && (
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <h3 className="text-lg font-semibold">Recurrence Rules</h3>
                <button
                  onClick={() => setShowCreateRule(true)}
                  className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 flex items-center gap-2"
                >
                  <Plus className="h-4 w-4" />
                  Create Rule
                </button>
              </div>

              <div className="space-y-3">
                {recurrenceRules.map((rule) => {
                  const template = templates.find(t => t.id === rule.templateId);
                  return (
                    <div key={rule.id} className="p-4 border border-gray-200 rounded-lg">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-4">
                          <div className="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center">
                            <Repeat className="h-5 w-5 text-green-600" />
                          </div>

                          <div>
                            <div className="font-medium text-gray-900">{template?.name}</div>
                            <div className="text-sm text-gray-600">{formatFrequency(rule)}</div>
                            <div className="text-xs text-gray-500 flex items-center gap-3">
                              <span>Started: {formatDate(rule.startDate)}</span>
                              <span>Generated: {rule.totalGenerated} sessions</span>
                              <span>Next: {rule.nextGeneration ? formatDate(rule.nextGeneration) : 'N/A'}</span>
                            </div>
                          </div>
                        </div>

                        <div className="flex items-center gap-4">
                          <div className="text-right">
                            <div className="text-sm">
                              {formatTime(rule.startTime)} - {formatTime(rule.endTime)}
                            </div>
                            <div className="text-xs text-gray-600">
                              {rule.autoConfirm ? 'Auto-confirm' : 'Manual confirm'}
                            </div>
                          </div>

                          <span className={`px-2 py-1 rounded-full text-xs ${getStatusColor(rule.status)}`}>
                            {rule.status}
                          </span>

                          <div className="flex items-center gap-1">
                            <button
                              onClick={() => handleToggleRuleStatus(rule.id)}
                              className={`p-1 rounded ${
                                rule.status === 'active'
                                  ? 'text-yellow-600 hover:bg-yellow-100'
                                  : 'text-green-600 hover:bg-green-100'
                              }`}
                              title={rule.status === 'active' ? 'Pause rule' : 'Activate rule'}
                            >
                              {rule.status === 'active' ? (
                                <Pause className="h-4 w-4" />
                              ) : (
                                <Play className="h-4 w-4" />
                              )}
                            </button>
                            <button
                              className="p-1 text-blue-600 hover:bg-blue-100 rounded"
                              title="Edit rule"
                            >
                              <Edit3 className="h-4 w-4" />
                            </button>
                            <button
                              className="p-1 text-red-600 hover:bg-red-100 rounded"
                              title="Delete rule"
                            >
                              <Trash2 className="h-4 w-4" />
                            </button>
                          </div>
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {/* Generated Sessions Tab */}
          {activeTab === 'sessions' && (
            <div className="space-y-4">
              <h3 className="text-lg font-semibold">Generated Sessions</h3>

              <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
                  <div className="text-2xl font-bold text-blue-600">248</div>
                  <div className="text-sm text-blue-700">Total Generated</div>
                </div>
                <div className="p-4 bg-green-50 border border-green-200 rounded-lg">
                  <div className="text-2xl font-bold text-green-600">156</div>
                  <div className="text-sm text-green-700">Confirmed</div>
                </div>
                <div className="p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
                  <div className="text-2xl font-bold text-yellow-600">42</div>
                  <div className="text-sm text-yellow-700">Pending</div>
                </div>
                <div className="p-4 bg-purple-50 border border-purple-200 rounded-lg">
                  <div className="text-2xl font-bold text-purple-600">$12,450</div>
                  <div className="text-sm text-purple-700">Revenue</div>
                </div>
              </div>

              <div className="text-center py-8 text-gray-500">
                <CalendarIcon className="h-12 w-12 mx-auto mb-4 opacity-50" />
                <p>Generated sessions will appear here</p>
                <p className="text-sm">Sessions are automatically created based on your recurrence rules</p>
              </div>
            </div>
          )}

          {/* Automation Settings Tab */}
          {activeTab === 'automation' && (
            <div className="space-y-6">
              <h3 className="text-lg font-semibold">Automation Settings</h3>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="p-4 border border-gray-200 rounded-lg">
                  <h4 className="font-medium text-gray-900 mb-3">Generation Settings</h4>
                  <div className="space-y-3">
                    <div className="flex items-center justify-between">
                      <span className="text-sm text-gray-700">Auto-generate sessions</span>
                      <button className="w-10 h-6 bg-green-600 rounded-full p-1 transition-colors">
                        <div className="w-4 h-4 bg-white rounded-full transform translate-x-4"></div>
                      </button>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-sm text-gray-700">Default lead time</span>
                      <select
                        className="text-sm border border-gray-300 rounded px-2 py-1 appearance-none bg-white pr-8 cursor-pointer"
                        style={{
                          backgroundImage: `url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%236b7280' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='M6 8l4 4 4-4'/%3e%3c/svg%3e")`,
                          backgroundPosition: 'right 0.25rem center',
                          backgroundRepeat: 'no-repeat',
                          backgroundSize: '1.25em 1.25em'
                        }}
                      >
                        <option>4 weeks</option>
                        <option>6 weeks</option>
                        <option>8 weeks</option>
                      </select>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-sm text-gray-700">Generation frequency</span>
                      <select
                        className="text-sm border border-gray-300 rounded px-2 py-1 appearance-none bg-white pr-8 cursor-pointer"
                        style={{
                          backgroundImage: `url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%236b7280' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='M6 8l4 4 4-4'/%3e%3c/svg%3e")`,
                          backgroundPosition: 'right 0.25rem center',
                          backgroundRepeat: 'no-repeat',
                          backgroundSize: '1.25em 1.25em'
                        }}
                      >
                        <option>Weekly</option>
                        <option>Daily</option>
                        <option>Monthly</option>
                      </select>
                    </div>
                  </div>
                </div>

                <div className="p-4 border border-gray-200 rounded-lg">
                  <h4 className="font-medium text-gray-900 mb-3">Notifications</h4>
                  <div className="space-y-3">
                    <div className="flex items-center justify-between">
                      <span className="text-sm text-gray-700">Notify on generation</span>
                      <button className="w-10 h-6 bg-green-600 rounded-full p-1 transition-colors">
                        <div className="w-4 h-4 bg-white rounded-full transform translate-x-4"></div>
                      </button>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-sm text-gray-700">Notify instructors</span>
                      <button className="w-10 h-6 bg-green-600 rounded-full p-1 transition-colors">
                        <div className="w-4 h-4 bg-white rounded-full transform translate-x-4"></div>
                      </button>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-sm text-gray-700">Email summary</span>
                      <select
                        className="text-sm border border-gray-300 rounded px-2 py-1 appearance-none bg-white pr-8 cursor-pointer"
                        style={{
                          backgroundImage: `url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%236b7280' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='M6 8l4 4 4-4'/%3e%3c/svg%3e")`,
                          backgroundPosition: 'right 0.25rem center',
                          backgroundRepeat: 'no-repeat',
                          backgroundSize: '1.25em 1.25em'
                        }}
                      >
                        <option>Weekly</option>
                        <option>Daily</option>
                        <option>Monthly</option>
                      </select>
                    </div>
                  </div>
                </div>

                <div className="p-4 border border-gray-200 rounded-lg">
                  <h4 className="font-medium text-gray-900 mb-3">Conflicts & Exceptions</h4>
                  <div className="space-y-3">
                    <div className="flex items-center justify-between">
                      <span className="text-sm text-gray-700">Skip holidays</span>
                      <button className="w-10 h-6 bg-green-600 rounded-full p-1 transition-colors">
                        <div className="w-4 h-4 bg-white rounded-full transform translate-x-4"></div>
                      </button>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-sm text-gray-700">Check instructor availability</span>
                      <button className="w-10 h-6 bg-green-600 rounded-full p-1 transition-colors">
                        <div className="w-4 h-4 bg-white rounded-full transform translate-x-4"></div>
                      </button>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-sm text-gray-700">Avoid double-booking</span>
                      <button className="w-10 h-6 bg-green-600 rounded-full p-1 transition-colors">
                        <div className="w-4 h-4 bg-white rounded-full transform translate-x-4"></div>
                      </button>
                    </div>
                  </div>
                </div>

                <div className="p-4 border border-gray-200 rounded-lg">
                  <h4 className="font-medium text-gray-900 mb-3">Performance</h4>
                  <div className="space-y-2">
                    <div className="flex justify-between text-sm">
                      <span className="text-gray-700">Templates created:</span>
                      <span className="font-medium">{templates.length}</span>
                    </div>
                    <div className="flex justify-between text-sm">
                      <span className="text-gray-700">Rules active:</span>
                      <span className="font-medium">{recurrenceRules.filter(r => r.status === 'active').length}</span>
                    </div>
                    <div className="flex justify-between text-sm">
                      <span className="text-gray-700">Sessions generated:</span>
                      <span className="font-medium">{recurrenceRules.reduce((sum, r) => sum + r.totalGenerated, 0)}</span>
                    </div>
                    <div className="flex justify-between text-sm">
                      <span className="text-gray-700">Time saved:</span>
                      <span className="font-medium">~24 hours</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="p-6 border-t border-gray-200 bg-gray-50">
          <div className="flex items-center justify-between">
            <div className="text-sm text-gray-600">
              {filteredTemplates.length} templates • {recurrenceRules.filter(r => r.status === 'active').length} active rules
            </div>

            <div className="flex items-center gap-3">
              <button className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50">
                <Download className="h-4 w-4 mr-2 inline" />
                Export Templates
              </button>
              <button
                onClick={() => onSave && onSave(templates, recurrenceRules)}
                className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700"
              >
                <Save className="h-4 w-4 mr-2 inline" />
                Save Changes
              </button>
            </div>
          </div>
        </div>
      </motion.div>
    </motion.div>
  );
}