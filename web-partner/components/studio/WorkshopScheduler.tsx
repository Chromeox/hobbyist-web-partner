'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Calendar,
  Clock,
  Users,
  MapPin,
  Plus,
  Edit,
  Copy,
  Trash2,
  AlertTriangle,
  CheckCircle,
  Settings,
  Filter,
  Search,
  ChevronLeft,
  ChevronRight,
  Grid,
  List,
  Palette,
  Hammer,
  Music,
  ChefHat
} from 'lucide-react';

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { formatDuration, calculateCapacity, getCategoryColor, hasTimeConflict } from '@/lib/utils';

interface Room {
  id: string;
  name: string;
  capacity: number;
  equipment: string[];
  suitableFor: string[]; // workshop categories
  hourlyRate?: number;
}

interface Workshop {
  id: string;
  name: string;
  category: string;
  skill_level: 'beginner' | 'intermediate' | 'advanced' | 'all_levels';
  duration: number; // minutes
  max_participants: number;
  price: number;
  material_fee: number;
  instructor_id?: string;
  instructor_name?: string;
  equipment_needed: string[];
  materials_required: string[];
  description?: string;
}

interface ScheduledWorkshop {
  id: string;
  workshop_id: string;
  workshop: Workshop;
  room_id: string;
  room: Room;
  start_time: Date;
  end_time: Date;
  spots_booked: number;
  spots_available: number;
  status: 'scheduled' | 'in_progress' | 'completed' | 'cancelled';
  recurring_pattern?: {
    type: 'weekly' | 'biweekly' | 'monthly';
    days: string[];
    end_date?: Date;
  };
  notes?: string;
}

interface Conflict {
  type: 'room_conflict' | 'instructor_conflict' | 'equipment_conflict' | 'capacity_conflict';
  severity: 'high' | 'medium' | 'low';
  message: string;
  workshops: ScheduledWorkshop[];
}

interface WorkshopSchedulerProps {
  studioId: string;
  rooms: Room[];
  workshops: Workshop[];
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
  pottery: 'bg-amber-100 border-amber-300 text-amber-800',
  painting: 'bg-blue-100 border-blue-300 text-blue-800',
  woodworking: 'bg-orange-100 border-orange-300 text-orange-800',
  jewelry: 'bg-purple-100 border-purple-300 text-purple-800',
  cooking: 'bg-green-100 border-green-300 text-green-800',
  music: 'bg-pink-100 border-pink-300 text-pink-800',
};

export function WorkshopScheduler({ studioId, rooms, workshops }: WorkshopSchedulerProps) {
  const [currentDate, setCurrentDate] = useState(new Date());
  const [viewMode, setViewMode] = useState<'week' | 'month'>('week');
  const [scheduledWorkshops, setScheduledWorkshops] = useState<ScheduledWorkshop[]>([]);
  const [selectedSlot, setSelectedSlot] = useState<{ date: Date; room: Room } | null>(null);
  const [conflicts, setConflicts] = useState<Conflict[]>([]);
  const [showAddModal, setShowAddModal] = useState(false);
  const [selectedWorkshop, setSelectedWorkshop] = useState<ScheduledWorkshop | null>(null);
  const [loading, setLoading] = useState(true);
  const [filters, setFilters] = useState({
    category: '',
    instructor: '',
    room: '',
    status: '',
  });

  useEffect(() => {
    fetchScheduledWorkshops();
  }, [studioId, currentDate, viewMode]);

  useEffect(() => {
    detectConflicts();
  }, [scheduledWorkshops]);

  const fetchScheduledWorkshops = async () => {
    setLoading(true);
    try {
      // Mock data - replace with actual API call
      const mockScheduled: ScheduledWorkshop[] = [
        {
          id: '1',
          workshop_id: 'w1',
          workshop: {
            id: 'w1',
            name: 'Beginner Pottery Wheel',
            category: 'pottery',
            skill_level: 'beginner',
            duration: 120,
            max_participants: 8,
            price: 95,
            material_fee: 15,
            instructor_name: 'Sarah Chen',
            equipment_needed: ['pottery_wheel', 'kiln_access'],
            materials_required: ['clay', 'glazes', 'tools'],
            description: 'Learn the basics of throwing pottery on the wheel'
          },
          room_id: 'r1',
          room: { id: 'r1', name: 'Pottery Studio', capacity: 10, equipment: ['pottery_wheel', 'kiln'], suitableFor: ['pottery'] },
          start_time: new Date(2025, 8, 18, 10, 0),
          end_time: new Date(2025, 8, 18, 12, 0),
          spots_booked: 6,
          spots_available: 2,
          status: 'scheduled',
          recurring_pattern: {
            type: 'weekly',
            days: ['tuesday', 'thursday'],
            end_date: new Date(2025, 11, 31)
          }
        },
        {
          id: '2',
          workshop_id: 'w2',
          workshop: {
            id: 'w2',
            name: 'Watercolor Landscapes',
            category: 'painting',
            skill_level: 'intermediate',
            duration: 90,
            max_participants: 12,
            price: 75,
            material_fee: 10,
            instructor_name: 'Michael Torres',
            equipment_needed: ['easels'],
            materials_required: ['watercolor_paints', 'brushes', 'paper'],
            description: 'Paint beautiful landscapes with watercolor techniques'
          },
          room_id: 'r2',
          room: { id: 'r2', name: 'Art Studio', capacity: 15, equipment: ['easels', 'lighting'], suitableFor: ['painting', 'drawing'] },
          start_time: new Date(2025, 8, 18, 14, 0),
          end_time: new Date(2025, 8, 18, 15, 30),
          spots_booked: 8,
          spots_available: 4,
          status: 'scheduled'
        }
      ];

      setScheduledWorkshops(mockScheduled);
    } catch (error) {
      console.error('Failed to fetch scheduled workshops:', error);
    } finally {
      setLoading(false);
    }
  };

  const detectConflicts = useCallback(() => {
    const detectedConflicts: Conflict[] = [];

    // Check for room conflicts
    for (let i = 0; i < scheduledWorkshops.length; i++) {
      for (let j = i + 1; j < scheduledWorkshops.length; j++) {
        const workshop1 = scheduledWorkshops[i];
        const workshop2 = scheduledWorkshops[j];

        // Same room, overlapping time
        if (workshop1.room_id === workshop2.room_id &&
            hasTimeConflict(workshop1.start_time, workshop1.end_time, workshop2.start_time, workshop2.end_time)) {
          detectedConflicts.push({
            type: 'room_conflict',
            severity: 'high',
            message: `Room conflict: ${workshop1.room.name} is double-booked`,
            workshops: [workshop1, workshop2]
          });
        }

        // Same instructor, overlapping time
        if (workshop1.workshop.instructor_name === workshop2.workshop.instructor_name &&
            hasTimeConflict(workshop1.start_time, workshop1.end_time, workshop2.start_time, workshop2.end_time)) {
          detectedConflicts.push({
            type: 'instructor_conflict',
            severity: 'high',
            message: `Instructor conflict: ${workshop1.workshop.instructor_name} is double-booked`,
            workshops: [workshop1, workshop2]
          });
        }

        // Equipment conflicts
        const sharedEquipment = workshop1.workshop.equipment_needed.filter(eq =>
          workshop2.workshop.equipment_needed.includes(eq)
        );
        if (sharedEquipment.length > 0 &&
            hasTimeConflict(workshop1.start_time, workshop1.end_time, workshop2.start_time, workshop2.end_time)) {
          detectedConflicts.push({
            type: 'equipment_conflict',
            severity: 'medium',
            message: `Equipment conflict: ${sharedEquipment.join(', ')} needed for both workshops`,
            workshops: [workshop1, workshop2]
          });
        }
      }

      // Check capacity issues
      const workshop = scheduledWorkshops[i];
      if (workshop.spots_booked > workshop.workshop.max_participants) {
        detectedConflicts.push({
          type: 'capacity_conflict',
          severity: 'medium',
          message: `Overbooked: ${workshop.workshop.name} has ${workshop.spots_booked} bookings for ${workshop.workshop.max_participants} spots`,
          workshops: [workshop]
        });
      }
    }

    setConflicts(detectedConflicts);
  }, [scheduledWorkshops]);

  const getWeekDays = (date: Date) => {
    const week = [];
    const startOfWeek = new Date(date);
    startOfWeek.setDate(date.getDate() - date.getDay()); // Start on Sunday

    for (let i = 0; i < 7; i++) {
      const day = new Date(startOfWeek);
      day.setDate(startOfWeek.getDate() + i);
      week.push(day);
    }
    return week;
  };

  const getWorkshopsForDay = (date: Date, roomId?: string) => {
    return scheduledWorkshops.filter(workshop => {
      const workshopDate = new Date(workshop.start_time);
      const isSameDay = workshopDate.toDateString() === date.toDateString();
      const matchesRoom = !roomId || workshop.room_id === roomId;
      return isSameDay && matchesRoom;
    });
  };

  const getConflictSeverity = (workshopId: string): 'high' | 'medium' | 'low' | null => {
    const conflict = conflicts.find(c => c.workshops.some(w => w.id === workshopId));
    return conflict?.severity || null;
  };

  const handleScheduleWorkshop = (slot: { date: Date; room: Room }) => {
    setSelectedSlot(slot);
    setShowAddModal(true);
  };

  const renderTimeSlots = () => {
    const hours = Array.from({ length: 12 }, (_, i) => i + 8); // 8 AM to 8 PM

    return (
      <div className="grid grid-cols-8 gap-1 text-xs">
        {/* Header */}
        <div className="sticky top-0 bg-white p-2 border-b font-medium">Time</div>
        {rooms.map(room => (
          <div key={room.id} className="sticky top-0 bg-white p-2 border-b font-medium">
            {room.name}
            <div className="text-gray-500 text-xs">{room.capacity} max</div>
          </div>
        ))}

        {/* Time slots */}
        {hours.map(hour => (
          <React.Fragment key={hour}>
            <div className="p-2 border-r bg-gray-50 font-medium">
              {hour}:00
            </div>
            {rooms.map(room => (
              <div
                key={`${hour}-${room.id}`}
                className="relative min-h-16 border border-gray-200 hover:bg-gray-50 cursor-pointer"
                onClick={() => handleScheduleWorkshop({
                  date: new Date(currentDate.getFullYear(), currentDate.getMonth(), currentDate.getDate(), hour),
                  room
                })}
              >
                {getWorkshopsForDay(currentDate, room.id)
                  .filter(workshop => new Date(workshop.start_time).getHours() === hour)
                  .map(workshop => {
                    const Icon = CATEGORY_ICONS[workshop.workshop.category as keyof typeof CATEGORY_ICONS] || Palette;
                    const severity = getConflictSeverity(workshop.id);

                    return (
                      <motion.div
                        key={workshop.id}
                        initial={{ scale: 0.9, opacity: 0 }}
                        animate={{ scale: 1, opacity: 1 }}
                        className={`absolute inset-1 p-1 rounded text-xs ${
                          CATEGORY_COLORS[workshop.workshop.category as keyof typeof CATEGORY_COLORS] || 'bg-gray-100'
                        } ${
                          severity === 'high' ? 'ring-2 ring-red-500' :
                          severity === 'medium' ? 'ring-2 ring-yellow-500' : ''
                        }`}
                        onClick={(e) => {
                          e.stopPropagation();
                          setSelectedWorkshop(workshop);
                        }}
                      >
                        <div className="flex items-center justify-between">
                          <Icon className="h-3 w-3" />
                          {severity && (
                            <AlertTriangle className={`h-3 w-3 ${
                              severity === 'high' ? 'text-red-500' : 'text-yellow-500'
                            }`} />
                          )}
                        </div>
                        <div className="font-medium truncate">{workshop.workshop.name}</div>
                        <div className="text-xs opacity-75">
                          {workshop.spots_booked}/{workshop.workshop.max_participants}
                        </div>
                        <div className="text-xs opacity-75">
                          {formatDuration(workshop.workshop.duration)}
                        </div>
                      </motion.div>
                    );
                  })}
              </div>
            ))}
          </React.Fragment>
        ))}
      </div>
    );
  };

  const renderWeekView = () => {
    const weekDays = getWeekDays(currentDate);

    return (
      <div className="space-y-4">
        {/* Week navigation */}
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-4">
            <Button
              variant="outline"
              size="sm"
              onClick={() => {
                const newDate = new Date(currentDate);
                newDate.setDate(currentDate.getDate() - 7);
                setCurrentDate(newDate);
              }}
            >
              <ChevronLeft className="h-4 w-4" />
            </Button>
            <h3 className="text-lg font-medium">
              {weekDays[0].toLocaleDateString('en-US', { month: 'long', day: 'numeric' })} -{' '}
              {weekDays[6].toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' })}
            </h3>
            <Button
              variant="outline"
              size="sm"
              onClick={() => {
                const newDate = new Date(currentDate);
                newDate.setDate(currentDate.getDate() + 7);
                setCurrentDate(newDate);
              }}
            >
              <ChevronRight className="h-4 w-4" />
            </Button>
          </div>
          <Button
            variant="outline"
            size="sm"
            onClick={() => setCurrentDate(new Date())}
          >
            Today
          </Button>
        </div>

        {/* Day tabs */}
        <div className="flex space-x-1 bg-gray-100 p-1 rounded-lg">
          {weekDays.map((day, index) => {
            const isToday = day.toDateString() === new Date().toDateString();
            const isSelected = day.toDateString() === currentDate.toDateString();

            return (
              <button
                key={index}
                onClick={() => setCurrentDate(day)}
                className={`flex-1 py-2 px-3 rounded-md text-sm font-medium transition-colors ${
                  isSelected
                    ? 'bg-white text-blue-600 shadow-sm'
                    : 'text-gray-600 hover:text-gray-900'
                } ${isToday ? 'ring-2 ring-blue-200' : ''}`}
              >
                <div>{day.toLocaleDateString('en-US', { weekday: 'short' })}</div>
                <div className="text-xs">{day.getDate()}</div>
              </button>
            );
          })}
        </div>

        {/* Time slots grid */}
        <Card>
          <CardContent className="p-0">
            <div className="overflow-x-auto">
              {renderTimeSlots()}
            </div>
          </CardContent>
        </Card>
      </div>
    );
  };

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="animate-pulse">
          <div className="h-8 bg-gray-200 rounded w-1/3 mb-4"></div>
          <div className="grid grid-cols-8 gap-2 h-96">
            {[...Array(56)].map((_, i) => (
              <div key={i} className="bg-gray-200 rounded"></div>
            ))}
          </div>
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
          <h1 className="text-3xl font-bold text-gray-900">Workshop Scheduler</h1>
          <p className="text-gray-600">Manage your creative workshop schedule and room allocation</p>
        </div>
        <div className="flex items-center gap-2">
          <Button
            variant={viewMode === 'week' ? 'default' : 'outline'}
            size="sm"
            onClick={() => setViewMode('week')}
          >
            <Calendar className="h-4 w-4 mr-2" />
            Week
          </Button>
          <Button
            variant={viewMode === 'month' ? 'default' : 'outline'}
            size="sm"
            onClick={() => setViewMode('month')}
          >
            <Grid className="h-4 w-4 mr-2" />
            Month
          </Button>
          <Button variant="creative">
            <Plus className="h-4 w-4 mr-2" />
            Add Workshop
          </Button>
        </div>
      </div>

      {/* Conflicts Alert */}
      {conflicts.length > 0 && (
        <Card className="border-red-200 bg-red-50">
          <CardHeader>
            <CardTitle className="flex items-center text-red-800">
              <AlertTriangle className="h-5 w-5 mr-2" />
              Scheduling Conflicts Detected
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              {conflicts.slice(0, 3).map((conflict, index) => (
                <div key={index} className="flex items-center justify-between p-2 bg-white rounded border">
                  <div>
                    <p className="text-sm font-medium text-red-800">{conflict.message}</p>
                    <p className="text-xs text-red-600">
                      Affects: {conflict.workshops.map(w => w.workshop.name).join(', ')}
                    </p>
                  </div>
                  <Badge variant="destructive">{conflict.severity}</Badge>
                </div>
              ))}
              {conflicts.length > 3 && (
                <p className="text-sm text-red-600">
                  +{conflicts.length - 3} more conflicts
                </p>
              )}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Studio Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Today's Workshops</p>
                <p className="text-2xl font-bold">
                  {getWorkshopsForDay(new Date()).length}
                </p>
              </div>
              <Calendar className="h-8 w-8 text-blue-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Active Rooms</p>
                <p className="text-2xl font-bold">{rooms.length}</p>
              </div>
              <MapPin className="h-8 w-8 text-green-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Capacity Used</p>
                <p className="text-2xl font-bold">
                  {Math.round(
                    (scheduledWorkshops.reduce((sum, w) => sum + w.spots_booked, 0) /
                    scheduledWorkshops.reduce((sum, w) => sum + w.workshop.max_participants, 0)) * 100
                  ) || 0}%
                </p>
              </div>
              <Users className="h-8 w-8 text-purple-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Conflicts</p>
                <p className="text-2xl font-bold text-red-600">{conflicts.length}</p>
              </div>
              {conflicts.length > 0 ? (
                <AlertTriangle className="h-8 w-8 text-red-500" />
              ) : (
                <CheckCircle className="h-8 w-8 text-green-500" />
              )}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Main Schedule View */}
      {viewMode === 'week' && renderWeekView()}

      {/* Workshop Details Modal */}
      <AnimatePresence>
        {selectedWorkshop && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
            onClick={() => setSelectedWorkshop(null)}
          >
            <motion.div
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.9, opacity: 0 }}
              className="bg-white rounded-lg p-6 max-w-md w-full mx-4"
              onClick={e => e.stopPropagation()}
            >
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-bold">{selectedWorkshop.workshop.name}</h3>
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => setSelectedWorkshop(null)}
                >
                  ×
                </Button>
              </div>

              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <Badge variant={selectedWorkshop.workshop.category as any}>
                    {selectedWorkshop.workshop.category}
                  </Badge>
                  <Badge variant={selectedWorkshop.workshop.skill_level as any}>
                    {selectedWorkshop.workshop.skill_level}
                  </Badge>
                </div>

                <div className="grid grid-cols-2 gap-4 text-sm">
                  <div>
                    <span className="font-medium">Time:</span>
                    <p>{selectedWorkshop.start_time.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</p>
                  </div>
                  <div>
                    <span className="font-medium">Duration:</span>
                    <p>{formatDuration(selectedWorkshop.workshop.duration)}</p>
                  </div>
                  <div>
                    <span className="font-medium">Room:</span>
                    <p>{selectedWorkshop.room.name}</p>
                  </div>
                  <div>
                    <span className="font-medium">Instructor:</span>
                    <p>{selectedWorkshop.workshop.instructor_name}</p>
                  </div>
                  <div>
                    <span className="font-medium">Capacity:</span>
                    <p>{selectedWorkshop.spots_booked}/{selectedWorkshop.workshop.max_participants}</p>
                  </div>
                  <div>
                    <span className="font-medium">Status:</span>
                    <p className="capitalize">{selectedWorkshop.status}</p>
                  </div>
                </div>

                {selectedWorkshop.workshop.description && (
                  <div>
                    <span className="font-medium">Description:</span>
                    <p className="text-sm text-gray-600 mt-1">{selectedWorkshop.workshop.description}</p>
                  </div>
                )}

                <div className="flex gap-2 pt-4">
                  <Button size="sm" variant="outline">
                    <Edit className="h-4 w-4 mr-2" />
                    Edit
                  </Button>
                  <Button size="sm" variant="outline">
                    <Copy className="h-4 w-4 mr-2" />
                    Duplicate
                  </Button>
                  <Button size="sm" variant="destructive">
                    <Trash2 className="h-4 w-4 mr-2" />
                    Cancel
                  </Button>
                </div>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </motion.div>
  );
}