'use client';

import React, {
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
} from 'react';
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
  CreditCard,
  RefreshCw,
  Loader2,
} from 'lucide-react';
import ClassEditor from './ClassEditor';
import ClassSchedule from './ClassSchedule';
import InstructorAssignment from './InstructorAssignment';
import RecurringTemplates from './RecurringTemplates';
import BackButton from '@/components/common/BackButton';
import { useUserProfile } from '@/lib/hooks/useAuth';
import type { Class, ClassFormData } from '@/types/class-management';
import { mapClassToFormData, mapDbClassToUiClass } from '@/lib/utils/class-mappers';
import LoadingState, { LoadingStates } from '@/components/ui/LoadingState';

type ClassStatus = Class['status'];

const STATUS_OPTIONS: ClassStatus[] = ['active', 'inactive', 'draft'];

const generateLocalId = () =>
  typeof crypto !== 'undefined' && 'randomUUID' in crypto
    ? crypto.randomUUID()
    : Date.now().toString();

export default function ClassManagement() {
  const { profile, isLoading: isProfileLoading } = useUserProfile();
  const studioId = profile?.instructor?.id;

  const [classes, setClasses] = useState<Class[]>([]);
  const [filteredClasses, setFilteredClasses] = useState<Class[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [selectedStatus, setSelectedStatus] =
    useState<'all' | ClassStatus>('all');
  const [sortBy, setSortBy] = useState('name');
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');
  const [selectedClass, setSelectedClass] = useState<Class | null>(null);
  const [editorInitialData, setEditorInitialData] = useState<ClassFormData | undefined>(undefined);
  const [lastSavedClassId, setLastSavedClassId] = useState<string | null>(null);
  const [isEditorOpen, setIsEditorOpen] = useState(false);
  const [isScheduleOpen, setIsScheduleOpen] = useState(false);
  const [isInstructorAssignmentOpen, setIsInstructorAssignmentOpen] =
    useState(false);
  const [isRecurringTemplatesOpen, setIsRecurringTemplatesOpen] =
    useState(false);
  const [deleteConfirm, setDeleteConfirm] = useState<string | null>(null);
  const [deleteError, setDeleteError] = useState<string | null>(null);
  const [deleteInFlight, setDeleteInFlight] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const abortRef = useRef<AbortController | null>(null);
  const lastSavedTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const fetchClasses = useCallback(
    async (options: { silent?: boolean } = {}) => {
      const { silent = false } = options;

      if (abortRef.current) {
        abortRef.current.abort();
      }

      const controller = new AbortController();
      abortRef.current = controller;

      setError(null);
      if (silent) {
        setIsRefreshing(true);
      } else {
        setIsLoading(true);
      }

      try {
        const params = new URLSearchParams();
        if (studioId) {
          params.set('studioId', studioId);
        }

        const response = await fetch(
          `/api/classes/meta${params.size ? `?${params.toString()}` : ''}`,
          {
            method: 'GET',
            cache: 'no-store',
            signal: controller.signal,
          }
        );

        if (!response.ok) {
          const errorPayload = await response.json().catch(() => ({}));
          const message =
            typeof errorPayload?.error === 'string'
              ? errorPayload.error
              : `Failed to load classes (${response.status})`;
          throw new Error(message);
        }

        const payload = await response.json();
        const rawItems = Array.isArray(payload?.classes) ? payload.classes : [];
        const mapped = rawItems.map((item: any) =>
          item && typeof item === 'object' && 'instructor' in item && 'creditCost' in item
            ? (item as Class)
            : mapDbClassToUiClass(item)
        );

        setClasses(mapped);
        setLastSavedClassId(null);
      } catch (err) {
        if (controller.signal.aborted) return;
        console.error('Failed to load classes', err);
        setClasses([]);
        setError(
          err instanceof Error ? err.message : 'Unable to load classes right now.'
        );
      } finally {
        if (!controller.signal.aborted) {
          setIsLoading(false);
          setIsRefreshing(false);
          abortRef.current = null;
        }
      }
    },
    [studioId]
  );

  useEffect(() => {
    fetchClasses();
    return () => {
      abortRef.current?.abort();
      if (lastSavedTimerRef.current) {
        clearTimeout(lastSavedTimerRef.current);
      }
    };
  }, [fetchClasses]);

  const categoryOptions = useMemo(() => {
    const set = new Set<string>();
    classes.forEach((cls) => {
      if (cls.category) set.add(cls.category);
    });
    const options = Array.from(set).sort((a, b) => a.localeCompare(b));
    return ['all', ...options];
  }, [classes]);

  useEffect(() => {
    let filtered = classes.filter((cls) => {
      const term = searchTerm.trim().toLowerCase();
      const matchesSearch =
        term.length === 0 ||
        cls.name.toLowerCase().includes(term) ||
        cls.instructor.toLowerCase().includes(term) ||
        cls.category.toLowerCase().includes(term);

      const matchesCategory =
        selectedCategory === 'all' ||
        cls.category.toLowerCase() === selectedCategory.toLowerCase();

      const matchesStatus =
        selectedStatus === 'all' || cls.status === selectedStatus;

      return matchesSearch && matchesCategory && matchesStatus;
    });

    filtered = filtered.sort((a, b) => {
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
          return (
            new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime()
          );
        default:
          return 0;
      }
    });

    setFilteredClasses(filtered);
  }, [classes, searchTerm, selectedCategory, selectedStatus, sortBy]);

  const handleRefresh = () => {
    fetchClasses({ silent: true });
  };

  const handleCreateClass = () => {
    setSelectedClass(null);
    setEditorInitialData(undefined);
    setIsEditorOpen(true);
  };

  const handleEditClass = (cls: Class) => {
    setSelectedClass(cls);
    setEditorInitialData(mapClassToFormData(cls));
    setIsEditorOpen(true);
  };

  const handleCloseEditor = () => {
    setIsEditorOpen(false);
    setEditorInitialData(undefined);
    setSelectedClass(null);
  };

  const handleDuplicateClass = (cls: Class) => {
    const now = new Date().toISOString();
    const newClass: Class = {
      ...cls,
      id: generateLocalId(),
      name: `${cls.name} (Copy)`,
      status: 'draft',
      categoryId: cls.categoryId,
      totalBookings: 0,
      nextSession: undefined,
      createdAt: now,
      updatedAt: now,
    };
    setClasses((prev) => [newClass, ...prev]);
    setLastSavedClassId(newClass.id);
    if (lastSavedTimerRef.current) {
      clearTimeout(lastSavedTimerRef.current);
    }
    lastSavedTimerRef.current = setTimeout(() => {
      setLastSavedClassId((current) =>
        current === newClass.id ? null : current
      );
    }, 4000);
  };

  const closeDeleteDialog = () => {
    setDeleteConfirm(null);
    setDeleteError(null);
    setDeleteInFlight(null);
  };

  const handleDeleteClass = async (classId: string | null) => {
    if (!classId) return;

    setDeleteError(null);
    setDeleteInFlight(classId);

    try {
      const response = await fetch(`/api/classes/meta/${classId}`, {
        method: 'DELETE',
      });

      if (!response.ok) {
        const errorPayload = await response.json().catch(() => ({}));
        const message =
          typeof errorPayload?.error === 'string'
            ? errorPayload.error
            : 'Failed to delete class';
        throw new Error(message);
      }

      setClasses((prev) => prev.filter((cls) => cls.id !== classId));
      closeDeleteDialog();
      await fetchClasses({ silent: true });
    } catch (err) {
      console.error('Failed to delete class', err);
      setDeleteError(
        err instanceof Error ? err.message : 'Unable to delete class.'
      );
    } finally {
      setDeleteInFlight((current) => (current === classId ? null : current));
    }
  };

  const handleSaveClass = async (classData: ClassFormData): Promise<void> => {
    const targetUrl = classData.id
      ? `/api/classes/meta/${classData.id}`
      : '/api/classes/meta';

    const response = await fetch(targetUrl, {
      method: classData.id ? 'PUT' : 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        class: classData,
        studioId: studioId ?? undefined,
      }),
    });

    if (!response.ok) {
      const errorPayload = await response.json().catch(() => ({}));
      const action = classData.id ? 'update' : 'create';
      const message =
        typeof errorPayload?.error === 'string'
          ? errorPayload.error
          : `Failed to ${action} class`;
      throw new Error(message);
    }

    const payload = await response.json();
    const savedRaw =
      payload?.class ??
      (Array.isArray(payload?.classes) ? payload.classes[0] : null);

    if (!savedRaw || typeof savedRaw !== 'object') {
      throw new Error('Missing class data in save response');
    }

    const savedClass: Class =
      'instructor' in savedRaw && 'creditCost' in savedRaw
        ? (savedRaw as Class)
        : mapDbClassToUiClass(savedRaw);

    setClasses((prev) => {
      const exists = prev.some((cls) => cls.id === savedClass.id);
      if (exists) {
        return prev.map((cls) =>
          cls.id === savedClass.id ? { ...cls, ...savedClass } : cls
        );
      }
      return [savedClass, ...prev];
    });

    handleCloseEditor();
    setLastSavedClassId(savedClass.id);

    if (lastSavedTimerRef.current) {
      clearTimeout(lastSavedTimerRef.current);
    }
    lastSavedTimerRef.current = setTimeout(() => {
      setLastSavedClassId((current) =>
        current === savedClass.id ? null : current
      );
    }, 4000);
  };

  const getLevelColor = (level: string) => {
    switch (level) {
      case 'beginner':
        return 'bg-green-100 text-green-700';
      case 'intermediate':
        return 'bg-yellow-100 text-yellow-700';
      case 'advanced':
        return 'bg-red-100 text-red-700';
      default:
        return 'bg-gray-100 text-gray-700';
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active':
        return 'bg-green-100 text-green-700';
      case 'inactive':
        return 'bg-gray-100 text-gray-700';
      case 'draft':
        return 'bg-yellow-100 text-yellow-700';
      default:
        return 'bg-gray-100 text-gray-700';
    }
  };

  const handleOpenSchedule = () => {
    setIsScheduleOpen(true);
  };

  const handleOpenInstructorAssignment = () => {
    setIsInstructorAssignmentOpen(true);
  };

  const handleOpenRecurringTemplates = () => {
    setIsRecurringTemplatesOpen(true);
  };

  const loadingState =
    isLoading && !isRefreshing && !isProfileLoading && classes.length === 0;

  return (
    <div className="space-y-8">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <BackButton href="/dashboard" label="Back to Dashboard" />

        <div className="flex items-center gap-2">
          <button
            onClick={handleRefresh}
            className="inline-flex items-center gap-2 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
            disabled={isRefreshing}
          >
            {isRefreshing ? (
              <Loader2 className="h-4 w-4 animate-spin" />
            ) : (
              <RefreshCw className="h-4 w-4" />
            )}
            <span>Refresh</span>
          </button>

          <button
            onClick={handleCreateClass}
            className="inline-flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            <Plus className="h-4 w-4" />
            <span>New Class</span>
          </button>
        </div>
      </div>

      <div className="bg-white rounded-2xl border border-gray-200 shadow-sm">
        <div className="p-6 border-b border-gray-200 flex flex-col md:flex-row md:items-center md:justify-between gap-4">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Class Management</h1>
            <p className="text-gray-600 mt-1">
              Manage your studio&apos;s classes, schedules, and instructors.
            </p>

            {studioId && (
              <p className="text-xs text-gray-500 mt-2">
                Filtering results for studio <span className="font-medium">{studioId}</span>
              </p>
            )}
          </div>

          <div className="flex items-center gap-3">
            <button
              onClick={() => setViewMode(viewMode === 'grid' ? 'list' : 'grid')}
              className="px-3 py-2 border border-gray-200 rounded-lg text-sm text-gray-700 hover:bg-gray-50"
            >
              View: {viewMode === 'grid' ? 'Grid' : 'List'}
            </button>

            <button
              onClick={handleOpenSchedule}
              className="px-3 py-2 border border-gray-200 rounded-lg text-sm text-gray-700 hover:bg-gray-50 flex items-center gap-2"
            >
              <Calendar className="h-4 w-4" />
              Schedule
            </button>

            <button
              onClick={handleOpenInstructorAssignment}
              className="px-3 py-2 border border-gray-200 rounded-lg text-sm text-gray-700 hover:bg-gray-50 flex items-center gap-2"
            >
              <User className="h-4 w-4" />
              Assign Instructors
            </button>

            <button
              onClick={handleOpenRecurringTemplates}
              className="px-3 py-2 border border-gray-200 rounded-lg text-sm text-gray-700 hover:bg-gray-50 flex items-center gap-2"
            >
              <Filter className="h-4 w-4" />
              Recurring
            </button>
          </div>
        </div>

        <div className="p-6 border-b border-gray-200">
          <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
            <div className="flex-1 relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
              <input
                type="text"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                placeholder="Search classes by name, instructor, or category"
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>

            <div className="flex flex-wrap items-center gap-3">
              <select
                value={selectedCategory}
                onChange={(e) => setSelectedCategory(e.target.value)}
                className="pl-3 pr-10 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent appearance-none bg-white"
              >
                {categoryOptions.map((category) => (
                  <option key={category} value={category}>
                    {category === 'all'
                      ? 'All Categories'
                      : category}
                  </option>
                ))}
              </select>

              <select
                value={selectedStatus}
                onChange={(e) =>
                  setSelectedStatus(e.target.value as 'all' | ClassStatus)
                }
                className="pl-3 pr-10 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent appearance-none bg-white"
              >
                {['all', ...STATUS_OPTIONS].map((status) => (
                  <option key={status} value={status}>
                    {status === 'all'
                      ? 'All Statuses'
                      : status.charAt(0).toUpperCase() + status.slice(1)}
                  </option>
                ))}
              </select>

              <select
                value={sortBy}
                onChange={(e) => setSortBy(e.target.value)}
                className="pl-3 pr-10 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent appearance-none bg-white"
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
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 rounded-xl p-4 flex items-start gap-3">
          <AlertCircle className="h-5 w-5 mt-0.5" />
          <div className="flex-1">
            <p className="font-medium">We couldn&apos;t load your classes.</p>
            <p className="text-sm mt-1">{error}</p>
          </div>
          <button
            onClick={handleRefresh}
            className="px-3 py-2 bg-red-600 text-white rounded-lg text-sm hover:bg-red-700 transition-colors"
          >
            Retry
          </button>
        </div>
      )}

      {loadingState ? (
        <LoadingState 
          message={LoadingStates.classes.message}
          description={LoadingStates.classes.description}
          size="lg"
        />
      ) : (
        <div
          className={viewMode === 'grid'
            ? 'grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6'
            : 'space-y-4'}
        >
          {filteredClasses.map((cls) => (
            <motion.div
              key={cls.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              className={`bg-white rounded-xl shadow-sm border hover:shadow-md transition-shadow overflow-hidden group ${
                viewMode === 'list' ? 'flex' : ''
              }`}
            >
              <div className={viewMode === 'list' ? 'w-1/3 relative bg-gradient-to-br from-blue-500 to-purple-600' : 'relative h-48 bg-gradient-to-br from-blue-500 to-purple-600'}>
                <div className="absolute inset-0 flex items-center justify-center">
                  <ImageIcon className="h-12 w-12 text-white opacity-50" />
                </div>

                <div className="absolute top-3 right-3 flex items-center gap-2">
                  <span
                    className={`px-2 py-1 text-sm font-medium rounded-full ${getStatusColor(
                      cls.status
                    )}`}
                  >
                    {cls.status}
                  </span>
                </div>

                <div className="absolute top-3 left-3">
                  <span
                    className={`px-2 py-1 text-sm font-medium rounded-full ${getLevelColor(
                      cls.level
                    )}`}
                  >
                    {cls.level}
                  </span>
                </div>
              </div>

              <div className={viewMode === 'list' ? 'flex-1 p-4' : 'p-4'}>
                <div className="flex items-start justify-between mb-2">
                  <h3 className="font-semibold text-gray-900 text-lg">
                    {cls.name}
                  </h3>
                  <div className="relative">
                    <button className="p-1 hover:bg-gray-100 rounded-full opacity-0 group-hover:opacity-100 transition-opacity">
                      <MoreVertical className="h-4 w-4 text-gray-500" />
                    </button>
                  </div>
                </div>

                <p className="text-gray-600 text-sm mb-3 line-clamp-2">
                  {cls.description}
                </p>

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
                    <MapPin className="h-4 w-4 mr-2" />
                    {cls.location}
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
                    {cls.rating.toFixed(1)} ({cls.totalBookings} bookings)
                  </div>
                </div>

                {cls.nextSession && (
                  <div className="bg-blue-50 rounded-lg p-3 mb-4">
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="text-sm font-medium text-blue-900">
                          Next Session
                        </p>
                        <p className="text-sm text-blue-700">
                          {new Date(cls.nextSession.date).toLocaleDateString()} at{' '}
                          {cls.nextSession.time}
                        </p>
                      </div>
                      <div className="text-right">
                        <p className="text-sm font-medium text-blue-900">
                          {cls.nextSession.enrolled}/{cls.nextSession.capacity ?? cls.capacity}
                        </p>
                        <p className="text-xs text-blue-700">enrolled</p>
                      </div>
                    </div>
                  </div>
                )}

                <div className="flex flex-wrap items-center gap-2 mb-4">
                  {cls.tags.slice(0, 4).map((tag) => (
                    <span
                      key={tag}
                      className="px-2 py-1 text-xs bg-gray-100 text-gray-600 rounded-full flex items-center gap-1"
                    >
                      <Tag className="h-3 w-3" />
                      {tag}
                    </span>
                  ))}
                  {cls.tags.length > 4 && (
                    <span className="text-xs text-gray-500">
                      +{cls.tags.length - 4} more
                    </span>
                  )}
                </div>

                {lastSavedClassId === cls.id && (
                  <div className="flex items-center text-sm text-green-600 mb-3">
                    <CheckCircle className="h-4 w-4 mr-2" />
                    Changes saved successfully
                  </div>
                )}

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
                    onClick={() => {
                      setDeleteError(null);
                      setDeleteConfirm(cls.id);
                    }}
                    className="px-3 py-2 text-sm border border-red-300 text-red-700 rounded-lg hover:bg-red-50 transition-colors"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </div>
              </div>
            </motion.div>
          ))}
        </div>
      )}

      {!loadingState && filteredClasses.length === 0 && (
        <div className="text-center py-12">
          <BookOpen className="h-16 w-16 text-gray-300 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">
            No classes found
          </h3>
          <p className="text-gray-600 mb-4">
            {searchTerm
              ? 'Try adjusting your search filters'
              : 'Get started by creating your first class'}
          </p>
          <button
            onClick={handleCreateClass}
            className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            Create Class
          </button>
        </div>
      )}

      <AnimatePresence>
        {isEditorOpen && (
          <ClassEditor
            class={editorInitialData}
            onSave={handleSaveClass}
            onClose={handleCloseEditor}
            studioId={studioId ?? null}
          />
        )}
      </AnimatePresence>

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
                <h3 className="text-xl font-semibold text-gray-900">
                  Delete Class
                </h3>
              </div>

              <p className="text-gray-600 mb-6">
                Are you sure you want to delete this class? This action cannot be
                undone.
              </p>

              {deleteError && (
                <div className="bg-red-50 border border-red-200 text-red-700 rounded-lg p-3 text-sm mb-4">
                  {deleteError}
                </div>
              )}

              <div className="flex items-center gap-3">
                <button
                  onClick={closeDeleteDialog}
                  className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={() => handleDeleteClass(deleteConfirm)}
                  disabled={deleteInFlight === deleteConfirm}
                  className="flex-1 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors disabled:opacity-60 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                >
                  {deleteInFlight === deleteConfirm ? (
                    <>
                      <Loader2 className="h-4 w-4 animate-spin" />
                      Deleting...
                    </>
                  ) : (
                    'Delete'
                  )}
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
