# HobbyistSwiftUI API Documentation

## Base Configuration

### Supabase Endpoint
```
Production: https://mcjqvdzdhtcvbrejvrtp.supabase.co
API Version: v1
Authentication: Bearer Token (JWT)
```

### Headers
```http
Authorization: Bearer {access_token}
apikey: {anon_key}
Content-Type: application/json
```

## Authentication Endpoints

### Sign Up
Create a new user account.

**Endpoint:** `POST /auth/v1/signup`

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securepassword123",
  "data": {
    "full_name": "John Doe",
    "phone_number": "+1234567890"
  }
}
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJI...",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_token": "refresh_token_here",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "created_at": "2024-08-21T10:00:00Z"
  }
}
```

### Sign In
Authenticate existing user.

**Endpoint:** `POST /auth/v1/token?grant_type=password`

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securepassword123"
}
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJI...",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_token": "refresh_token_here",
  "user": {
    "id": "uuid",
    "email": "user@example.com"
  }
}
```

### Sign Out
Invalidate user session.

**Endpoint:** `POST /auth/v1/logout`

**Headers:**
```http
Authorization: Bearer {access_token}
```

**Response:**
```json
{
  "message": "Successfully logged out"
}
```

### Refresh Token
Get new access token using refresh token.

**Endpoint:** `POST /auth/v1/token?grant_type=refresh_token`

**Request Body:**
```json
{
  "refresh_token": "refresh_token_here"
}
```

## User Endpoints

### Get User Profile
Retrieve current user's profile information.

**Endpoint:** `GET /rest/v1/user_profiles?user_id=eq.{user_id}`

**Response:**
```json
{
  "user_id": "uuid",
  "email": "user@example.com",
  "full_name": "John Doe",
  "phone_number": "+1234567890",
  "bio": "Hobby enthusiast",
  "profile_image_url": "https://...",
  "created_at": "2024-08-21T10:00:00Z"
}
```

### Update User Profile
Update user profile information.

**Endpoint:** `PATCH /rest/v1/user_profiles?user_id=eq.{user_id}`

**Request Body:**
```json
{
  "full_name": "Jane Doe",
  "bio": "Updated bio",
  "phone_number": "+0987654321"
}
```

### Get User Statistics
Retrieve user's booking and class statistics.

**Endpoint:** `GET /rest/v1/rpc/get_user_statistics`

**Request Body:**
```json
{
  "user_id": "uuid"
}
```

**Response:**
```json
{
  "total_bookings": 15,
  "total_spent": 450.00,
  "classes_attended": 12,
  "favorite_category": "Arts & Crafts",
  "upcoming_classes": 3,
  "completed_classes": 12,
  "member_since": "2024-01-15T00:00:00Z"
}
```

## Class Endpoints

### List Classes
Get paginated list of available classes.

**Endpoint:** `GET /rest/v1/classes`

**Query Parameters:**
- `limit`: Number of results (default: 20)
- `offset`: Pagination offset
- `category`: Filter by category
- `min_price`: Minimum price filter
- `max_price`: Maximum price filter
- `start_date`: Classes after this date
- `difficulty`: Filter by difficulty level

**Example:**
```
GET /rest/v1/classes?limit=10&category=eq.Arts&min_price=gte.20&max_price=lte.100
```

**Response:**
```json
[
  {
    "id": "uuid",
    "title": "Pottery for Beginners",
    "description": "Learn the basics of pottery",
    "category": "Arts & Crafts",
    "difficulty": "Beginner",
    "price": 45.00,
    "credit_cost": 1,
    "start_date": "2024-09-01T14:00:00Z",
    "end_date": "2024-09-01T16:00:00Z",
    "max_participants": 12,
    "enrolled_count": 8,
    "instructor": {
      "id": "uuid",
      "name": "Sarah Smith",
      "rating": 4.8
    },
    "venue": {
      "id": "uuid",
      "name": "Downtown Art Studio",
      "address": "123 Main St"
    },
    "image_url": "https://..."
  }
]
```

### Get Class Details
Get detailed information about a specific class.

**Endpoint:** `GET /rest/v1/classes?id=eq.{class_id}`

**Response:**
```json
{
  "id": "uuid",
  "title": "Pottery for Beginners",
  "description": "Comprehensive pottery introduction...",
  "category": "Arts & Crafts",
  "difficulty": "Beginner",
  "price": 45.00,
  "credit_cost": 1,
  "start_date": "2024-09-01T14:00:00Z",
  "end_date": "2024-09-01T16:00:00Z",
  "duration": 120,
  "max_participants": 12,
  "enrolled_count": 8,
  "requirements": ["Apron", "Closed-toe shoes"],
  "what_to_bring": ["Water bottle", "Notebook"],
  "cancellation_policy": "24 hours notice required",
  "instructor": {
    "id": "uuid",
    "name": "Sarah Smith",
    "bio": "Professional potter with 10 years experience",
    "rating": 4.8,
    "total_classes": 156,
    "certifications": ["Certified Art Instructor"]
  },
  "venue": {
    "id": "uuid",
    "name": "Downtown Art Studio",
    "address": "123 Main St",
    "city": "San Francisco",
    "state": "CA",
    "zip_code": "94102",
    "latitude": 37.7749,
    "longitude": -122.4194,
    "parking_info": "Street parking available",
    "amenities": ["WiFi", "Restrooms", "Water Fountain"]
  }
}
```

### Search Classes
Search classes by keyword.

**Endpoint:** `GET /rest/v1/rpc/search_classes`

**Request Body:**
```json
{
  "search_term": "pottery",
  "limit": 10
}
```

## Booking Endpoints

### Create Booking
Book a class for the user.

**Endpoint:** `POST /rest/v1/bookings`

**Request Body:**
```json
{
  "class_id": "uuid",
  "user_id": "uuid",
  "participant_count": 1,
  "payment_method": "credits",
  "credits_used": 1,
  "special_requests": "Vegetarian option for lunch",
  "total_amount": 45.00
}
```

**Response:**
```json
{
  "id": "uuid",
  "class_id": "uuid",
  "user_id": "uuid",
  "status": "confirmed",
  "confirmation_code": "HBY-2024-8921",
  "created_at": "2024-08-21T10:00:00Z"
}
```

### Get User Bookings
Retrieve all bookings for a user.

**Endpoint:** `GET /rest/v1/bookings?user_id=eq.{user_id}`

**Query Parameters:**
- `status`: Filter by booking status (confirmed, cancelled, completed)
- `order`: Sort order (created_at.desc)

**Response:**
```json
[
  {
    "id": "uuid",
    "class_id": "uuid",
    "class_name": "Pottery for Beginners",
    "status": "confirmed",
    "confirmation_code": "HBY-2024-8921",
    "class_start_date": "2024-09-01T14:00:00Z",
    "total_amount": 45.00,
    "payment_method": "credits",
    "created_at": "2024-08-21T10:00:00Z"
  }
]
```

### Cancel Booking
Cancel an existing booking.

**Endpoint:** `PATCH /rest/v1/bookings?id=eq.{booking_id}`

**Request Body:**
```json
{
  "status": "cancelled",
  "cancellation_reason": "Schedule conflict",
  "cancelled_at": "2024-08-21T10:00:00Z"
}
```

### Check-in to Class
Mark attendance for a booking.

**Endpoint:** `PATCH /rest/v1/bookings?id=eq.{booking_id}`

**Request Body:**
```json
{
  "status": "completed",
  "check_in_time": "2024-09-01T13:55:00Z"
}
```

## Payment Endpoints

### Get Credit Packs
Retrieve available credit pack options.

**Endpoint:** `GET /rest/v1/credit_packs?is_active=eq.true`

**Response:**
```json
[
  {
    "id": "uuid",
    "name": "Starter Pack",
    "description": "Perfect for trying out classes",
    "credit_amount": 5,
    "price_cents": 2500,
    "bonus_credits": 0,
    "display_order": 1
  },
  {
    "id": "uuid",
    "name": "Popular Pack",
    "description": "Best value for regular students",
    "credit_amount": 12,
    "price_cents": 5000,
    "bonus_credits": 3,
    "display_order": 2
  }
]
```

### Purchase Credit Pack
Buy credits for the user account.

**Endpoint:** `POST /rest/v1/credit_pack_purchases`

**Request Body:**
```json
{
  "user_id": "uuid",
  "credit_pack_id": "uuid",
  "stripe_payment_intent_id": "pi_1234567890",
  "amount_paid_cents": 5000,
  "credits_received": 12,
  "bonus_credits": 3
}
```

### Get User Credits
Check user's credit balance.

**Endpoint:** `GET /rest/v1/user_credits?user_id=eq.{user_id}`

**Response:**
```json
{
  "id": "uuid",
  "user_id": "uuid",
  "credit_balance": 15,
  "total_earned": 45,
  "total_spent": 30,
  "last_activity_at": "2024-08-20T15:30:00Z"
}
```

### Get Credit Transactions
View credit transaction history.

**Endpoint:** `GET /rest/v1/credit_transactions?user_id=eq.{user_id}&order=created_at.desc`

**Response:**
```json
[
  {
    "id": "uuid",
    "transaction_type": "purchase",
    "credit_amount": 15,
    "balance_after": 20,
    "description": "Popular Pack purchase",
    "created_at": "2024-08-20T10:00:00Z"
  },
  {
    "id": "uuid",
    "transaction_type": "spend",
    "credit_amount": -1,
    "balance_after": 19,
    "description": "Pottery class booking",
    "created_at": "2024-08-21T09:00:00Z"
  }
]
```

## Review Endpoints

### Create Review
Submit a review for a completed class.

**Endpoint:** `POST /rest/v1/reviews`

**Request Body:**
```json
{
  "booking_id": "uuid",
  "user_id": "uuid",
  "class_id": "uuid",
  "instructor_id": "uuid",
  "rating": 5,
  "title": "Amazing class!",
  "comment": "Learned so much in just 2 hours",
  "would_recommend": true
}
```

### Get Class Reviews
Retrieve reviews for a specific class.

**Endpoint:** `GET /rest/v1/reviews?class_id=eq.{class_id}`

**Response:**
```json
[
  {
    "id": "uuid",
    "user_name": "John D.",
    "rating": 5,
    "title": "Amazing class!",
    "comment": "Learned so much in just 2 hours",
    "created_at": "2024-08-15T10:00:00Z",
    "verified_booking": true
  }
]
```

## Notification Endpoints

### Get User Notifications
Retrieve notifications for a user.

**Endpoint:** `GET /rest/v1/notifications?user_id=eq.{user_id}&is_read=eq.false`

**Response:**
```json
[
  {
    "id": "uuid",
    "type": "booking_reminder",
    "title": "Class Tomorrow",
    "message": "Your Pottery class is tomorrow at 2:00 PM",
    "is_read": false,
    "created_at": "2024-08-31T10:00:00Z"
  }
]
```

### Mark Notification as Read
Update notification read status.

**Endpoint:** `PATCH /rest/v1/notifications?id=eq.{notification_id}`

**Request Body:**
```json
{
  "is_read": true,
  "read_at": "2024-08-21T10:00:00Z"
}
```

## Achievement Endpoints

### Get User Achievements
Retrieve user's unlocked achievements.

**Endpoint:** `GET /rest/v1/rpc/get_user_achievements`

**Request Body:**
```json
{
  "user_id": "uuid"
}
```

**Response:**
```json
[
  {
    "id": "uuid",
    "title": "First Steps",
    "description": "Attended your first class",
    "icon_name": "star.fill",
    "unlocked_at": "2024-08-15T10:00:00Z",
    "points": 10,
    "category": "attendance"
  },
  {
    "id": "uuid",
    "title": "Explorer",
    "description": "Tried 3 different categories",
    "icon_name": "map.fill",
    "unlocked_at": null,
    "progress": 0.67,
    "requirement": 3,
    "current": 2,
    "points": 30,
    "category": "exploration"
  }
]
```

## Instructor Endpoints

### Get Instructor Profile
Retrieve detailed instructor information.

**Endpoint:** `GET /rest/v1/instructors?id=eq.{instructor_id}`

**Response:**
```json
{
  "id": "uuid",
  "user_id": "uuid",
  "name": "Sarah Smith",
  "bio": "Professional potter with 10 years of experience",
  "specialties": ["Pottery", "Ceramics", "Sculpture"],
  "rating": 4.8,
  "total_reviews": 234,
  "total_classes": 156,
  "total_students": 1892,
  "certifications": ["Certified Art Instructor", "MFA in Ceramics"],
  "years_of_experience": 10,
  "profile_image_url": "https://..."
}
```

### Get Instructor Classes
List all classes by an instructor.

**Endpoint:** `GET /rest/v1/classes?instructor_id=eq.{instructor_id}`

## Error Responses

All endpoints may return error responses in the following format:

```json
{
  "code": "PGRST116",
  "details": "The result contains 0 rows",
  "hint": null,
  "message": "Resource not found"
}
```

### Common Error Codes
- `400`: Bad Request - Invalid parameters
- `401`: Unauthorized - Invalid or missing token
- `403`: Forbidden - Insufficient permissions
- `404`: Not Found - Resource doesn't exist
- `409`: Conflict - Duplicate resource
- `422`: Unprocessable Entity - Validation failed
- `429`: Too Many Requests - Rate limit exceeded
- `500`: Internal Server Error

## Rate Limiting

API requests are limited to:
- **Authenticated users**: 1000 requests per hour
- **Anonymous users**: 100 requests per hour

Rate limit headers:
```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1629561600
```

## Webhooks

### Booking Confirmation Webhook
Triggered when a booking is confirmed.

**Payload:**
```json
{
  "event": "booking.confirmed",
  "data": {
    "booking_id": "uuid",
    "user_id": "uuid",
    "class_id": "uuid",
    "confirmation_code": "HBY-2024-8921"
  },
  "timestamp": "2024-08-21T10:00:00Z"
}
```

### Payment Success Webhook
Triggered when a payment is processed.

**Payload:**
```json
{
  "event": "payment.success",
  "data": {
    "payment_id": "uuid",
    "user_id": "uuid",
    "amount_cents": 5000,
    "type": "credit_pack_purchase"
  },
  "timestamp": "2024-08-21T10:00:00Z"
}
```

## SDK Integration Examples

### Swift (iOS)
```swift
import Supabase

let client = SupabaseClient(
    supabaseURL: URL(string: "https://mcjqvdzdhtcvbrejvrtp.supabase.co")!,
    supabaseKey: "your-anon-key"
)

// Fetch classes
let classes = try await client
    .from("classes")
    .select()
    .eq("category", value: "Arts")
    .execute()
```

### TypeScript (Web)
```typescript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  'https://mcjqvdzdhtcvbrejvrtp.supabase.co',
  'your-anon-key'
)

// Fetch classes
const { data, error } = await supabase
  .from('classes')
  .select('*')
  .eq('category', 'Arts')
```

---

For more information about Supabase APIs, visit [Supabase Documentation](https://supabase.com/docs).