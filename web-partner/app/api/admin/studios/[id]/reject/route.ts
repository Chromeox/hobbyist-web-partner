import { createClient } from '@/lib/supabase/server';
import { NextResponse } from 'next/server';

/**
 * POST /api/admin/studios/[id]/reject
 * Rejects a pending studio
 * Admin-only endpoint
 */
export async function POST(
  request: Request,
  { params }: { params: { id: string } }
) {
  try {
    const supabase = await createClient();
    const studioId = params.id;

    // Verify user is authenticated
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      );
    }

    // TODO: Add admin role check once user_profiles has role column
    // For now, any authenticated user can reject studios

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
        approved_by: user.id, // Track who made the decision
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
        reviewed_by: user.id,
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
