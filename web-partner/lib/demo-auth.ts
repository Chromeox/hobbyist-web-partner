'use client';

import { supabase } from '@/lib/supabase';

/**
 * Demo Authentication Helper
 * Creates a temporary demo user session for testing messaging
 */

export async function createDemoAuthSession() {
  try {
    // Check if user is already authenticated
    const { data: user } = await supabase.auth.getUser();
    if (user.user) {
      console.log('User already authenticated:', user.user.email);
      return user.user;
    }

    // Create a demo user session using anonymous sign-in
    const { data, error } = await supabase.auth.signInAnonymously();

    if (error) {
      console.error('Demo auth failed:', error.message);
      return null;
    }

    if (data.user) {
      console.log('Demo authentication successful:', data.user.id);
      return data.user;
    }

    return null;
  } catch (error) {
    console.error('Demo auth error:', error);
    return null;
  }
}

export async function signOutDemo() {
  try {
    await supabase.auth.signOut();
    console.log('Demo user signed out');
  } catch (error) {
    console.error('Sign out error:', error);
  }
}

export async function getDemoAuthStatus() {
  try {
    const { data: user } = await supabase.auth.getUser();
    return {
      isAuthenticated: !!user.user,
      user: user.user,
      isDemo: user.user?.is_anonymous || false
    };
  } catch (error) {
    console.error('Auth status error:', error);
    return {
      isAuthenticated: false,
      user: null,
      isDemo: false
    };
  }
}