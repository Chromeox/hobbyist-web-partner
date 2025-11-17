import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

export const dynamic = 'force-dynamic';


// Initialize Supabase client with service role key for elevated privileges
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;
const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

export async function POST(request: Request) {
  try {
    // --- Authentication/Authorization (Crucial for Production) ---
    // Verify the user's identity and ensure they are authorized to update this profile.
    // This typically involves checking the user's session and matching the user ID
    // from the session with the instructor ID being updated.
    // For example:
    // const { data: { user }, error: authError } = await supabase.auth.getUser();
    // if (authError || !user) {
    //   return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    // }
    // const authenticatedUserId = user.id;

    const {
      id, // Instructor ID to update
      first_name,
      last_name,
      bio,
      phone_number,
      profile_picture_url,
      qualifications,
      specialties,
      portfolio_images,
    } = await request.json();

    // Basic validation
    if (!id) {
      return NextResponse.json({ error: 'Instructor ID is required' }, { status: 400 });
    }

    // Ensure the authenticated user is updating their own profile
    // if (id !== authenticatedUserId) {
    //   return NextResponse.json({ error: 'Forbidden: You can only update your own profile' }, { status: 403 });
    // }

    // Update the instructor's profile in the database
    // Assuming an 'instructors' table
    const { data, error } = await supabase
      .from('instructors')
      .update({
        first_name,
        last_name,
        bio,
        phone_number,
        profile_picture_url,
        qualifications,
        specialties,
        portfolio_images,
        updated_at: new Date().toISOString(), // Track last update
      })
      .eq('id', id);

    if (error) {
      console.error('Supabase update error:', error);
      return NextResponse.json({ error: 'Failed to update instructor profile' }, { status: 500 });
    }

    return NextResponse.json({ message: 'Instructor profile updated successfully' }, { status: 200 });

  } catch (error: any) {
    console.error('Error processing instructor profile update:', error);
    return NextResponse.json({ error: 'Internal Server Error', details: error.message }, { status: 500 });
  }
}
