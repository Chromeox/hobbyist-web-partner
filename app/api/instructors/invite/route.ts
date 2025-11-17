import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

export const dynamic = 'force-dynamic';


// Lazy initialization to avoid build-time evaluation
const getSupabase = () => {
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
  const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;
  return createClient(supabaseUrl, supabaseServiceRoleKey);
};

export async function POST(request: Request) {
  try {
    const supabase = getSupabase();
    // --- Authentication/Authorization (Crucial for Production) ---
    // Verify the user's identity and ensure they are authorized to send invitations.
    // This typically involves checking the user's session and role (e.g., 'studio' role).
    // For example:
    // const { data: { user }, error: authError } = await supabase.auth.getUser();
    // if (authError || !user || user.user_metadata.role !== 'studio') {
    //   return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    // }
    // const studioId = user.id; // Assuming the studio's user ID is their studio ID

    const { studioId, instructorId } = await request.json();

    // Basic validation
    if (!studioId || !instructorId) {
      return NextResponse.json({ error: 'Missing studioId or instructorId' }, { status: 400 });
    }

    // --- Record the Invitation ---
    // Insert a record into an 'invitations' table in Supabase.
    // This table would track who invited whom, the status of the invitation, etc.
    // Assuming an 'invitations' table with 'studio_id', 'instructor_id', 'status'
    const { data, error } = await supabase
      .from('invitations')
      .insert({
        studio_id: studioId,
        instructor_id: instructorId,
        status: 'pending', // Initial status
        created_at: new Date().toISOString(),
      });

    if (error) {
      console.error('Supabase insert error:', error);
      return NextResponse.json({ error: 'Failed to send invitation' }, { status: 500 });
    }

    // --- Optional: Send Notification to Instructor ---
    // In a real application, you would likely send an email or in-app notification
    // to the invited instructor to inform them about the new invitation.
    // This would involve another service call (e.g., a notification service).

    return NextResponse.json({ message: 'Invitation sent successfully' }, { status: 200 });

  } catch (error: any) {
    console.error('Error processing invitation:', error);
    return NextResponse.json({ error: 'Internal Server Error', details: error.message }, { status: 500 });
  }
}
