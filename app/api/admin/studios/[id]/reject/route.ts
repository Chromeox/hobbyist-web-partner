import { createClient } from '@/lib/supabase/server';
import { NextResponse } from 'next/server';
import { isAdmin } from '@/lib/utils/roleUtils';
import { getServerSession } from '@/lib/auth';

export const dynamic = 'force-dynamic';


/**
 * POST /api/admin/studios/[id]/reject
 * Rejects a pending studio
 * Admin-only endpoint (Clerk)
 */
export async function POST(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id: studioId } = await params;

    // Get Clerk session
    const session = await getServerSession();

    // Verify user is authenticated
    if (!session?.user) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      );
    }

    // Verify user has admin role
    if (!isAdmin(session.user)) {
      return NextResponse.json(
        { error: 'Forbidden - Admin access required' },
        { status: 403 }
      );
    }

    // Continue using Supabase for database queries (not auth)
    const supabase = await createClient();

    // Parse request body for rejection reason (required)
    const body = await request.json();
    const { rejection_reason, admin_notes } = body;

    if (!rejection_reason) {
      return NextResponse.json(
        { error: 'Rejection reason is required' },
        { status: 400 }
      );
    }

    // Update studio to rejected status
    const { data: updatedStudio, error: updateError } = await supabase
      .from('studios')
      .update({
        approval_status: 'rejected',
        rejection_reason,
        approved_by: session.user.id, // Track who made the decision
        approved_at: new Date().toISOString(), // Track when decision was made
        admin_notes: admin_notes || null,
        is_active: false, // Deactivate rejected studios
        updated_at: new Date().toISOString(),
      })
      .eq('id', studioId)
      .select()
      .single();

    if (updateError) {
      console.error('Error rejecting studio:', updateError);
      return NextResponse.json(
        { error: 'Failed to reject studio', details: updateError.message },
        { status: 500 }
      );
    }

    // Update onboarding submission status if exists
    const { error: submissionError } = await supabase
      .from('studio_onboarding_submissions')
      .update({
        submission_status: 'rejected',
        reviewed_at: new Date().toISOString(),
        reviewed_by: session.user.id,
        admin_review_notes: `${rejection_reason}${admin_notes ? ' | ' + admin_notes : ''}`,
      })
      .eq('studio_id', studioId);

    if (submissionError) {
      console.warn('Warning: Failed to update submission status:', submissionError);
      // Don't fail the request if submission update fails
    }

    // TODO: Send rejection email notification to studio owner
    // This would integrate with your email service (Resend, SendGrid, etc.)
    // await sendStudioRejectionEmail(updatedStudio.email, updatedStudio.name, rejection_reason);

    return NextResponse.json({
      success: true,
      message: 'Studio rejected',
      studio: updatedStudio,
    });

  } catch (error) {
    console.error('Unexpected error in reject studio endpoint:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
