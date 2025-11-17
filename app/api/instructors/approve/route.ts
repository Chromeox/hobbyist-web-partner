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
    // This route should only be accessible by authenticated administrators.
    // You would typically verify the user's session and role here.
    // For example:
    // const { data: { user } } = await supabase.auth.getUser();
    // if (!user || user.user_metadata.role !== 'admin') {
    //   return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    // }

    const { instructorId, status } = await request.json();

    if (!instructorId || !status) {
      return NextResponse.json({ error: 'Missing instructorId or status' }, { status: 400 });
    }

    // Validate status value
    if (!['approved', 'rejected', 'pending'].includes(status)) {
      return NextResponse.json({ error: 'Invalid status value' }, { status: 400 });
    }

    // Update the instructor's status in the database
    // Assuming an 'instructors' table with 'id' and 'status' columns
    const { data, error } = await supabase
      .from('instructors')
      .update({ status: status })
      .eq('id', instructorId);

    if (error) {
      console.error('Supabase update error:', error);
      return NextResponse.json({ error: 'Failed to update instructor status' }, { status: 500 });
    }

    return NextResponse.json({ message: `Instructor ${instructorId} status updated to ${status}` }, { status: 200 });

  } catch (error: any) {
    console.error('Error processing instructor approval:', error);
    return NextResponse.json({ error: 'Internal Server Error', details: error.message }, { status: 500 });
  }
}
