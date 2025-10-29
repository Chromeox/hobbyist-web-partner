-- WARNING: drops existing Hobbyist schema tables/views before rebuilding.
-- Run only if you're OK starting fresh (all existing studio/class/credit data will be removed).

DROP VIEW IF EXISTS booking_summary CASCADE;
DROP VIEW IF EXISTS class_availability CASCADE;

DROP TABLE IF EXISTS credit_transactions CASCADE;
DROP TABLE IF EXISTS user_insurance_subscriptions CASCADE;
DROP TABLE IF EXISTS user_subscriptions CASCADE;
DROP TABLE IF EXISTS credit_insurance_plans CASCADE;
DROP TABLE IF EXISTS subscription_plans CASCADE;
DROP TABLE IF EXISTS credit_packs CASCADE;

DROP TABLE IF EXISTS bookings CASCADE;
DROP TABLE IF EXISTS class_schedules CASCADE;
DROP TABLE IF EXISTS classes CASCADE;
DROP TABLE IF EXISTS instructors CASCADE;
DROP TABLE IF EXISTS studios CASCADE;

DROP TABLE IF EXISTS dynamic_pricing_rules CASCADE;
DROP TABLE IF EXISTS dynamic_pricing_adjustments CASCADE;

DROP TABLE IF EXISTS promotional_campaign_rules CASCADE;
DROP TABLE IF EXISTS promotional_campaigns CASCADE;

DROP TABLE IF EXISTS retention_metrics CASCADE;
DROP TABLE IF EXISTS retention_goals CASCADE;
DROP TABLE IF EXISTS retention_events CASCADE;

DROP TABLE IF EXISTS squads CASCADE;
DROP TABLE IF EXISTS squad_members CASCADE;
DROP TABLE IF EXISTS squad_events CASCADE;

DROP TABLE IF EXISTS user_credits CASCADE;
