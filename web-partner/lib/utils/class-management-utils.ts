// Shared utilities for class management system

import type {
  ClassSession,
  SessionStatus,
  PaymentStatus,
  InstructorStatus,
  ClassLevel,
  RecurrenceRule
} from '../../types/class-management';

// Status color utilities
export const getStatusColor = (status: SessionStatus | InstructorStatus | string) => {
  switch (status) {
    case 'active':
    case 'scheduled':
    case 'confirmed':
      return 'bg-green-100 text-green-700 border-green-200';
    case 'completed':
      return 'bg-purple-100 text-purple-700 border-purple-200';
    case 'cancelled':
      return 'bg-red-100 text-red-700 border-red-200';
    case 'in-progress':
      return 'bg-yellow-100 text-yellow-700 border-yellow-200';
    case 'inactive':
      return 'bg-gray-100 text-gray-700 border-gray-200';
    case 'on-leave':
    case 'paused':
      return 'bg-yellow-100 text-yellow-700 border-yellow-200';
    case 'pending':
      return 'bg-blue-100 text-blue-700 border-blue-200';
    case 'draft':
      return 'bg-purple-100 text-purple-700 border-purple-200';
    default:
      return 'bg-gray-100 text-gray-700 border-gray-200';
  }
};

export const getPaymentStatusColor = (status: PaymentStatus) => {
  switch (status) {
    case 'paid':
      return 'bg-green-100 text-green-700';
    case 'pending':
      return 'bg-yellow-100 text-yellow-700';
    case 'refunded':
      return 'bg-blue-100 text-blue-700';
    case 'failed':
      return 'bg-red-100 text-red-700';
    default:
      return 'bg-gray-100 text-gray-700';
  }
};

export const getLevelColor = (level: ClassLevel) => {
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

export const getCapacityColor = (enrolled: number, capacity: number) => {
  const percentage = (enrolled / capacity) * 100;
  if (percentage >= 90) return 'text-red-600';
  if (percentage >= 75) return 'text-yellow-600';
  return 'text-green-600';
};

// Time and date utilities
export const formatTime = (time: string) => {
  try {
    return new Date(`2000-01-01T${time}:00`).toLocaleTimeString('en-US', {
      hour: 'numeric',
      minute: '2-digit',
      hour12: true
    });
  } catch {
    return time; // Return original if parsing fails
  }
};

export const formatDate = (dateString: string) => {
  try {
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    });
  } catch {
    return dateString; // Return original if parsing fails
  }
};

export const formatDateTime = (dateString: string) => {
  try {
    return new Date(dateString).toLocaleDateString('en-US', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });
  } catch {
    return dateString;
  }
};

// Day name utilities
export const getDayName = (dayKey: string) => {
  const days: Record<string, string> = {
    monday: 'Monday',
    tuesday: 'Tuesday',
    wednesday: 'Wednesday',
    thursday: 'Thursday',
    friday: 'Friday',
    saturday: 'Saturday',
    sunday: 'Sunday'
  };
  return days[dayKey.toLowerCase()] || dayKey;
};

export const getDayAbbreviation = (dayKey: string) => {
  return getDayName(dayKey).slice(0, 3);
};

// Recurrence formatting
export const formatFrequency = (rule: RecurrenceRule) => {
  const { frequency, interval, daysOfWeek } = rule;
  const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  if (frequency === 'weekly' && daysOfWeek) {
    const days = daysOfWeek.map(d => dayNames[d]).join(', ');
    return `Every ${interval > 1 ? interval + ' weeks' : 'week'} on ${days}`;
  }

  const frequencyText = frequency.slice(0, -2); // Remove 'ly' suffix
  return `Every ${interval > 1 ? interval : ''} ${frequencyText}${interval > 1 ? 's' : ''}`;
};

// Calendar utilities
export const getCalendarDays = (currentDate: Date) => {
  const days = [];
  const startOfWeek = new Date(currentDate);
  startOfWeek.setDate(currentDate.getDate() - currentDate.getDay());

  for (let i = 0; i < 7; i++) {
    const day = new Date(startOfWeek);
    day.setDate(startOfWeek.getDate() + i);
    days.push(day);
  }
  return days;
};

// Session filtering
export const getSessionsForDate = (
  sessions: ClassSession[],
  date: Date,
  filterInstructor: string = 'all',
  filterStatus: string = 'all'
) => {
  const dateStr = date.toISOString().split('T')[0];
  return sessions.filter(session => {
    const matchesDate = session.date === dateStr;
    const matchesInstructor = filterInstructor === 'all' || session.instructorId === filterInstructor;
    const matchesStatus = filterStatus === 'all' || session.status === filterStatus;
    return matchesDate && matchesInstructor && matchesStatus;
  });
};

// Revenue calculations
export const calculateSessionRevenue = (session: ClassSession): number => {
  return session.bookings?.reduce((sum, booking) => {
    return booking.paymentStatus === 'paid' ? sum + booking.amount : sum;
  }, 0) || session.revenue || 0;
};

export const calculateTotalRevenue = (sessions: ClassSession[]): number => {
  return sessions.reduce((sum, session) => sum + calculateSessionRevenue(session), 0);
};

// Validation utilities
export const isValidEmail = (email: string): boolean => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

export const isValidPhone = (phone: string): boolean => {
  const phoneRegex = /^\+?[\d\s\-\(\)]{10,}$/;
  return phoneRegex.test(phone);
};

// Search and filter utilities
const getValueByPath = (item: Record<string, unknown>, path: string) => {
  return path.split('.').reduce<unknown>((value, key) => {
    if (value === undefined || value === null) {
      return undefined;
    }
    if (typeof value !== 'object') {
      return undefined;
    }
    return (value as Record<string, unknown>)[key];
  }, item);
};

export const searchFilter = <T extends Record<string, any>>(
  items: T[],
  searchTerm: string,
  searchFields: string[]
): T[] => {
  if (!searchTerm.trim()) return items;

  const term = searchTerm.toLowerCase();
  return items.filter(item =>
    searchFields.some(field => {
      const value = field.includes('.')
        ? getValueByPath(item, field)
        : item[field as keyof T];
      return typeof value === 'string' && value.toLowerCase().includes(term);
    })
  );
};

// Animation variants for framer-motion
export const modalVariants = {
  hidden: { opacity: 0, scale: 0.95 },
  visible: { opacity: 1, scale: 1 },
  exit: { opacity: 0, scale: 0.95 }
};

export const listItemVariants = {
  hidden: { opacity: 0, x: -20 },
  visible: (index: number) => ({
    opacity: 1,
    x: 0,
    transition: { delay: index * 0.1 }
  })
};

// Error handling utilities
export const safeJsonParse = <T>(jsonString: string, fallback: T): T => {
  try {
    return JSON.parse(jsonString);
  } catch {
    return fallback;
  }
};

export const handleAsyncError = (error: unknown, context: string) => {
  console.error(`Error in ${context}:`, error);
  // Could integrate with error reporting service here
};

// Performance optimization utilities
export const debounce = <T extends (...args: any[]) => any>(
  func: T,
  wait: number
): ((...args: Parameters<T>) => void) => {
  let timeout: NodeJS.Timeout;
  return (...args: Parameters<T>) => {
    clearTimeout(timeout);
    timeout = setTimeout(() => func(...args), wait);
  };
};

export const throttle = <T extends (...args: any[]) => any>(
  func: T,
  limit: number
): ((...args: Parameters<T>) => void) => {
  let inThrottle: boolean;
  return (...args: Parameters<T>) => {
    if (!inThrottle) {
      func(...args);
      inThrottle = true;
      setTimeout(() => inThrottle = false, limit);
    }
  };
};
