// Business Logic Validation & Error Handling
// Comprehensive validation rules and business logic enforcement

import { createSupabaseClient } from './utils.ts';
import { 
  User, 
  Class, 
  Booking, 
  Instructor, 
  UserProfile,
  BookingAttendee,
  ClassSchedule,
  RecurrenceRule,
  CancellationPolicy,
  AvailabilitySchedule
} from './types.ts';

export interface ValidationResult {
  valid: boolean;
  errors: ValidationError[];
  warnings: ValidationWarning[];
}

export interface ValidationError {
  field?: string;
  code: string;
  message: string;
  severity: 'error' | 'critical';
  context?: Record<string, any>;
}

export interface ValidationWarning {
  field?: string;
  code: string;
  message: string;
  suggestion?: string;
}

export interface BusinessRule {
  name: string;
  description: string;
  validate: (data: any, context?: any) => Promise<ValidationResult>;
  priority: number; // Higher priority rules run first
  enabled: boolean;
}

// Core validation functions
export class BusinessValidator {
  private rules: Map<string, BusinessRule[]> = new Map();
  private supabase: any;

  constructor(supabase?: any) {
    this.supabase = supabase || createSupabaseClient();
    this.initializeRules();
  }

  private initializeRules(): void {
    // User registration rules
    this.addRule('user_registration', {
      name: 'email_uniqueness',
      description: 'Email addresses must be unique across all users',
      validate: this.validateEmailUniqueness.bind(this),
      priority: 100,
      enabled: true,
    });

    this.addRule('user_registration', {
      name: 'age_verification',
      description: 'Users must be at least 16 years old',
      validate: this.validateUserAge.bind(this),
      priority: 90,
      enabled: true,
    });

    this.addRule('user_registration', {
      name: 'profile_completeness',
      description: 'User profiles must have minimum required information',
      validate: this.validateProfileCompleteness.bind(this),
      priority: 80,
      enabled: true,
    });

    // Class creation rules
    this.addRule('class_creation', {
      name: 'instructor_verification',
      description: 'Only verified instructors can create classes',
      validate: this.validateInstructorVerification.bind(this),
      priority: 100,
      enabled: true,
    });

    this.addRule('class_creation', {
      name: 'schedule_conflict',
      description: 'Classes cannot overlap with existing instructor commitments',
      validate: this.validateScheduleConflict.bind(this),
      priority: 90,
      enabled: true,
    });

    this.addRule('class_creation', {
      name: 'pricing_validation',
      description: 'Class pricing must be within acceptable ranges',
      validate: this.validateClassPricing.bind(this),
      priority: 80,
      enabled: true,
    });

    this.addRule('class_creation', {
      name: 'capacity_limits',
      description: 'Class capacity must be reasonable for the venue type',
      validate: this.validateClassCapacity.bind(this),
      priority: 70,
      enabled: true,
    });

    // Booking rules
    this.addRule('booking_creation', {
      name: 'class_availability',
      description: 'Class must have available spots for all attendees',
      validate: this.validateClassAvailability.bind(this),
      priority: 100,
      enabled: true,
    });

    this.addRule('booking_creation', {
      name: 'booking_window',
      description: 'Bookings must be made within the allowed time window',
      validate: this.validateBookingWindow.bind(this),
      priority: 90,
      enabled: true,
    });

    this.addRule('booking_creation', {
      name: 'duplicate_booking',
      description: 'Users cannot book the same class multiple times',
      validate: this.validateDuplicateBooking.bind(this),
      priority: 85,
      enabled: true,
    });

    this.addRule('booking_creation', {
      name: 'attendee_validation',
      description: 'All attendees must have valid information',
      validate: this.validateAttendees.bind(this),
      priority: 80,
      enabled: true,
    });

    this.addRule('booking_creation', {
      name: 'payment_method',
      description: 'Valid payment method must be provided',
      validate: this.validatePaymentMethod.bind(this),
      priority: 70,
      enabled: true,
    });

    // Payment rules
    this.addRule('payment_processing', {
      name: 'amount_verification',
      description: 'Payment amounts must match booking totals',
      validate: this.validatePaymentAmount.bind(this),
      priority: 100,
      enabled: true,
    });

    this.addRule('payment_processing', {
      name: 'instructor_payout',
      description: 'Instructor must have valid payout account',
      validate: this.validateInstructorPayout.bind(this),
      priority: 90,
      enabled: true,
    });

    // Cancellation rules
    this.addRule('booking_cancellation', {
      name: 'cancellation_policy',
      description: 'Cancellations must comply with class policy',
      validate: this.validateCancellationPolicy.bind(this),
      priority: 100,
      enabled: true,
    });

    this.addRule('booking_cancellation', {
      name: 'refund_calculation',
      description: 'Refund amounts must be calculated correctly',
      validate: this.validateRefundCalculation.bind(this),
      priority: 90,
      enabled: true,
    });
  }

  addRule(category: string, rule: BusinessRule): void {
    if (!this.rules.has(category)) {
      this.rules.set(category, []);
    }
    this.rules.get(category)!.push(rule);
    // Sort rules by priority (highest first)
    this.rules.get(category)!.sort((a, b) => b.priority - a.priority);
  }

  async validate(category: string, data: any, context?: any): Promise<ValidationResult> {
    const rules = this.rules.get(category) || [];
    const errors: ValidationError[] = [];
    const warnings: ValidationWarning[] = [];

    // Run rules in priority order
    for (const rule of rules.filter(r => r.enabled)) {
      try {
        const result = await rule.validate(data, context);
        errors.push(...result.errors);
        warnings.push(...result.warnings);

        // Stop on critical errors
        if (result.errors.some(e => e.severity === 'critical')) {
          break;
        }
      } catch (error) {
        console.error(`Validation rule "${rule.name}" failed:`, error);
        errors.push({
          code: 'VALIDATION_RULE_ERROR',
          message: `Validation rule "${rule.name}" encountered an error`,
          severity: 'error',
          context: { rule: rule.name, error: error.message },
        });
      }
    }

    return {
      valid: errors.length === 0,
      errors,
      warnings,
    };
  }

  // User validation rules
  private async validateEmailUniqueness(data: any): Promise<ValidationResult> {
    const { email } = data;
    if (!email) {
      return { valid: true, errors: [], warnings: [] };
    }

    const { data: existingUser } = await this.supabase
      .from('user_profiles')
      .select('id')
      .eq('email', email.toLowerCase())
      .single();

    if (existingUser) {
      return {
        valid: false,
        errors: [{
          field: 'email',
          code: 'EMAIL_ALREADY_EXISTS',
          message: 'An account with this email address already exists',
          severity: 'error' as const,
        }],
        warnings: [],
      };
    }

    return { valid: true, errors: [], warnings: [] };
  }

  private async validateUserAge(data: any): Promise<ValidationResult> {
    const { date_of_birth } = data;
    if (!date_of_birth) {
      return { valid: true, errors: [], warnings: [] };
    }

    const birthDate = new Date(date_of_birth);
    const today = new Date();
    const age = today.getFullYear() - birthDate.getFullYear();
    const monthDiff = today.getMonth() - birthDate.getMonth();
    
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birthDate.getDate())) {
      age--;
    }

    const errors: ValidationError[] = [];
    const warnings: ValidationWarning[] = [];

    if (age < 16) {
      errors.push({
        field: 'date_of_birth',
        code: 'MINIMUM_AGE_REQUIREMENT',
        message: 'Users must be at least 16 years old to create an account',
        severity: 'critical',
        context: { required_age: 16, user_age: age },
      });
    } else if (age < 18) {
      warnings.push({
        field: 'date_of_birth',
        code: 'MINOR_USER',
        message: 'Users under 18 may have limited access to certain features',
        suggestion: 'Consider requiring parental consent for minors',
      });
    }

    return { valid: errors.length === 0, errors, warnings };
  }

  private async validateProfileCompleteness(data: any): Promise<ValidationResult> {
    const errors: ValidationError[] = [];
    const warnings: ValidationWarning[] = [];

    const requiredFields = ['first_name', 'last_name', 'email'];
    const recommendedFields = ['phone', 'date_of_birth'];

    for (const field of requiredFields) {
      if (!data[field] || (typeof data[field] === 'string' && data[field].trim() === '')) {
        errors.push({
          field,
          code: 'REQUIRED_FIELD_MISSING',
          message: `${field.replace('_', ' ')} is required`,
          severity: 'error',
        });
      }
    }

    for (const field of recommendedFields) {
      if (!data[field]) {
        warnings.push({
          field,
          code: 'RECOMMENDED_FIELD_MISSING',
          message: `${field.replace('_', ' ')} is recommended for a complete profile`,
          suggestion: `Consider adding ${field.replace('_', ' ')} to improve user experience`,
        });
      }
    }

    return { valid: errors.length === 0, errors, warnings };
  }

  // Class validation rules
  private async validateInstructorVerification(data: any, context?: any): Promise<ValidationResult> {
    const { instructor_id } = context || {};
    if (!instructor_id) {
      return {
        valid: false,
        errors: [{
          code: 'INSTRUCTOR_ID_REQUIRED',
          message: 'Instructor ID is required for class creation',
          severity: 'critical',
        }],
        warnings: [],
      };
    }

    const { data: instructor } = await this.supabase
      .from('instructor_profiles')
      .select('verified, stripe_account_status, specialties')
      .eq('id', instructor_id)
      .single();

    const errors: ValidationError[] = [];
    const warnings: ValidationWarning[] = [];

    if (!instructor) {
      errors.push({
        code: 'INSTRUCTOR_NOT_FOUND',
        message: 'Instructor profile not found',
        severity: 'critical',
      });
    } else {
      if (!instructor.verified) {
        errors.push({
          code: 'INSTRUCTOR_NOT_VERIFIED',
          message: 'Instructor must be verified before creating classes',
          severity: 'error',
        });
      }

      if (instructor.stripe_account_status !== 'active') {
        errors.push({
          code: 'PAYMENT_ACCOUNT_REQUIRED',
          message: 'Instructor must have an active payment account to receive payments',
          severity: 'error',
        });
      }

      if (!instructor.specialties || instructor.specialties.length === 0) {
        warnings.push({
          code: 'MISSING_SPECIALTIES',
          message: 'Instructor should specify their specialties',
          suggestion: 'Add specialties to help students find your classes',
        });
      }
    }

    return { valid: errors.length === 0, errors, warnings };
  }

  private async validateScheduleConflict(data: any, context?: any): Promise<ValidationResult> {
    const { schedule, duration_minutes } = data;
    const { instructor_id } = context || {};

    if (!schedule || !instructor_id) {
      return { valid: true, errors: [], warnings: [] };
    }

    // Get existing classes for this instructor
    const { data: existingClasses } = await this.supabase
      .from('classes')
      .select('schedule, duration_minutes, title')
      .eq('instructor_id', instructor_id)
      .in('status', ['published', 'draft'])
      .neq('id', context?.class_id || '');

    const errors: ValidationError[] = [];
    const warnings: ValidationWarning[] = [];

    if (existingClasses) {
      for (const existingClass of existingClasses) {
        const conflict = checkScheduleConflict(schedule, existingClass.schedule, duration_minutes, existingClass.duration_minutes);
        if (conflict.hasConflict) {
          if (conflict.severity === 'critical') {
            errors.push({
              code: 'SCHEDULE_CONFLICT',
              message: `Class conflicts with existing class "${existingClass.title}" at ${conflict.conflictTime}`,
              severity: 'error',
              context: { conflicting_class: existingClass.title, conflict_time: conflict.conflictTime },
            });
          } else {
            warnings.push({
              code: 'POTENTIAL_SCHEDULE_CONFLICT',
              message: `Class may conflict with "${existingClass.title}"`,
              suggestion: 'Consider adjusting the schedule to avoid potential conflicts',
            });
          }
        }
      }
    }

    return { valid: errors.length === 0, errors, warnings };
  }

  private async validateClassPricing(data: any): Promise<ValidationResult> {
    const { price, duration_minutes, category_id } = data;
    const errors: ValidationError[] = [];
    const warnings: ValidationWarning[] = [];

    // Minimum price validation
    const minimumPrice = 500; // $5.00 in cents
    const maximumPrice = 50000; // $500.00 in cents

    if (price < minimumPrice) {
      errors.push({
        field: 'price',
        code: 'PRICE_TOO_LOW',
        message: `Class price must be at least $${(minimumPrice / 100).toFixed(2)}`,
        severity: 'error',
        context: { minimum_price: minimumPrice, provided_price: price },
      });
    }

    if (price > maximumPrice) {
      errors.push({
        field: 'price',
        code: 'PRICE_TOO_HIGH',
        message: `Class price cannot exceed $${(maximumPrice / 100).toFixed(2)}`,
        severity: 'error',
        context: { maximum_price: maximumPrice, provided_price: price },
      });
    }

    // Price per minute validation
    if (duration_minutes > 0) {
      const pricePerMinute = price / duration_minutes;
      const maxPricePerMinute = 10 * 100; // $10 per minute in cents

      if (pricePerMinute > maxPricePerMinute) {
        warnings.push({
          field: 'price',
          code: 'HIGH_PRICE_PER_MINUTE',
          message: `Price per minute (${(pricePerMinute / 100).toFixed(2)}) is unusually high`,
          suggestion: 'Consider if the pricing is appropriate for the class duration',
        });
      }
    }

    return { valid: errors.length === 0, errors, warnings };
  }

  private async validateClassCapacity(data: any): Promise<ValidationResult> {
    const { max_participants, location } = data;
    const errors: ValidationError[] = [];
    const warnings: ValidationWarning[] = [];

    if (max_participants < 1) {
      errors.push({
        field: 'max_participants',
        code: 'MINIMUM_CAPACITY',
        message: 'Classes must allow at least 1 participant',
        severity: 'error',
      });
    }

    const maxCapacityLimits = {
      'online': 50,
      'in_person': 30,
      'hybrid': 25,
    };

    const locationLimit = maxCapacityLimits[location?.type as keyof typeof maxCapacityLimits] || 30;

    if (max_participants > locationLimit) {
      warnings.push({
        field: 'max_participants',
        code: 'HIGH_CAPACITY',
        message: `Class capacity (${max_participants}) is high for ${location?.type || 'in-person'} classes`,
        suggestion: `Consider if you can effectively manage ${max_participants} participants`,
      });
    }

    return { valid: errors.length === 0, errors, warnings };
  }

  // Booking validation rules
  private async validateClassAvailability(data: any): Promise<ValidationResult> {
    const { class_id, attendees } = data;
    const attendeeCount = attendees?.length || 1;

    const { data: classData } = await this.supabase
      .from('classes')
      .select('max_participants, current_participants, status, schedule')
      .eq('id', class_id)
      .single();

    const errors: ValidationError[] = [];
    const warnings: ValidationWarning[] = [];

    if (!classData) {
      errors.push({
        code: 'CLASS_NOT_FOUND',
        message: 'Class not found',
        severity: 'critical',
      });
      return { valid: false, errors, warnings };
    }

    if (classData.status !== 'published') {
      errors.push({
        code: 'CLASS_NOT_AVAILABLE',
        message: 'Class is not available for booking',
        severity: 'error',
        context: { class_status: classData.status },
      });
    }

    const spotsAvailable = classData.max_participants - classData.current_participants;
    if (attendeeCount > spotsAvailable) {
      errors.push({
        code: 'INSUFFICIENT_CAPACITY',
        message: `Not enough spots available. Only ${spotsAvailable} spot(s) remaining`,
        severity: 'error',
        context: { 
          spots_available: spotsAvailable, 
          spots_requested: attendeeCount,
          max_participants: classData.max_participants,
          current_participants: classData.current_participants,
        },
      });
    }

    // Check if class is in the past
    if (classData.schedule?.start_date) {
      const classDate = new Date(classData.schedule.start_date);
      const now = new Date();
      
      if (classDate < now) {
        errors.push({
          code: 'CLASS_IN_PAST',
          message: 'Cannot book a class that has already occurred',
          severity: 'error',
          context: { class_date: classData.schedule.start_date },
        });
      }
    }

    return { valid: errors.length === 0, errors, warnings };
  }

  private async validateBookingWindow(data: any): Promise<ValidationResult> {
    const { class_id } = data;

    const { data: classData } = await this.supabase
      .from('classes')
      .select('schedule, booking_cutoff_hours')
      .eq('id', class_id)
      .single();

    const errors: ValidationError[] = [];
    const warnings: ValidationWarning[] = [];

    if (!classData?.schedule?.start_date) {
      return { valid: true, errors, warnings };
    }

    const classDate = new Date(classData.schedule.start_date);
    const now = new Date();
    const hoursUntilClass = (classDate.getTime() - now.getTime()) / (1000 * 60 * 60);
    
    const cutoffHours = classData.booking_cutoff_hours || 2; // Default 2 hours before class

    if (hoursUntilClass < cutoffHours) {
      errors.push({
        code: 'BOOKING_WINDOW_CLOSED',
        message: `Booking window has closed. Classes must be booked at least ${cutoffHours} hour(s) in advance`,
        severity: 'error',
        context: { 
          cutoff_hours: cutoffHours, 
          hours_until_class: hoursUntilClass,
          class_date: classData.schedule.start_date,
        },
      });
    } else if (hoursUntilClass < cutoffHours + 1) {
      warnings.push({
        code: 'BOOKING_WINDOW_CLOSING',
        message: `Booking window closes in ${Math.ceil(hoursUntilClass - cutoffHours)} hour(s)`,
        suggestion: 'Complete your booking soon to secure your spot',
      });
    }

    return { valid: errors.length === 0, errors, warnings };
  }

  private async validateDuplicateBooking(data: any, context?: any): Promise<ValidationResult> {
    const { class_id } = data;
    const { user_id } = context || {};

    if (!user_id) {
      return { valid: true, errors: [], warnings: [] };
    }

    const { data: existingBooking } = await this.supabase
      .from('bookings')
      .select('id, status')
      .eq('user_id', user_id)
      .eq('class_id', class_id)
      .in('status', ['pending', 'confirmed'])
      .single();

    if (existingBooking) {
      return {
        valid: false,
        errors: [{
          code: 'DUPLICATE_BOOKING',
          message: 'You already have a booking for this class',
          severity: 'error',
          context: { 
            existing_booking_id: existingBooking.id, 
            existing_status: existingBooking.status,
          },
        }],
        warnings: [],
      };
    }

    return { valid: true, errors: [], warnings: [] };
  }

  private async validateAttendees(data: any): Promise<ValidationResult> {
    const { attendees } = data;
    const errors: ValidationError[] = [];
    const warnings: ValidationWarning[] = [];

    if (!attendees || !Array.isArray(attendees) || attendees.length === 0) {
      errors.push({
        field: 'attendees',
        code: 'ATTENDEES_REQUIRED',
        message: 'At least one attendee is required',
        severity: 'error',
      });
      return { valid: false, errors, warnings };
    }

    if (attendees.length > 10) {
      errors.push({
        field: 'attendees',
        code: 'TOO_MANY_ATTENDEES',
        message: 'Maximum 10 attendees per booking',
        severity: 'error',
        context: { max_attendees: 10, provided_attendees: attendees.length },
      });
    }

    for (let i = 0; i < attendees.length; i++) {
      const attendee = attendees[i];
      
      if (!attendee.name || attendee.name.trim() === '') {
        errors.push({
          field: `attendees[${i}].name`,
          code: 'ATTENDEE_NAME_REQUIRED',
          message: `Attendee ${i + 1} name is required`,
          severity: 'error',
        });
      }

      if (!attendee.email || !isValidEmail(attendee.email)) {
        errors.push({
          field: `attendees[${i}].email`,
          code: 'ATTENDEE_EMAIL_INVALID',
          message: `Attendee ${i + 1} must have a valid email address`,
          severity: 'error',
        });
      }

      if (attendee.phone && !isValidPhone(attendee.phone)) {
        warnings.push({
          field: `attendees[${i}].phone`,
          code: 'ATTENDEE_PHONE_INVALID',
          message: `Attendee ${i + 1} phone number appears to be invalid`,
          suggestion: 'Verify the phone number format',
        });
      }
    }

    return { valid: errors.length === 0, errors, warnings };
  }

  private async validatePaymentMethod(data: any, context?: any): Promise<ValidationResult> {
    const { payment_method_id } = data;
    const { user_id } = context || {};

    // For now, we'll do basic validation
    // In a real implementation, you'd verify with Stripe
    const errors: ValidationError[] = [];
    const warnings: ValidationWarning[] = [];

    if (!payment_method_id) {
      warnings.push({
        code: 'PAYMENT_METHOD_MISSING',
        message: 'No payment method provided',
        suggestion: 'Payment will be required before booking confirmation',
      });
    }

    return { valid: errors.length === 0, errors, warnings };
  }

  // Payment validation rules
  private async validatePaymentAmount(data: any, context?: any): Promise<ValidationResult> {
    const { amount, booking_id } = data;
    
    if (!booking_id) {
      return { valid: true, errors: [], warnings: [] };
    }

    const { data: booking } = await this.supabase
      .from('bookings')
      .select('amount')
      .eq('id', booking_id)
      .single();

    const errors: ValidationError[] = [];

    if (!booking) {
      errors.push({
        code: 'BOOKING_NOT_FOUND',
        message: 'Associated booking not found',
        severity: 'critical',
      });
    } else if (booking.amount !== amount) {
      errors.push({
        code: 'AMOUNT_MISMATCH',
        message: 'Payment amount does not match booking total',
        severity: 'critical',
        context: { 
          expected_amount: booking.amount, 
          provided_amount: amount,
        },
      });
    }

    return { valid: errors.length === 0, errors, warnings: [] };
  }

  private async validateInstructorPayout(data: any, context?: any): Promise<ValidationResult> {
    const { instructor_id } = context || {};

    if (!instructor_id) {
      return { valid: true, errors: [], warnings: [] };
    }

    const { data: instructor } = await this.supabase
      .from('instructor_profiles')
      .select('stripe_account_id, stripe_account_status')
      .eq('id', instructor_id)
      .single();

    const errors: ValidationError[] = [];

    if (!instructor) {
      errors.push({
        code: 'INSTRUCTOR_NOT_FOUND',
        message: 'Instructor not found',
        severity: 'critical',
      });
    } else {
      if (!instructor.stripe_account_id) {
        errors.push({
          code: 'PAYOUT_ACCOUNT_MISSING',
          message: 'Instructor has not set up a payout account',
          severity: 'error',
        });
      } else if (instructor.stripe_account_status !== 'active') {
        errors.push({
          code: 'PAYOUT_ACCOUNT_INACTIVE',
          message: 'Instructor payout account is not active',
          severity: 'error',
          context: { account_status: instructor.stripe_account_status },
        });
      }
    }

    return { valid: errors.length === 0, errors, warnings: [] };
  }

  // Cancellation validation rules
  private async validateCancellationPolicy(data: any, context?: any): Promise<ValidationResult> {
    const { booking_id, cancellation_reason } = data;

    const { data: booking } = await this.supabase
      .from('bookings')
      .select(`
        *,
        class:classes!inner(
          cancellation_policy,
          schedule
        )
      `)
      .eq('id', booking_id)
      .single();

    const errors: ValidationError[] = [];
    const warnings: ValidationWarning[] = [];

    if (!booking) {
      errors.push({
        code: 'BOOKING_NOT_FOUND',
        message: 'Booking not found',
        severity: 'critical',
      });
      return { valid: false, errors, warnings };
    }

    if (booking.status === 'cancelled') {
      errors.push({
        code: 'BOOKING_ALREADY_CANCELLED',
        message: 'Booking is already cancelled',
        severity: 'error',
      });
    }

    if (booking.status === 'completed') {
      errors.push({
        code: 'BOOKING_COMPLETED',
        message: 'Cannot cancel a completed booking',
        severity: 'error',
      });
    }

    // Check cancellation timing
    const classDate = new Date(booking.class.schedule?.start_date || Date.now());
    const now = new Date();
    const hoursUntilClass = (classDate.getTime() - now.getTime()) / (1000 * 60 * 60);

    const policy = booking.class.cancellation_policy || {
      refund_percentage: 100,
      hours_before_class: 24,
    };

    if (hoursUntilClass < 0) {
      errors.push({
        code: 'CLASS_ALREADY_OCCURRED',
        message: 'Cannot cancel booking for a class that has already occurred',
        severity: 'error',
      });
    } else if (hoursUntilClass < policy.hours_before_class) {
      const refundPercentage = Math.max(0, policy.refund_percentage * (hoursUntilClass / policy.hours_before_class));
      warnings.push({
        code: 'REDUCED_REFUND',
        message: `Cancelling within ${policy.hours_before_class} hours reduces refund to ${Math.round(refundPercentage)}%`,
        suggestion: 'Consider the financial impact of cancelling at this time',
      });
    }

    return { valid: errors.length === 0, errors, warnings };
  }

  private async validateRefundCalculation(data: any, context?: any): Promise<ValidationResult> {
    const { refund_amount, booking_id } = data;

    const { data: booking } = await this.supabase
      .from('bookings')
      .select(`
        amount,
        class:classes!inner(
          cancellation_policy,
          schedule
        )
      `)
      .eq('id', booking_id)
      .single();

    const errors: ValidationError[] = [];

    if (!booking) {
      errors.push({
        code: 'BOOKING_NOT_FOUND',
        message: 'Booking not found for refund calculation',
        severity: 'critical',
      });
      return { valid: false, errors, warnings: [] };
    }

    const classDate = new Date(booking.class.schedule?.start_date || Date.now());
    const now = new Date();
    const hoursUntilClass = (classDate.getTime() - now.getTime()) / (1000 * 60 * 60);

    const policy = booking.class.cancellation_policy || {
      refund_percentage: 100,
      hours_before_class: 24,
    };

    let expectedRefundPercentage = 0;
    if (hoursUntilClass >= policy.hours_before_class) {
      expectedRefundPercentage = policy.refund_percentage;
    } else if (hoursUntilClass >= 0) {
      expectedRefundPercentage = Math.max(0, policy.refund_percentage * (hoursUntilClass / policy.hours_before_class));
    }

    const expectedRefundAmount = Math.round(booking.amount * (expectedRefundPercentage / 100));

    if (Math.abs(refund_amount - expectedRefundAmount) > 100) { // Allow $1.00 variance for rounding
      errors.push({
        code: 'REFUND_CALCULATION_ERROR',
        message: 'Refund amount does not match expected calculation',
        severity: 'error',
        context: {
          expected_refund: expectedRefundAmount,
          provided_refund: refund_amount,
          refund_percentage: expectedRefundPercentage,
          original_amount: booking.amount,
        },
      });
    }

    return { valid: errors.length === 0, errors, warnings: [] };
  }
}

// Helper functions
function checkScheduleConflict(
  schedule1: ClassSchedule,
  schedule2: ClassSchedule,
  duration1: number,
  duration2: number
): { hasConflict: boolean; severity: 'critical' | 'warning'; conflictTime?: string } {
  // Simplified conflict detection - in production, this would be more sophisticated
  const start1 = new Date(schedule1.start_date + 'T' + schedule1.start_time);
  const end1 = new Date(start1.getTime() + duration1 * 60 * 1000);
  
  const start2 = new Date(schedule2.start_date + 'T' + schedule2.start_time);
  const end2 = new Date(start2.getTime() + duration2 * 60 * 1000);

  const hasOverlap = start1 < end2 && start2 < end1;
  
  return {
    hasConflict: hasOverlap,
    severity: hasOverlap ? 'critical' : 'warning',
    conflictTime: hasOverlap ? start2.toLocaleString() : undefined,
  };
}

function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

function isValidPhone(phone: string): boolean {
  const phoneRegex = /^\+?[1-9]\d{1,14}$/; // E.164 format
  return phoneRegex.test(phone.replace(/\s/g, ''));
}