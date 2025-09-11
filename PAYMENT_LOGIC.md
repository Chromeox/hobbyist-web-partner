# Payment Logic & Payout Strategy for Hobbyist Platform

This document outlines the core payment processing and payout logic for the Hobbyist platform, ensuring transparency and reliability for studios, instructors, and the platform itself.

## 1. Revenue Streams

### 1.1 Class Bookings
- **Source:** Student payments for classes booked through the Hobbyist app/web portal.
- **Payment Gateway:** Stripe (for credit card processing, Apple Pay, Google Pay).
- **Flow:** Student pays Hobbyist. Hobbyist then distributes funds to studios/instructors after deducting platform commission.

### 1.2 Subscriptions/Credit Packages (Platform-Specific)
- **Source:** Direct purchases by students for platform-wide credit packages or premium subscriptions.
- **Payment Gateway:** Stripe (for web), Apple In-App Purchase (for iOS).
- **Flow:** Student pays Hobbyist. Revenue is retained by Hobbyist.

## 2. Commission Model

The Hobbyist platform operates on a commission-based model for class bookings.

- **Platform Commission:** 15% of the class booking fee.
- **Studio/Instructor Share:** 85% of the class booking fee.

**Example:**
- Class Price: $50
- Platform Commission (15%): $7.50
- Studio/Instructor Share (85%): $42.50

## 3. Payout Schedule

Payouts to studios and instructors will be processed on a **weekly** basis.

- **Payout Day:** Every Monday.
- **Cut-off Time:** All bookings confirmed by Sunday 11:59 PM PST will be included in the upcoming Monday's payout.
- **Method:** Direct deposit via Stripe Connect to the studio/instructor's linked bank account.

## 4. Payout Process (Automated via Supabase Edge Functions & Stripe Connect)

1.  **Data Aggregation (Sunday Night):**
    *   A scheduled Supabase Edge Function (`payout_aggregator`) queries the `bookings` table for all confirmed bookings within the past week (Monday to Sunday).
    *   It calculates the total earnings for each studio/instructor, applying the 85% share.
    *   It verifies the linked Stripe Connect account ID for each recipient.
2.  **Payout Initiation (Monday Morning):**
    *   The `payout_aggregator` function initiates individual payouts to each studio/instructor via the Stripe Connect API.
    *   Each payout is linked to the corresponding bookings for auditing.
3.  **Status Tracking:**
    *   Payout status (pending, paid, failed) is updated in a `payout_history` table in Supabase.
    *   Notifications are sent to studios/instructors upon successful payout or in case of failure.

## 5. Handling Refunds, Cancellations, and Disputes

### 5.1 Refunds & Cancellations
- **Policy:** As per the class-specific cancellation policy (e.g., 24-hour notice for full refund).
- **Process:**
    1.  Student requests refund/cancellation through the app.
    2.  Hobbyist platform processes the refund via Stripe.
    3.  The corresponding booking record is updated in Supabase.
    4.  If a payout for that booking has already occurred, the refunded amount (minus platform commission) will be deducted from the studio/instructor's next payout. If no future payouts are expected, the studio/instructor will be notified to return the funds.

### 5.2 Disputes & Chargebacks
- **Process:**
    1.  Stripe notifies Hobbyist of a dispute/chargeback.
    2.  Hobbyist investigates the dispute, potentially involving the studio/instructor.
    3.  If the dispute is lost, the disputed amount (including Stripe fees) will be deducted from the studio/instructor's next payout.

## 6. Financial Reporting

-   **Studio/Instructor Dashboard:** Provides a clear overview of earnings, upcoming payouts, and historical payout records.
-   **Platform Admin Dashboard:** Comprehensive financial reports, including total revenue, platform commission, payout summaries, and detailed transaction logs.

## 7. Security & Compliance

-   All payment processing is handled by Stripe, ensuring PCI DSS compliance.
-   Sensitive financial data (bank accounts, credit card numbers) are never stored directly on Hobbyist servers.
-   Stripe Connect is used for secure onboarding and management of recipient accounts.

This document serves as a living guide and will be updated as the platform evolves.
