# Supabase Migration Runbook (October 2025 Refresh)

These scripts rebuild the full Hobbyist platform schema (studios, classes, credits, payouts) and then layer on the August/September 2025 security & performance fixes. Run them **in order** against project `mcjqvdzdhtcvbrejvrtp`.

> **Heads up:** The scripts assume the target database does not already contain incompatible legacy tables. Back up or drop conflicting objects first.

## 0. (Optional) Reset Legacy Tables
- File: `supabase/migrations/20241005000000_reset_base_schema.sql`
- Drops the existing Hobbyist tables/views so you can start fresh. **Only run if losing current data is acceptable.**

## 1. Base Schema & Pricing System
- File: `supabase/migrations/20241005000001_complete_vancouver_pricing_system.sql`
- Creates `studios`, `instructors`, `classes`, `class_schedules`, credit pack + subscription tables, bookings, squads, and seed data.

## 2. Studio Revenue & Payout Infrastructure
- File: `supabase/migrations/20241005000002_revenue_sharing.sql`
- Adds payout tracking tables (`payout_requests`, `payout_batches`) plus supporting analytics views.

## 3. Comprehensive Security Fixes
- File: `supabase/migrations/20241005000003_comprehensive_security_fixes.sql`
- Enables RLS across the new tables, rebuilds non-secure views/functions, and enforces safe `search_path`.

## 4. Performance Optimizations
- File: `supabase/migrations/20241005000004_performance_optimizations.sql`
- Consolidates duplicate policies, introduces the `auth.uid()` initplan pattern, and adds high-value indexes.

## 5. Verification Script
- File: `supabase/migrations/20241005000005_verify_security_performance.sql`
- Confirms the security/performance migrations executed successfully.

## 6–7. RLS Follow-ups
- Files:
  - `supabase/migrations/20241005000006_rls_performance_optimization.sql`
  - `supabase/migrations/20241005000007_rls_performance_optimization_corrected.sql`
- Fine-tunes remaining instructor/payout policies.

## 8. Studio Onboarding Submissions
- File: `supabase/migrations/20241005000008_create_studio_onboarding_submissions.sql`
- Adds the staging table used by the partner portal to capture raw onboarding payloads.

## 9. Studio Profile Extensions
- File: `supabase/migrations/20241005000009_extend_studio_profile.sql`
- Adds JSONB `profile`/`social_links` fields and an `amenities` array on `studios`.

## 10–11. Existing Avatar/Profile Migrations
- Continue running the repo’s existing migrations:
  - `supabase/migrations/20250105000000_create_avatars_storage.sql`
  - `supabase/migrations/20251005142646_auto_create_user_profiles.sql`

### Manual Execution Checklist
1. Open the Supabase SQL editor for project `mcjqvdzdhtcvbrejvrtp`.
2. Paste and execute each file above (in order).
3. Re-run the verification script (#5) when finished and confirm there are no errors.

### After Schema Deployment
- Regenerate TypeScript types:  
  `supabase gen types typescript --project-ref mcjqvdzdhtcvbrejvrtp --schema public > web-partner/types/supabase.ts`
- Update local env files with the active Supabase keys.
- Seed a test studio through the onboarding wizard to confirm data flows into `studios`, `instructors`, and `studio_onboarding_submissions`.
