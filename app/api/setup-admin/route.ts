/**
 * One-Time Admin Setup Endpoint (DEPRECATED)
 *
 * ⚠️ SECURITY: Delete this file after using it!
 * ⚠️ With Clerk: Create admin users via Clerk Dashboard instead
 *
 * This endpoint is deprecated as Clerk handles user creation.
 * To make a user admin in Clerk:
 * 1. Go to Clerk Dashboard > Users
 * 2. Select the user
 * 3. Update their unsafeMetadata to include: { "role": "admin" }
 */

import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  return NextResponse.json({
    error: 'This endpoint is deprecated',
    message: 'With Clerk authentication, create admin users via Clerk Dashboard instead.',
    instructions: [
      '1. Go to Clerk Dashboard > Users',
      '2. Select or create the user',
      '3. Update unsafeMetadata to include: { "role": "admin" }',
    ],
  }, { status: 410 }); // 410 Gone
}
