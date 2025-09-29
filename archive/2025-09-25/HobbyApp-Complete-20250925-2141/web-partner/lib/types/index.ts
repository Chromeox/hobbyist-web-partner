// Core User Types
export interface User {
  id: string;
  email: string;
  created_at: string;
  updated_at: string;
}

export interface Student extends User {
  firstName: string;
  lastName: string;
  phone?: string;
  dateOfBirth?: string;
  preferences?: StudentPreferences;
  creditBalance?: number;
  subscriptionTier?: SubscriptionTier;
}

export interface StudentPreferences {
  favoriteCategories: string[];
  skillLevel: 'beginner' | 'intermediate' | 'advanced';
  notificationSettings: NotificationSettings;
}

// Instructor Types
export interface Instructor {
  id: string;
  userId: string;
  displayName: string;
  slug: string;
  bio?: string;
  tagline?: string;
  profileImageUrl?: string;
  coverImageUrl?: string;
  specialties: string[];
  certifications: Certification[];
  yearsExperience: number;
  languages: string[];
  isVerified: boolean;
  isFeatured: boolean;
  averageRating: number;
  totalReviews: number;
  totalStudents: number;
  totalClassesTaught: number;
  hourlyRate: number;
  travelRadius: number;
  availability: WeeklyAvailability;
  social?: SocialLinks;
}

export interface Certification {
  name: string;
  issuer: string;
  year: string;
  verificationUrl?: string;
}

export interface WeeklyAvailability {
  monday: DayAvailability;
  tuesday: DayAvailability;
  wednesday: DayAvailability;
  thursday: DayAvailability;
  friday: DayAvailability;
  saturday: DayAvailability;
  sunday: DayAvailability;
}

export interface DayAvailability {
  available: boolean;
  slots?: TimeSlot[];
}

export interface TimeSlot {
  start: string;
  end: string;
}

export interface SocialLinks {
  website?: string;
  instagram?: string;
  youtube?: string;
  facebook?: string;
}

// Studio & Location Types
export interface Studio {
  id: string;
  name: string;
  slug: string;
  ownerId: string;
  description?: string;
  logoUrl?: string;
  coverImageUrl?: string;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface StudioLocation {
  id: string;
  studioId: string;
  name: string;
  slug: string;
  address: string;
  city: string;
  state?: string;
  postalCode: string;
  country: string;
  latitude?: number;
  longitude?: number;
  phone?: string;
  email?: string;
  timezone: string;
  currency: string;
  isPrimary: boolean;
  isActive: boolean;
  operatingHours: OperatingHours;
  amenities: string[];
  capacity: number;
  managerId?: string;
}

export interface OperatingHours {
  [day: string]: {
    open: string;
    close: string;
    closed?: boolean;
  };
}

// Class & Booking Types
export interface Class {
  id: string;
  studioId: string;
  locationId?: string;
  instructorId: string;
  categoryId: string;
  name: string;
  description: string;
  duration: number; // in minutes
  capacity: number;
  price: number;
  creditCost?: number;
  imageUrl?: string;
  skillLevel: 'all' | 'beginner' | 'intermediate' | 'advanced';
  requirements?: string[];
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface ClassSession {
  id: string;
  classId: string;
  startTime: string;
  endTime: string;
  spotsAvailable: number;
  spotsTotal: number;
  status: 'scheduled' | 'in-progress' | 'completed' | 'cancelled';
  waitlistCount: number;
}

export interface Booking {
  id: string;
  userId: string;
  classSessionId: string;
  status: 'confirmed' | 'cancelled' | 'completed' | 'no-show';
  paymentMethod: 'credit' | 'cash' | 'subscription';
  amountPaid?: number;
  creditsUsed?: number;
  bookedAt: string;
  cancelledAt?: string;
  completedAt?: string;
}

// Payment Types
export interface PaymentMethod {
  id: string;
  userId: string;
  type: 'card' | 'bank' | 'paypal';
  last4?: string;
  brand?: string;
  isDefault: boolean;
  createdAt: string;
}

export interface Transaction {
  id: string;
  userId: string;
  type: 'purchase' | 'refund' | 'payout';
  amount: number;
  currency: string;
  status: 'pending' | 'completed' | 'failed';
  description?: string;
  metadata?: Record<string, any>;
  createdAt: string;
}

// Subscription Types
export interface SubscriptionTier {
  id: string;
  name: string;
  slug: string;
  description: string;
  price: number;
  interval: 'monthly' | 'quarterly' | 'yearly';
  features: string[];
  limitations: SubscriptionLimitations;
  isActive: boolean;
}

export interface SubscriptionLimitations {
  classesPerMonth?: number | 'unlimited';
  bookingWindow?: number; // days in advance
  guestPasses?: number;
  priorityBooking?: boolean;
  exclusiveClasses?: boolean;
}

export interface Subscription {
  id: string;
  userId: string;
  tierId: string;
  status: 'active' | 'paused' | 'cancelled' | 'expired';
  startDate: string;
  endDate?: string;
  nextBillingDate?: string;
  cancelledAt?: string;
}

// Review Types
export interface Review {
  id: string;
  instructorId?: string;
  classId?: string;
  studentId: string;
  bookingId?: string;
  rating: number; // 1-5
  title?: string;
  comment?: string;
  photos?: string[];
  isVerifiedBooking: boolean;
  helpfulCount: number;
  instructorResponse?: string;
  responseDate?: string;
  createdAt: string;
  updatedAt: string;
}

// Revenue & Payout Types
export interface RevenueShare {
  id: string;
  instructorId: string;
  studioId: string;
  commissionRate: number; // percentage
  baseRate?: number;
  effectiveDate: string;
  endDate?: string;
}

export interface Payout {
  id: string;
  instructorId: string;
  amount: number;
  currency: string;
  period: string; // e.g., "2024-01"
  status: 'pending' | 'processing' | 'completed' | 'failed';
  paymentMethod: string;
  transactionId?: string;
  createdAt: string;
  paidAt?: string;
}

// Notification Types
export interface NotificationSettings {
  email: boolean;
  sms: boolean;
  push: boolean;
  classReminders: boolean;
  marketingEmails: boolean;
  instructorUpdates: boolean;
}

export interface Notification {
  id: string;
  userId: string;
  type: 'booking' | 'reminder' | 'cancellation' | 'waitlist' | 'review' | 'payout';
  title: string;
  message: string;
  actionUrl?: string;
  isRead: boolean;
  createdAt: string;
}

// Category Types
export interface Category {
  id: string;
  name: string;
  slug: string;
  description?: string;
  icon?: string;
  color?: string;
  displayOrder: number;
  isActive: boolean;
}