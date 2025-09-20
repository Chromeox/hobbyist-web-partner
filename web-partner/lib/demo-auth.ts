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

    // Create a demo user session using a test email/password
    const demoEmail = 'demo@hobbyist.app';
    const demoPassword = 'demo123456';

    // Try to sign in with demo credentials
    let { data, error } = await supabase.auth.signInWithPassword({
      email: demoEmail,
      password: demoPassword,
    });

    if (error && error.message.includes('Invalid login credentials')) {
      // Demo user doesn't exist, create it
      console.log('Creating demo user...');
      const { data: signupData, error: signupError } = await supabase.auth.signUp({
        email: demoEmail,
        password: demoPassword,
        options: {
          data: {
            full_name: 'Demo Studio User',
            user_type: 'studio'
          }
        }
      });

      if (signupError) {
        console.error('Demo user creation failed:', signupError.message);
        return null;
      }

      // Now sign in with the new demo user
      const { data: signinData, error: signinError } = await supabase.auth.signInWithPassword({
        email: demoEmail,
        password: demoPassword,
      });

      if (signinError) {
        console.error('Demo signin after signup failed:', signinError.message);
        return null;
      }

      data = signinData;
    } else if (error) {
      console.error('Demo auth failed:', error.message);
      return null;
    }

    if (data.user) {
      console.log('Demo authentication successful:', data.user.email);
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
    const isDemo = user.user?.email === 'demo@hobbyist.app';
    return {
      isAuthenticated: !!user.user,
      user: user.user,
      isDemo: isDemo
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