# Studio Portal Form & Data Flow Audit

_Last updated: 2025-10-16_

The goal of this audit is to map every major portal form to its source of truth, identify mocked or missing integrations, and highlight how the iOS consumer app relies on the same datasets. This will help us remove redundant inputs and keep the mobile + web experiences in sync with Supabase.

---

## 1. Class Management

### 1.1 Class Editor (`app/dashboard/classes/ClassEditor.tsx`)
- **Current behaviour**
  - Loads instructors via `/api/instructors` and categories via `/api/categories`.
  - Persists class data through `onSave → ClassManagement.handleSaveClass → /api/classes/meta` (new API).
  - Supports tags, materials, prerequisites, recurring schedules, cancellation policy.
- **Data mapping**
  - `lib/utils/class-mappers.ts` maps form state to Supabase payload:
    - `classes` table: `name`, `description`, `difficulty_level`, `duration_minutes`, `max_participants`, `price`, `credit_cost`, `status`, `image_url`, `location`.
    - Foreign keys: `instructor_id`, `category_id`.
    - Optional arrays: `tags`, `materials`, `prerequisites`.
    - `recurring_settings` (JSONB) + `cancellation_policy`.
- **iOS consumers**
  - `SimpleSupabaseService.fetchClasses()` → `SimpleClass` → `ClassService` → `ClassItem`.
  - iOS expects accurate minutes, price, credit cost, location, instructor, tags, and cancellation policy.
- **Outstanding work**
  - `/api/categories` implementation (currently mocked fallback list).
  - Instructor endpoint should normalise fields (`id`, `name`, `email`).
  - `/api/classes/meta` needs DELETE/PUT handlers plus validation.
  - After save, refetch class list instead of assuming optimistic update.

### 1.2 Class Management Screen (`app/dashboard/classes/ClassManagement.tsx`)
- Fetches classes with `/api/classes/meta` and displays grid/list.
- Derives filters, duplication, refreshing.
- Enriched fields (`rating`, `totalBookings`, `nextSession`) come from DB; ensure Supabase query includes them or provide defaults.

---

## 2. Pricing & Credit Packs

### 2.1 Pricing Management (`app/dashboard/pricing/PricingManagement.tsx`)
- **Current state**: Purely mocked UI (`mockCreditPacks`, `mockSettings`).
- **Target mapping**
  - `credit_packs` table → pack list (id, name, description, `credit_amount`, `price_cents`, `bonus_credits`, `is_active`, `display_order`).
  - `studio_commission_settings` (or similar) → commission rate, minimum payout, frequency.
- **Actions**
  - Replace mock loader with Supabase query + mutations.
  - Add create/edit forms and connect to iOS credit purchase config.

### 2.2 Credit Purchase Flow (iOS)
- `CreditService` now loads packs from Supabase and calls the updated `purchase-credits` function.
- Supabase function supports `create_payment_sheet` + `finalize_purchase`.
- Tables touched: `credit_packs`, `credit_pack_purchases`, `credit_transactions`, `user_credits`.
- Portal needs management tooling to keep these records accurate (activate/deactivate packs, adjust pricing).

---

## 3. Studio Settings (`app/dashboard/settings/SettingsManagement.tsx`)
- **Current state**: Uses `mockSettings`; no persistence.
- **Recommended schema**
  - `studios`: legal/business info, website, contact, timezone, currency.
  - `studio_business_hours`: per-day schedules.
  - `studio_booking_policy`: cancellation window, refund policy, waitlist, payment requirements.
  - `studio_payment_settings`: payment mode, default credits per class, commission rate, payout prefs.
  - `studio_notifications`: booleans for new bookings/cancellations/etc.
  - `studio_privacy_settings`: instructor visibility, public profile toggles.
  - `studio_subscription`: current plan, limits, billing cycle.
- **iOS usage**
  - Studio description, contact info, booking policies surface in class details and confirmation flows.
- **Action items**
  - Add Supabase fetch/update endpoints for each section.
  - Handle optimistic UI + error feedback.
  - Ensure payout configuration (commission/minimums) links to upcoming payout service.

---

## 4. Class Schedule (`app/dashboard/classes/ClassSchedule.tsx`)
- Uses mock sessions; actions (manage, edit, delete) do nothing.
- Booking drawer expects `booking.student.name/email`, `paymentStatus`, etc.
- Needs Supabase-backed endpoint joining `class_schedules`, `bookings`, `user_profiles`.
- Align booking model with `BookingDetails` in `types/class-management.ts` and the iOS `BookingViewModel` expectations.

---

## 5. Data Alignment: Portal → Supabase → iOS

| Portal Field | Supabase source | iOS usage |
|--------------|-----------------|-----------|
| Class name | `classes.name` | `ClassItem.name`, search results |
| Category | `categories.name` | Filter chips, `ClassItem.category` |
| Price | `classes.price` (CAD) | `ClassItem.price` string, credit conversion |
| Credit cost | `classes.credit_cost` | Booking credit deduction |
| Duration | `classes.duration_minutes` | Formatted duration (`ClassItem.duration`) |
| Instructor | join `instructors`/profiles | Display + instructor details |
| Cancellation policy | `classes.cancellation_policy` | Booking confirmation text |
| Tags/materials/prereqs | `classes.tags/materials/prerequisites` | Future detail screens |
| Credit packs | `credit_packs` | Portal pricing + iOS purchase list |
| Commission settings | `studio_payment_settings` | Portal summary, payout engine |

Keep schema changes backward-compatible with the consumer app; update `SimpleClass` / `ClassItem` builders if column names change.

---

## Action Items Snapshot

1. Implement `/api/categories` and `/api/instructors` (Supabase queries + slug handling).
2. Finish `/api/classes/meta` (PUT/DELETE) and wire ClassEditor save/refetch.
3. Replace mock pricing data with Supabase integration and CRUD UI.
4. Design & migrate studio settings tables; expose REST/RPC endpoints; hook settings UI to real data.
5. Wire ClassSchedule to real schedule/booking tables, ensuring booking details match iOS expectations.
6. Document schema contracts alongside UI forms so future changes stay in sync.

This document should be revisited after payout integration and any major schema change to ensure the portal remains the single entry point for authoritative studio data.
