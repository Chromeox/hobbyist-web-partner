'use server';

import { NextResponse } from 'next/server';

import { createServiceSupabase } from '@/lib/supabase';
import { logMonitoringEvent } from '@/lib/monitoring/logflare';

type CheckStatus = 'pass' | 'fail';

interface HealthCheck {
  component: string;
  status: CheckStatus;
  message?: string;
}

export async function GET() {
  const timestamp = new Date().toISOString();
  const checks: HealthCheck[] = [];
  let overall: CheckStatus = 'pass';

  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!supabaseUrl || !supabaseServiceRoleKey) {
    overall = 'fail';
    checks.push({
      component: 'supabase',
      status: 'fail',
      message: 'Missing Supabase environment variables'
    });
  } else {
    try {
      const supabase = createServiceSupabase();
      const { error } = await (supabase as any).from('studios').select('id', { head: true, count: 'exact' });

      if (error) {
        overall = 'fail';
        checks.push({
          component: 'supabase',
          status: 'fail',
          message: `Supabase query failed: ${error.message}`
        });
      } else {
        checks.push({
          component: 'supabase',
          status: 'pass'
        });
      }
    } catch (error) {
      overall = 'fail';
      checks.push({
        component: 'supabase',
        status: 'fail',
        message:
          error instanceof Error ? error.message : 'Unexpected Supabase error'
      });
    }
  }

  if (process.env.LOGFLARE_API_KEY && process.env.LOGFLARE_SOURCE_TOKEN) {
    checks.push({
      component: 'logflare',
      status: 'pass'
    });
  } else {
    checks.push({
      component: 'logflare',
      status: 'fail',
      message: 'Logflare environment variables not configured'
    });
    overall = 'fail';
  }

  const release =
    process.env.VERCEL_GIT_COMMIT_SHA ??
    process.env.GITHUB_SHA ??
    process.env.COMMIT_SHA ??
    'unknown';

  if (overall === 'fail') {
    await logMonitoringEvent({
      event: 'health_check_failed',
      level: 'critical',
      context: {
        checks,
        release
      }
    });
  }

  return NextResponse.json(
    {
      status: overall,
      timestamp,
      release,
      environment: process.env.VERCEL_ENV ?? process.env.NODE_ENV,
      checks
    },
    {
      headers: {
        'Cache-Control': 'no-store, no-cache, must-revalidate'
      }
    }
  );
}
