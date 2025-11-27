/**
 * App Store Connect API Endpoint
 *
 * Provides admin access to App Store Connect data including:
 * - App information
 * - TestFlight builds and testers
 * - Beta group management
 *
 * @route GET /api/admin/app-store-connect
 * @route POST /api/admin/app-store-connect (for actions like adding testers)
 */

import { NextRequest, NextResponse } from 'next/server';
import { auth } from '@clerk/nextjs/server';
import {
  testConnection,
  getApps,
  getAppByBundleId,
  getBetaBuilds,
  getBetaGroups,
  getBetaTesters,
  isConfigured,
} from '@/lib/services/app-store-connect';

export const dynamic = 'force-dynamic';

// Your app's bundle ID
const APP_BUNDLE_ID = process.env.APPLE_BUNDLE_ID || 'com.hobbyist.bookingapp';

/**
 * GET: Retrieve App Store Connect data
 */
export async function GET(request: NextRequest) {
  try {
    // Check authentication
    const { userId } = await auth();
    if (!userId) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      );
    }

    // Check if API is configured
    if (!isConfigured()) {
      return NextResponse.json(
        {
          error: 'App Store Connect API not configured',
          configured: false,
          hint: 'Set APP_STORE_CONNECT_KEY_ID, APP_STORE_CONNECT_ISSUER_ID, and APP_STORE_CONNECT_PRIVATE_KEY environment variables',
        },
        { status: 503 }
      );
    }

    const { searchParams } = new URL(request.url);
    const action = searchParams.get('action') || 'status';

    switch (action) {
      case 'status': {
        const result = await testConnection();
        return NextResponse.json(result);
      }

      case 'apps': {
        const apps = await getApps();
        return NextResponse.json({ apps });
      }

      case 'app': {
        const bundleId = searchParams.get('bundleId') || APP_BUNDLE_ID;
        const app = await getAppByBundleId(bundleId);
        if (!app) {
          return NextResponse.json(
            { error: `App with bundle ID ${bundleId} not found` },
            { status: 404 }
          );
        }
        return NextResponse.json({ app });
      }

      case 'builds': {
        const app = await getAppByBundleId(APP_BUNDLE_ID);
        if (!app) {
          return NextResponse.json(
            { error: 'App not found' },
            { status: 404 }
          );
        }
        const builds = await getBetaBuilds(app.id);
        return NextResponse.json({ builds });
      }

      case 'testers': {
        const app = await getAppByBundleId(APP_BUNDLE_ID);
        if (!app) {
          return NextResponse.json(
            { error: 'App not found' },
            { status: 404 }
          );
        }
        const testers = await getBetaTesters(app.id);
        return NextResponse.json({ testers });
      }

      case 'groups': {
        const app = await getAppByBundleId(APP_BUNDLE_ID);
        if (!app) {
          return NextResponse.json(
            { error: 'App not found' },
            { status: 404 }
          );
        }
        const groups = await getBetaGroups(app.id);
        return NextResponse.json({ groups });
      }

      case 'dashboard': {
        // Get comprehensive dashboard data
        const app = await getAppByBundleId(APP_BUNDLE_ID);
        if (!app) {
          return NextResponse.json(
            { error: 'App not found' },
            { status: 404 }
          );
        }

        const [builds, testers, groups] = await Promise.all([
          getBetaBuilds(app.id),
          getBetaTesters(app.id),
          getBetaGroups(app.id),
        ]);

        return NextResponse.json({
          app: {
            id: app.id,
            name: app.attributes.name,
            bundleId: app.attributes.bundleId,
          },
          stats: {
            totalBuilds: builds.length,
            totalTesters: testers.length,
            totalGroups: groups.length,
            latestBuild: builds[0] || null,
          },
          builds: builds.slice(0, 5), // Last 5 builds
          groups,
        });
      }

      default:
        return NextResponse.json(
          { error: `Unknown action: ${action}` },
          { status: 400 }
        );
    }
  } catch (error) {
    console.error('App Store Connect API error:', error);
    return NextResponse.json(
      {
        error: 'Failed to fetch App Store Connect data',
        message: error instanceof Error ? error.message : 'Unknown error',
      },
      { status: 500 }
    );
  }
}
