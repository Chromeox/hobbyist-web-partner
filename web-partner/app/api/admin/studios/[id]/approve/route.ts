import { createClient } from '@/lib/supabase/server';
import { NextResponse } from 'next/server';

/**
 * POST /api/admin/studios/[id]/approve
 * Approves a pending studio
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
    // For now, any authenticated user can approve studios

    // Parse request body for optional notes
    const body = await request.json().catch(() => ({}));
    const { admin_notes } = body;

    // Update studio to approved status
    const { data: updatedStudio, error: updateError } = await supabase
      .from('studios')
      .update({
        approval_status: 'approved',
        approved_by: user.id,
        approved_at: new Date().toISOString(),
        admin_notes: admin_notes || null,
        is_active: true,
        updated_at: new Date().toISOString(),
      })
      .eq('id', studioId)
      .select()
      .single();

    if (updateError) {
      console.error('Error approving studio:', updateError);
      return NextResponse.json(
        { error: 'Failed to approve studio', details: updateError.message },
        { status: 500 }
      );
    }

    // Update onboarding submission status if exists
    const { error: submissionError } = await supabase
      .from('studio_onboarding_submissions')
      .update({
        submission_status: 'approved',
        reviewed_at: new Date().toISOString(),
        reviewed_by: user.id,
        admin_review_notes: admin_notes || null,
      })
      .eq('studio_id', studioId);

    if (submissionError) {
      console.warn('Warning: Failed to update submission status:', submissionError);
      // Don't fail the request if submission update fails
    }

    // TODO: Send approval email notification to studio owner
    // This would integrate with your email service (Resend, SendGrid, etc.)
    // await sendStudioApprovalEmail(updatedStudio.email, updatedStudio.name);

    return NextResponse.json({
      success: true,
      message: 'Studio approved successfully',
      studio: updatedStudio,
    });

  } catch (error) {
    console.error('Unexpected error in approve studio endpoint:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
