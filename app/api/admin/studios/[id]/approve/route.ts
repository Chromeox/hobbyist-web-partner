import { createClient } from '@/lib/supabase/server';
import { NextResponse } from 'next/server';
import { isAdmin } from '@/lib/utils/roleUtils';
import { auth } from '@/lib/auth';
import { headers } from 'next/headers';

export const dynamic = 'force-dynamic';


/**
 * POST /api/admin/studios/[id]/approve
 * Approves a pending studio
 * Admin-only endpoint (Better Auth)
 */
export async function POST(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id: studioId } = await params;

    // Get Better Auth session
    const session = await auth.api.getSession({
      headers: await headers()
    });

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

    // Parse request body for optional notes
    const body = await request.json().catch(() => ({}));
    const { admin_notes } = body;

    // Update studio to approved status
    const { data: updatedStudio, error: updateError } = await supabase
      .from('studios')
      .update({
        approval_status: 'approved',
        approved_by: session.user.id,
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
        reviewed_by: session.user.id,
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
