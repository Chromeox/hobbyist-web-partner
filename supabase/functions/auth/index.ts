// Authentication & Authorization Edge Function
// Handles user registration, login, profile updates, and role management

import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';
import { createSupabaseClient, corsHeaders, createResponse, errorResponse, getUserId, validateBody } from '../_shared/utils.ts';
import { User, UserProfile, Instructor } from '../_shared/types.ts';

const ALLOWED_ORIGINS = [
  'http://localhost:3000',
  'https://hobbyist.app',
  'capacitor://localhost',
  'ionic://localhost',
];

serve(async (req: Request) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const url = new URL(req.url);
  const method = req.method;
  const path = url.pathname.replace('/auth', '');

  try {
    const authHeader = req.headers.get('Authorization');
    const origin = req.headers.get('Origin');

    // Validate origin for security
    if (origin && !ALLOWED_ORIGINS.includes(origin)) {
      return errorResponse('Unauthorized origin', 'INVALID_ORIGIN', 403);
    }

    // Route requests
    switch (method) {
      case 'POST':
        switch (path) {
          case '/register':
            return handleRegister(req);
          case '/complete-profile':
            return handleCompleteProfile(req, authHeader);
          case '/update-profile':
            return handleUpdateProfile(req, authHeader);
          case '/become-instructor':
            return handleBecomeInstructor(req, authHeader);
          case '/verify-email':
            return handleVerifyEmail(req);
          case '/reset-password':
            return handleResetPassword(req);
          case '/change-password':
            return handleChangePassword(req, authHeader);
          case '/delete-account':
            return handleDeleteAccount(req, authHeader);
          default:
            return errorResponse('Endpoint not found', 'NOT_FOUND', 404);
        }
      case 'GET':
        switch (path) {
          case '/profile':
            return handleGetProfile(req, authHeader);
          case '/instructor-profile':
            return handleGetInstructorProfile(req, authHeader);
          default:
            return errorResponse('Endpoint not found', 'NOT_FOUND', 404);
        }
      default:
        return errorResponse('Method not allowed', 'METHOD_NOT_ALLOWED', 405);
    }
  } catch (error) {
    console.error('Auth function error:', error);
    return errorResponse(
      'Internal server error',
      'INTERNAL_ERROR',
      500,
      { message: error.message }
    );
  }
});

async function handleRegister(req: Request): Promise<Response> {
  const body = await req.json();
  const validation = validateBody(body, ['email', 'password', 'first_name', 'last_name']);
  
  if (!validation.valid) {
    return errorResponse('Invalid request body', 'VALIDATION_ERROR', 400, {
      errors: validation.errors,
    });
  }

  const { email, password, first_name, last_name, phone } = validation.data;
  const supabase = createSupabaseClient();

  try {
    // Create user account
    const { data: authData, error: authError } = await supabase.auth.admin.createUser({
      email,
      password,
      email_confirm: false, // We'll handle email confirmation separately
      user_metadata: {
        first_name,
        last_name,
        phone,
        role: 'student', // Default role
      },
    });

    if (authError) {
      return errorResponse(
        authError.message,
        'AUTH_ERROR',
        400,
        { supabase_error: authError }
      );
    }

    // Create user profile
    const { error: profileError } = await supabase
      .from('user_profiles')
      .insert({
        user_id: authData.user.id,
        first_name,
        last_name,
        phone: phone || null,
      });

    if (profileError) {
      // Cleanup: delete the created user if profile creation fails
      await supabase.auth.admin.deleteUser(authData.user.id);
      return errorResponse(
        'Failed to create user profile',
        'PROFILE_ERROR',
        500,
        { supabase_error: profileError }
      );
    }

    // Send verification email (handled by Supabase Auth)
    const { error: emailError } = await supabase.auth.resend({
      type: 'signup',
      email,
    });

    if (emailError) {
      console.warn('Failed to send verification email:', emailError);
    }

    return createResponse({
      user_id: authData.user.id,
      email: authData.user.email,
      email_confirmed: false,
      message: 'Registration successful. Please check your email for verification.',
    });
  } catch (error) {
    console.error('Registration error:', error);
    return errorResponse(
      'Registration failed',
      'REGISTRATION_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleCompleteProfile(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const body = await req.json();
  const validation = validateBody(body, ['date_of_birth']);
  
  if (!validation.valid) {
    return errorResponse('Invalid request body', 'VALIDATION_ERROR', 400, {
      errors: validation.errors,
    });
  }

  const { date_of_birth, bio, emergency_contact, preferences } = validation.data;
  const supabase = createSupabaseClient(authHeader);

  try {
    const { data, error } = await supabase
      .from('user_profiles')
      .update({
        date_of_birth,
        bio: bio || null,
        emergency_contact: emergency_contact || null,
        preferences: preferences || {
          notifications: {
            email: true,
            push: true,
            sms: false,
            class_reminders: true,
            promotional: false,
            instructor_updates: true,
          },
          privacy: {
            profile_visible: true,
            show_attendance: false,
            allow_invites: true,
          },
          accessibility: {
            high_contrast: false,
            large_text: false,
            reduce_motion: false,
            haptic_feedback: true,
          },
        },
      })
      .eq('user_id', userId)
      .select()
      .single();

    if (error) {
      return errorResponse(
        'Failed to update profile',
        'UPDATE_ERROR',
        500,
        { supabase_error: error }
      );
    }

    return createResponse(data);
  } catch (error) {
    console.error('Complete profile error:', error);
    return errorResponse(
      'Failed to complete profile',
      'PROFILE_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleUpdateProfile(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const body = await req.json();
  const supabase = createSupabaseClient(authHeader);

  try {
    const { data: currentProfile, error: fetchError } = await supabase
      .from('user_profiles')
      .select('*')
      .eq('user_id', userId)
      .single();

    if (fetchError) {
      return errorResponse(
        'Profile not found',
        'NOT_FOUND',
        404,
        { supabase_error: fetchError }
      );
    }

    // Merge updates with current profile
    const updates = {
      ...currentProfile,
      ...body,
      updated_at: new Date().toISOString(),
    };

    // Remove fields that shouldn't be updated directly
    delete updates.user_id;
    delete updates.created_at;

    const { data, error } = await supabase
      .from('user_profiles')
      .update(updates)
      .eq('user_id', userId)
      .select()
      .single();

    if (error) {
      return errorResponse(
        'Failed to update profile',
        'UPDATE_ERROR',
        500,
        { supabase_error: error }
      );
    }

    return createResponse(data);
  } catch (error) {
    console.error('Update profile error:', error);
    return errorResponse(
      'Failed to update profile',
      'PROFILE_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleBecomeInstructor(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const body = await req.json();
  const validation = validateBody(body, ['specialties']);
  
  if (!validation.valid) {
    return errorResponse('Invalid request body', 'VALIDATION_ERROR', 400, {
      errors: validation.errors,
    });
  }

  const { business_name, specialties, certifications } = validation.data;
  const supabase = createSupabaseClient();

  try {
    // Check if user already has instructor profile
    const { data: existing } = await supabase
      .from('instructor_profiles')
      .select('id')
      .eq('user_id', userId)
      .single();

    if (existing) {
      return errorResponse('User already has instructor profile', 'ALREADY_EXISTS', 400);
    }

    // Update user role to instructor
    const { error: roleError } = await supabase.auth.admin.updateUserById(userId, {
      user_metadata: { role: 'instructor' },
    });

    if (roleError) {
      return errorResponse(
        'Failed to update user role',
        'ROLE_UPDATE_ERROR',
        500,
        { supabase_error: roleError }
      );
    }

    // Create instructor profile
    const { data, error } = await supabase
      .from('instructor_profiles')
      .insert({
        user_id: userId,
        business_name: business_name || null,
        stripe_account_status: 'pending',
        commission_rate: parseFloat(Deno.env.get('PLATFORM_COMMISSION_PERCENTAGE') || '15'),
        rating: 0,
        total_reviews: 0,
        total_students: 0,
        verified: false,
        specialties,
        certifications: certifications || [],
        availability: {
          monday: [],
          tuesday: [],
          wednesday: [],
          thursday: [],
          friday: [],
          saturday: [],
          sunday: [],
          exceptions: [],
        },
      })
      .select()
      .single();

    if (error) {
      // Rollback role update
      await supabase.auth.admin.updateUserById(userId, {
        user_metadata: { role: 'student' },
      });
      
      return errorResponse(
        'Failed to create instructor profile',
        'INSTRUCTOR_ERROR',
        500,
        { supabase_error: error }
      );
    }

    return createResponse({
      ...data,
      message: 'Instructor profile created successfully. You can now create classes!',
    });
  } catch (error) {
    console.error('Become instructor error:', error);
    return errorResponse(
      'Failed to create instructor profile',
      'INSTRUCTOR_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleGetProfile(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const supabase = createSupabaseClient(authHeader);

  try {
    // Get user profile with auth metadata
    const { data: profile, error: profileError } = await supabase
      .from('user_profiles')
      .select('*')
      .eq('user_id', userId)
      .single();

    if (profileError) {
      return errorResponse(
        'Profile not found',
        'NOT_FOUND',
        404,
        { supabase_error: profileError }
      );
    }

    // Get user auth data
    const { data: authData, error: authError } = await supabase.auth.admin.getUserById(userId);
    
    if (authError) {
      return errorResponse(
        'User not found',
        'NOT_FOUND',
        404,
        { supabase_error: authError }
      );
    }

    const user: User = {
      id: authData.user.id,
      email: authData.user.email!,
      role: authData.user.user_metadata?.role || 'student',
      profile: profile as UserProfile,
      created_at: authData.user.created_at,
      updated_at: authData.user.updated_at || authData.user.created_at,
    };

    return createResponse(user);
  } catch (error) {
    console.error('Get profile error:', error);
    return errorResponse(
      'Failed to get profile',
      'PROFILE_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleGetInstructorProfile(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const supabase = createSupabaseClient(authHeader);

  try {
    const { data, error } = await supabase
      .from('instructor_profiles')
      .select('*')
      .eq('user_id', userId)
      .single();

    if (error) {
      return errorResponse(
        'Instructor profile not found',
        'NOT_FOUND',
        404,
        { supabase_error: error }
      );
    }

    return createResponse(data);
  } catch (error) {
    console.error('Get instructor profile error:', error);
    return errorResponse(
      'Failed to get instructor profile',
      'PROFILE_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleVerifyEmail(req: Request): Promise<Response> {
  const body = await req.json();
  const validation = validateBody(body, ['token']);
  
  if (!validation.valid) {
    return errorResponse('Invalid request body', 'VALIDATION_ERROR', 400, {
      errors: validation.errors,
    });
  }

  const { token } = validation.data;
  const supabase = createSupabaseClient();

  try {
    const { data, error } = await supabase.auth.verifyOtp({
      token_hash: token,
      type: 'email',
    });

    if (error) {
      return errorResponse(
        'Email verification failed',
        'VERIFICATION_ERROR',
        400,
        { supabase_error: error }
      );
    }

    return createResponse({
      user_id: data.user?.id,
      email_confirmed: true,
      message: 'Email verified successfully',
    });
  } catch (error) {
    console.error('Email verification error:', error);
    return errorResponse(
      'Email verification failed',
      'VERIFICATION_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleResetPassword(req: Request): Promise<Response> {
  const body = await req.json();
  const validation = validateBody(body, ['email']);
  
  if (!validation.valid) {
    return errorResponse('Invalid request body', 'VALIDATION_ERROR', 400, {
      errors: validation.errors,
    });
  }

  const { email } = validation.data;
  const supabase = createSupabaseClient();

  try {
    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: 'https://hobbyist.app/reset-password',
    });

    if (error) {
      return errorResponse(
        'Failed to send reset email',
        'RESET_ERROR',
        400,
        { supabase_error: error }
      );
    }

    return createResponse({
      message: 'Password reset email sent successfully',
    });
  } catch (error) {
    console.error('Reset password error:', error);
    return errorResponse(
      'Failed to send reset email',
      'RESET_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleChangePassword(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const body = await req.json();
  const validation = validateBody(body, ['current_password', 'new_password']);
  
  if (!validation.valid) {
    return errorResponse('Invalid request body', 'VALIDATION_ERROR', 400, {
      errors: validation.errors,
    });
  }

  const { current_password, new_password } = validation.data;
  const supabase = createSupabaseClient();

  try {
    // Verify current password by attempting to sign in
    const { data: user } = await supabase.auth.admin.getUserById(userId);
    if (!user.user?.email) {
      return errorResponse('User email not found', 'USER_ERROR', 400);
    }

    const { error: signInError } = await supabase.auth.signInWithPassword({
      email: user.user.email,
      password: current_password,
    });

    if (signInError) {
      return errorResponse(
        'Current password is incorrect',
        'INVALID_PASSWORD',
        400
      );
    }

    // Update password
    const { error } = await supabase.auth.admin.updateUserById(userId, {
      password: new_password,
    });

    if (error) {
      return errorResponse(
        'Failed to update password',
        'PASSWORD_UPDATE_ERROR',
        500,
        { supabase_error: error }
      );
    }

    return createResponse({
      message: 'Password updated successfully',
    });
  } catch (error) {
    console.error('Change password error:', error);
    return errorResponse(
      'Failed to change password',
      'PASSWORD_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleDeleteAccount(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const body = await req.json();
  const validation = validateBody(body, ['password']);
  
  if (!validation.valid) {
    return errorResponse('Invalid request body', 'VALIDATION_ERROR', 400, {
      errors: validation.errors,
    });
  }

  const { password } = validation.data;
  const supabase = createSupabaseClient();

  try {
    // Verify password
    const { data: user } = await supabase.auth.admin.getUserById(userId);
    if (!user.user?.email) {
      return errorResponse('User email not found', 'USER_ERROR', 400);
    }

    const { error: signInError } = await supabase.auth.signInWithPassword({
      email: user.user.email,
      password,
    });

    if (signInError) {
      return errorResponse(
        'Password is incorrect',
        'INVALID_PASSWORD',
        400
      );
    }

    // TODO: Handle data cleanup (bookings, payments, etc.) before deletion
    // This should be done in a separate function to handle complex relationships

    // Delete user account
    const { error } = await supabase.auth.admin.deleteUser(userId);

    if (error) {
      return errorResponse(
        'Failed to delete account',
        'DELETE_ERROR',
        500,
        { supabase_error: error }
      );
    }

    return createResponse({
      message: 'Account deleted successfully',
    });
  } catch (error) {
    console.error('Delete account error:', error);
    return errorResponse(
      'Failed to delete account',
      'DELETE_ERROR',
      500,
      { error: error.message }
    );
  }
}