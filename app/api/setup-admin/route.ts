/**
 * One-Time Admin Setup Endpoint
 *
 * ⚠️ SECURITY: Delete this file after using it!
 *
 * Usage:
 * POST http://localhost:3000/api/setup-admin
 * Body: { "email": "admin@hobbi.com", "password": "YourSecurePassword123!" }
 */

import { NextRequest, NextResponse } from 'next/server';
import { auth } from '@/lib/auth';

export async function POST(request: NextRequest) {
  try {
    // Parse request
    const { email, password } = await request.json();

    if (!email || !password) {
      return NextResponse.json(
        { error: 'Email and password required' },
        { status: 400 }
      );
    }

    // Validate password strength
    if (password.length < 8) {
      return NextResponse.json(
        { error: 'Password must be at least 8 characters' },
        { status: 400 }
      );
    }

    // Create user with Better Auth
    // This bypasses email verification
    const result = await auth.api.signUpEmail({
      body: {
        email,
        password,
        name: 'Admin User',
      },
    });

    if (result.error) {
      return NextResponse.json(
        { error: result.error.message },
        { status: 400 }
      );
    }

    // Update user to admin role using database
    const pool = await import('pg').then((pg) => new pg.Pool({
      connectionString: process.env.DATABASE_URL,
    }));

    await pool.query(`
      UPDATE "user"
      SET
        role = 'admin',
        "accountType" = 'admin',
        "emailVerified" = true,
        "firstName" = 'Admin',
        "lastName" = 'User'
      WHERE email = $1
    `, [email]);

    await pool.end();

    return NextResponse.json({
      success: true,
      message: 'Admin user created successfully!',
      email,
      note: '⚠️ DELETE /app/api/setup-admin/route.ts NOW!',
    });

  } catch (error: any) {
    console.error('Admin setup error:', error);
    return NextResponse.json(
      { error: error.message || 'Failed to create admin user' },
      { status: 500 }
    );
  }
}
