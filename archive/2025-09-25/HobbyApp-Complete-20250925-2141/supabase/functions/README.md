# HobbyistSwiftUI API Documentation

## Overview

This document provides comprehensive documentation for the HobbyistSwiftUI Supabase Edge Functions API. The API is designed to support a full-featured hobby class booking platform with real-time capabilities, payment processing, and comprehensive business logic.

## Base URL

- **Development:** `https://your-project.supabase.co/functions/v1`
- **Production:** `https://hobbyist-api.supabase.co/functions/v1`

## Authentication

All authenticated endpoints require a Bearer token in the Authorization header:

```
Authorization: Bearer <supabase_jwt_token>
```

## Response Format

All API responses follow a consistent format:

```json
{
  "success": true,
  "data": { ... },
  "error": null,
  "meta": {
    "request_id": "uuid",
    "timestamp": "2024-01-01T00:00:00Z"
  }
}
```

### Error Response Format

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable error message",
    "details": { ... },
    "timestamp": "2024-01-01T00:00:00Z"
  }
}
```

## API Endpoints

### Authentication & Authorization (`/auth`)

#### POST /auth/register
Register a new user account.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securepassword",
  "first_name": "John",
  "last_name": "Doe",
  "phone": "+1234567890"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user_id": "uuid",
    "email": "user@example.com",
    "email_confirmed": false,
    "message": "Registration successful. Please check your email for verification."
  }
}
```

#### POST /auth/complete-profile
Complete user profile after registration.

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "date_of_birth": "1990-01-01",
  "bio": "I love learning new skills!",
  "emergency_contact": {
    "name": "Jane Doe",
    "phone": "+1234567890",
    "relationship": "Sister"
  },
  "preferences": {
    "notifications": {
      "email": true,
      "push": true,
      "sms": false,
      "class_reminders": true,
      "promotional": false,
      "instructor_updates": true
    },
    "privacy": {
      "profile_visible": true,
      "show_attendance": false,
      "allow_invites": true
    },
    "accessibility": {
      "high_contrast": false,
      "large_text": false,
      "reduce_motion": false,
      "haptic_feedback": true
    }
  }
}
```

#### GET /auth/profile
Get current user profile.

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "email": "user@example.com",
    "role": "student",
    "profile": {
      "first_name": "John",
      "last_name": "Doe",
      "phone": "+1234567890",
      "avatar_url": "https://...",
      "bio": "...",
      "preferences": { ... }
    }
  }
}
```

#### POST /auth/become-instructor
Convert user account to instructor.

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "business_name": "John's Fitness Classes",
  "specialties": ["yoga", "pilates", "meditation"],
  "certifications": [
    {
      "name": "Certified Yoga Instructor",
      "issuer": "Yoga Alliance",
      "date": "2023-01-01",
      "verification_url": "https://..."
    }
  ]
}
```

### Classes (`/classes`)

#### GET /classes/search
Search and filter classes.

**Query Parameters:**
- `q` (string): Search query
- `category` (string): Category ID
- `location` (string): Location filter
- `price_min` (number): Minimum price
- `price_max` (number): Maximum price
- `difficulty` (string): Difficulty level
- `date` (string): Date filter (YYYY-MM-DD)
- `sort_by` (string): Sort by (popularity, price_low, price_high, date, rating)
- `lat` (number): Latitude for location-based search
- `lng` (number): Longitude for location-based search
- `radius` (number): Search radius in miles
- `page` (number): Page number (default: 1)
- `limit` (number): Results per page (default: 20)

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "title": "Beginner Yoga Class",
      "description": "Perfect for beginners...",
      "price": 2500,
      "price_formatted": "25.00",
      "duration_minutes": 60,
      "max_participants": 15,
      "current_participants": 8,
      "spots_remaining": 7,
      "difficulty_level": "beginner",
      "tags": ["yoga", "relaxation"],
      "images": [
        {
          "url": "https://...",
          "alt_text": "Yoga class",
          "is_primary": true
        }
      ],
      "location": {
        "type": "in_person",
        "address": {
          "street": "123 Main St",
          "city": "San Francisco",
          "state": "CA",
          "zip": "94102"
        }
      },
      "schedule": {
        "type": "single",
        "start_date": "2024-01-15",
        "start_time": "10:00",
        "end_time": "11:00"
      },
      "instructor": {
        "id": "uuid",
        "business_name": "Sarah's Yoga",
        "rating": 4.8,
        "total_reviews": 150,
        "user": {
          "first_name": "Sarah",
          "last_name": "Smith",
          "avatar_url": "https://..."
        }
      },
      "category": {
        "id": "uuid",
        "name": "Yoga",
        "slug": "yoga"
      },
      "average_rating": 4.8,
      "total_reviews": 45,
      "distance": 2.3
    }
  ]
}
```

#### GET /classes/{id}
Get detailed class information.

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "title": "Beginner Yoga Class",
    "description": "A comprehensive description...",
    "price": 2500,
    "price_formatted": "25.00",
    "duration_minutes": 60,
    "max_participants": 15,
    "current_participants": 8,
    "spots_remaining": 7,
    "difficulty_level": "beginner",
    "requirements": ["Yoga mat", "Water bottle"],
    "what_to_bring": ["Comfortable clothing"],
    "tags": ["yoga", "relaxation"],
    "images": [...],
    "location": {...},
    "schedule": {...},
    "instructor": {
      "id": "uuid",
      "business_name": "Sarah's Yoga",
      "rating": 4.8,
      "total_reviews": 150,
      "verified": true,
      "specialties": ["yoga", "meditation"],
      "user": {
        "first_name": "Sarah",
        "last_name": "Smith",
        "avatar_url": "https://...",
        "bio": "Certified yoga instructor with 10 years experience"
      }
    },
    "cancellation_policy": {
      "refund_percentage": 100,
      "hours_before_class": 24,
      "terms": "Full refund if cancelled 24 hours before class"
    },
    "reviews": [
      {
        "id": "uuid",
        "rating": 5,
        "title": "Amazing class!",
        "comment": "Sarah is an excellent instructor...",
        "user": {
          "first_name": "Emily",
          "last_name": "Johnson",
          "avatar_url": "https://..."
        },
        "created_at": "2024-01-01T00:00:00Z"
      }
    ],
    "average_rating": 4.8,
    "total_reviews": 45,
    "is_full": false
  }
}
```

#### POST /classes/create
Create a new class (instructors only).

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "title": "Advanced Yoga Flow",
  "description": "A challenging flow class for experienced practitioners",
  "price": 35.00,
  "duration_minutes": 75,
  "max_participants": 12,
  "difficulty_level": "advanced",
  "category_id": "uuid",
  "requirements": ["Previous yoga experience", "Own yoga mat"],
  "what_to_bring": ["Yoga mat", "Water bottle", "Towel"],
  "tags": ["yoga", "advanced", "flow"],
  "images": [
    {
      "url": "https://...",
      "alt_text": "Advanced yoga pose",
      "is_primary": true,
      "order": 1
    }
  ],
  "location": {
    "type": "in_person",
    "address": {
      "street": "456 Wellness Ave",
      "city": "San Francisco",
      "state": "CA",
      "zip": "94103",
      "lat": 37.7749,
      "lng": -122.4194
    },
    "instructions": "Enter through the main entrance"
  },
  "schedule": {
    "type": "recurring",
    "start_date": "2024-01-15",
    "start_time": "18:00",
    "end_time": "19:15",
    "recurrence": {
      "frequency": "weekly",
      "interval": 1,
      "days_of_week": [1, 3, 5],
      "end_after_occurrences": 12
    }
  },
  "cancellation_policy": {
    "refund_percentage": 80,
    "hours_before_class": 12,
    "terms": "80% refund if cancelled 12+ hours before class"
  }
}
```

### Bookings (`/bookings`)

#### POST /bookings/create
Create a new booking.

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "class_id": "uuid",
  "session_id": "uuid",
  "attendees": [
    {
      "name": "John Doe",
      "email": "john@example.com",
      "phone": "+1234567890",
      "emergency_contact": {
        "name": "Jane Doe",
        "phone": "+1234567890",
        "relationship": "Sister"
      },
      "dietary_restrictions": "Vegetarian",
      "medical_conditions": "None"
    }
  ],
  "notes": "First time student, please provide extra guidance"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "booking": {
      "id": "uuid",
      "class_id": "uuid",
      "status": "pending",
      "payment_status": "pending",
      "amount": 2500,
      "amount_formatted": "25.00",
      "attendees_count": 1,
      "created_at": "2024-01-01T00:00:00Z",
      "class": {
        "title": "Beginner Yoga Class",
        "instructor": {
          "business_name": "Sarah's Yoga"
        }
      }
    },
    "payment": {
      "id": "uuid",
      "status": "pending"
    },
    "next_steps": {
      "action": "complete_payment",
      "message": "Please complete your payment to confirm the booking",
      "payment_url": "/payment/uuid"
    }
  }
}
```

#### GET /bookings/my-bookings
Get user's bookings.

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
- `status` (string): Filter by status (all, pending, confirmed, cancelled, completed)
- `page` (number): Page number
- `limit` (number): Results per page

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "class_id": "uuid",
      "status": "confirmed",
      "payment_status": "succeeded",
      "amount": 2500,
      "amount_formatted": "25.00",
      "attendees_count": 1,
      "booking_date": "2024-01-15",
      "can_cancel": true,
      "can_review": false,
      "created_at": "2024-01-01T00:00:00Z",
      "class": {
        "id": "uuid",
        "title": "Beginner Yoga Class",
        "schedule": {
          "start_date": "2024-01-15",
          "start_time": "10:00"
        },
        "location": {
          "type": "in_person",
          "address": {
            "street": "123 Main St",
            "city": "San Francisco"
          }
        },
        "instructor": {
          "business_name": "Sarah's Yoga",
          "user": {
            "first_name": "Sarah",
            "last_name": "Smith"
          }
        }
      }
    }
  ]
}
```

#### POST /bookings/cancel
Cancel a booking.

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "booking_id": "uuid",
  "reason": "Schedule conflict"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "booking_id": "uuid",
    "status": "cancelled",
    "class_title": "Beginner Yoga Class",
    "attendees_count": 1,
    "original_amount": "25.00",
    "refund": {
      "amount": "25.00",
      "percentage": 100,
      "estimated_processing_time": "3-5 business days"
    },
    "message": "Booking cancelled successfully. Refund of $25.00 is being processed."
  }
}
```

### Payments (`/payments`)

#### POST /payments/create-intent
Create a payment intent for a booking.

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "booking_id": "uuid",
  "payment_method_id": "pm_xxx",
  "save_payment_method": false
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "client_secret": "pi_xxx_secret_xxx",
    "payment_intent_id": "pi_xxx",
    "status": "requires_payment_method",
    "amount": "25.00",
    "currency": "usd",
    "requires_action": false,
    "requires_payment_method": true,
    "booking": {
      "id": "uuid",
      "class_title": "Beginner Yoga Class",
      "attendees_count": 1,
      "instructor_name": "Sarah Smith"
    }
  }
}
```

#### POST /payments/confirm-payment
Confirm a successful payment.

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "payment_intent_id": "pi_xxx"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "booking_id": "uuid",
    "payment_status": "succeeded",
    "payment_intent_id": "pi_xxx",
    "amount_paid": "25.00",
    "class_title": "Beginner Yoga Class",
    "confirmation_number": "HB12345678",
    "message": "Payment successful! Your booking is confirmed."
  }
}
```

### Real-time (`/realtime`)

#### POST /realtime/subscribe
Subscribe to real-time updates.

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "channel": "bookings",
  "connection_id": "conn_xxx",
  "filters": {
    "user_id": "uuid"
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "channel": "bookings",
    "connection_id": "conn_xxx",
    "status": "subscribed",
    "active_connections": 42,
    "subscription_config": {
      "table": "bookings",
      "filter": "user_id=eq.uuid",
      "event": "*"
    }
  }
}
```

#### GET /realtime/notifications
Get user notifications.

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
- `limit` (number): Number of notifications (default: 50)
- `unread_only` (boolean): Only unread notifications

**Response:**
```json
{
  "success": true,
  "data": {
    "notifications": [
      {
        "id": "uuid",
        "type": "booking_confirmation",
        "title": "Booking Confirmed!",
        "message": "Your booking for \"Beginner Yoga Class\" has been confirmed.",
        "data": {
          "booking_id": "uuid",
          "class_id": "uuid"
        },
        "read": false,
        "created_at": "2024-01-01T00:00:00Z"
      }
    ],
    "unread_count": 3,
    "total_count": 10
  }
}
```

### Storage (`/storage`)

#### POST /storage/upload
Upload a file.

**Headers:** `Authorization: Bearer <token>`, `Content-Type: multipart/form-data`

**Form Data:**
- `file`: File to upload
- `type`: File type (image, document, video, general)
- `public`: Whether file should be public (true/false)
- `description`: File description
- `tags`: Comma-separated tags

**Response:**
```json
{
  "success": true,
  "data": {
    "file_id": "uuid",
    "file_name": "generated_filename.jpg",
    "original_name": "my_image.jpg",
    "file_size": 1024000,
    "file_size_formatted": "1.02 MB",
    "mime_type": "image/jpeg",
    "public_url": "https://...",
    "upload_path": "uuid/image/generated_filename.jpg",
    "is_public": true,
    "created_at": "2024-01-01T00:00:00Z",
    "message": "File uploaded successfully"
  }
}
```

### Webhooks (`/webhooks`)

#### POST /webhooks/stripe
Handle Stripe webhook events.

**Headers:** `stripe-signature: <signature>`

**Supported Events:**
- `payment_intent.succeeded`
- `payment_intent.payment_failed`
- `charge.dispute.created`
- `account.updated`
- `payout.created`
- `payout.paid`
- `payout.failed`

#### POST /webhooks/sendgrid
Handle SendGrid webhook events for email delivery status.

### Notifications (`/notifications`)

#### POST /notifications/send-email
Send an email notification.

**Request Body:**
```json
{
  "to": "user@example.com",
  "subject": "Class Reminder",
  "content": "<h2>Your class is tomorrow!</h2>",
  "template_id": "booking-reminder",
  "template_data": {
    "customer_name": "John Doe",
    "class_title": "Beginner Yoga Class"
  }
}
```

## Error Codes

### Authentication Errors (401)
- `UNAUTHORIZED`: Missing or invalid authentication token
- `TOKEN_EXPIRED`: Authentication token has expired
- `EMAIL_NOT_VERIFIED`: Email verification required

### Authorization Errors (403)
- `FORBIDDEN`: Insufficient permissions
- `INSTRUCTOR_REQUIRED`: Instructor role required
- `ACCOUNT_SUSPENDED`: Account has been suspended

### Validation Errors (400)
- `VALIDATION_ERROR`: Request validation failed
- `REQUIRED_FIELD_MISSING`: Required field is missing
- `INVALID_FORMAT`: Invalid data format
- `EMAIL_ALREADY_EXISTS`: Email address already in use

### Business Logic Errors (422)
- `INSUFFICIENT_CAPACITY`: Not enough spots available
- `BOOKING_WINDOW_CLOSED`: Booking deadline has passed
- `SCHEDULE_CONFLICT`: Class schedule conflicts with existing booking
- `PAYMENT_REQUIRED`: Payment is required to proceed

### Not Found Errors (404)
- `USER_NOT_FOUND`: User account not found
- `CLASS_NOT_FOUND`: Class not found
- `BOOKING_NOT_FOUND`: Booking not found
- `INSTRUCTOR_NOT_FOUND`: Instructor profile not found

### Rate Limiting (429)
- `RATE_LIMIT_EXCEEDED`: Too many requests

### Server Errors (500+)
- `INTERNAL_ERROR`: Internal server error
- `DATABASE_ERROR`: Database operation failed
- `PAYMENT_ERROR`: Payment processing error
- `EXTERNAL_SERVICE_ERROR`: Third-party service error

## Rate Limiting

API endpoints are rate-limited to prevent abuse:

- **Authentication endpoints:** 10 requests per minute per IP
- **General endpoints:** 100 requests per minute per user
- **File upload endpoints:** 20 requests per minute per user
- **Webhook endpoints:** No rate limiting (handled by webhook signatures)

## Pagination

List endpoints support pagination with the following parameters:

- `page`: Page number (1-based, default: 1)
- `limit`: Items per page (default: 20, max: 100)

Response includes pagination metadata:

```json
{
  "data": [...],
  "meta": {
    "page": 1,
    "per_page": 20,
    "total": 150,
    "total_pages": 8,
    "has_more": true
  }
}
```

## Webhooks

### Webhook Security

All webhooks include signature verification:

- **Stripe:** Verify using `stripe-signature` header
- **SendGrid:** Verify using SendGrid's webhook signature

### Webhook Retries

Failed webhook deliveries are retried with exponential backoff:

- Retry attempts: 3
- Initial delay: 1 second
- Maximum delay: 30 seconds

## SDK and Client Libraries

### JavaScript/TypeScript

```typescript
import { SupabaseClient } from '@supabase/supabase-js'

const supabase = new SupabaseClient(
  'https://your-project.supabase.co',
  'your-anon-key'
)

// Invoke Edge Function
const { data, error } = await supabase.functions.invoke('classes', {
  body: { action: 'search', query: 'yoga' }
})
```

### Swift (for iOS app)

```swift
import Supabase

let supabase = SupabaseClient(
  supabaseURL: URL(string: "https://your-project.supabase.co")!,
  supabaseKey: "your-anon-key"
)

// Invoke Edge Function
let response: ClassSearchResponse = try await supabase.functions
  .invoke("classes", body: ["action": "search", "query": "yoga"])
```

## Testing

### Test Environment

- **Base URL:** `https://your-project-test.supabase.co/functions/v1`
- **Test Stripe Keys:** Use Stripe test mode keys
- **Test Data:** Database includes sample test data

### Example Test Requests

```bash
# Search classes
curl -X GET "https://your-project.supabase.co/functions/v1/classes/search?q=yoga&limit=5" \
  -H "Authorization: Bearer <token>"

# Create booking
curl -X POST "https://your-project.supabase.co/functions/v1/bookings/create" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "class_id": "uuid",
    "attendees": [{"name": "Test User", "email": "test@example.com"}]
  }'
```

## Support

For API support and questions:

- **Documentation:** This README and inline code comments
- **Issues:** Create issues in the project repository
- **Contact:** api-support@hobbyist.app

---

*Last updated: January 2024*
*API Version: 1.0.0*