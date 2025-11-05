'use client';

import React from 'react';
import MessageInstructorButton from './MessageInstructorButton';

/**
 * Reusable messaging integrations for dashboard components
 * These can be easily added to existing dashboard sections
 */

// For instructor cards/tables
interface InstructorMessageActionProps {
  instructorId: string;
  instructorName: string;
  businessName?: string;
  size?: 'sm' | 'md' | 'lg';
  variant?: 'primary' | 'secondary' | 'ghost';
}

export function InstructorMessageAction({
  instructorId,
  instructorName,
  businessName,
  size = 'sm',
  variant = 'ghost'
}: InstructorMessageActionProps) {
  const displayName = businessName || instructorName;

  return (
    <MessageInstructorButton
      instructorId={instructorId}
      instructorName={displayName}
      size={size}
      variant={variant}
      className="min-w-0" // Prevents button from expanding table cells
    />
  );
}

// For payout dashboard venue cards
interface VenueMessageActionProps {
  venueId: string;
  venueName: string;
  instructorId?: string;
  instructorName?: string;
}

export function VenueMessageAction({
  venueId,
  venueName,
  instructorId,
  instructorName
}: VenueMessageActionProps) {
  if (!instructorId || !instructorName) {
    return null; // No instructor to message
  }

  return (
    <MessageInstructorButton
      instructorId={instructorId}
      instructorName={instructorName}
      size="sm"
      variant="secondary"
      className="w-full"
    />
  );
}

// For admin instructor management
interface AdminInstructorMessageProps {
  instructorId: string;
  instructorName: string;
  businessName?: string;
  status?: 'pending' | 'approved' | 'rejected';
}

export function AdminInstructorMessage({
  instructorId,
  instructorName,
  businessName,
  status
}: AdminInstructorMessageProps) {
  const displayName = businessName || instructorName;
  const variant = status === 'pending' ? 'primary' : 'secondary';

  return (
    <MessageInstructorButton
      instructorId={instructorId}
      instructorName={displayName}
      size="md"
      variant={variant}
      className="w-full"
    />
  );
}

// For class/session management
interface ClassInstructorMessageProps {
  instructorId: string;
  instructorName: string;
  className?: string;
  context?: 'schedule' | 'payment' | 'feedback';
}

export function ClassInstructorMessage({
  instructorId,
  instructorName,
  className,
  context = 'schedule'
}: ClassInstructorMessageProps) {
  const contextText = {
    schedule: 'Schedule Discussion',
    payment: 'Payment Question',
    feedback: 'Class Feedback'
  };

  return (
    <MessageInstructorButton
      instructorId={instructorId}
      instructorName={`${instructorName} - ${contextText[context]}`}
      size="sm"
      variant="ghost"
    />
  );
}

export default {
  InstructorMessageAction,
  VenueMessageAction,
  AdminInstructorMessage,
  ClassInstructorMessage
};