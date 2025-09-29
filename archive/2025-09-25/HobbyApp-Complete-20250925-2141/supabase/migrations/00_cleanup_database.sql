-- DATABASE CLEANUP SCRIPT
-- This will drop ALL existing tables to start fresh
-- Run this first to clear everything

-- Drop all policies first (they depend on tables)
DO $$ 
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN 
        SELECT schemaname, tablename, policyname 
        FROM pg_policies 
        WHERE schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', 
            pol.policyname, pol.schemaname, pol.tablename);
    END LOOP;
END $$;

-- Drop all tables in dependency order (reverse of creation)
DROP TABLE IF EXISTS promotional_campaign_usage CASCADE;
DROP TABLE IF EXISTS promotional_campaigns CASCADE;
DROP TABLE IF EXISTS squad_activity CASCADE;
DROP TABLE IF EXISTS squad_goals CASCADE;
DROP TABLE IF EXISTS squad_members CASCADE;
DROP TABLE IF EXISTS squads CASCADE;
DROP TABLE IF EXISTS retention_metrics CASCADE;
DROP TABLE IF EXISTS dynamic_pricing_rules CASCADE;
DROP TABLE IF EXISTS credit_rollover_history CASCADE;
DROP TABLE IF EXISTS user_insurance_subscriptions CASCADE;
DROP TABLE IF EXISTS credit_insurance_plans CASCADE;
DROP TABLE IF EXISTS user_subscriptions CASCADE;
DROP TABLE IF EXISTS subscription_plans CASCADE;
DROP TABLE IF EXISTS credit_transactions CASCADE;
DROP TABLE IF EXISTS credit_packs CASCADE;
DROP TABLE IF EXISTS bookings CASCADE;
DROP TABLE IF EXISTS class_schedules CASCADE;
DROP TABLE IF EXISTS class_tiers CASCADE;
DROP TABLE IF EXISTS classes CASCADE;
DROP TABLE IF EXISTS instructors CASCADE;
DROP TABLE IF EXISTS studios CASCADE;
DROP TABLE IF EXISTS user_credits CASCADE;

-- Drop any views that might exist
DROP VIEW IF EXISTS class_performance CASCADE;
DROP VIEW IF EXISTS revenue_analytics CASCADE;
DROP VIEW IF EXISTS user_engagement CASCADE;

-- Drop any functions that might exist
DROP FUNCTION IF EXISTS calculate_dynamic_price CASCADE;
DROP FUNCTION IF EXISTS apply_credit_rollover CASCADE;
DROP FUNCTION IF EXISTS process_squad_bonus CASCADE;

-- Clear migration history (optional - uncomment if you want to reset migrations)
-- TRUNCATE TABLE supabase_migrations.schema_migrations;

-- Confirmation message
DO $$ 
BEGIN
    RAISE NOTICE 'Database cleanup complete. All tables dropped.';
END $$;