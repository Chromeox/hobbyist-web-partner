'use client';

import React, { useState } from 'react';
import { MessageSquare } from 'lucide-react';
import { simpleMessagingService } from '@/lib/services/messaging-simple';
import { useRouter } from 'next/navigation';

interface MessageInstructorButtonProps {
  instructorId: string;
  instructorName: string;
  size?: 'sm' | 'md' | 'lg';
  variant?: 'primary' | 'secondary' | 'ghost';
  className?: string;
}

export default function MessageInstructorButton({
  instructorId,
  instructorName,
  size = 'md',
  variant = 'secondary',
  className = ''
}: MessageInstructorButtonProps) {
  const [creating, setCreating] = useState(false);
  const router = useRouter();

  const handleMessageInstructor = async () => {
    if (creating) return;

    try {
      setCreating(true);

      // Create or find existing conversation
      const conversation = await simpleMessagingService.createConversation(
        instructorId,
        `Chat with ${instructorName}`
      );

      if (!conversation) {
        throw new Error('Unable to start conversation');
      }

      // Navigate to messages with the conversation selected
      router.push(`/dashboard/messages?conversation=${conversation.id}`);
    } catch (error) {
      console.error('Failed to create conversation:', error);
    } finally {
      setCreating(false);
    }
  };

  const sizeClasses = {
    sm: 'px-2 py-1 text-xs',
    md: 'px-3 py-2 text-sm',
    lg: 'px-4 py-2.5 text-base'
  };

  const variantClasses = {
    primary: 'bg-blue-600 hover:bg-blue-700 text-white',
    secondary: 'bg-gray-100 hover:bg-gray-200 text-gray-700',
    ghost: 'hover:bg-gray-100 text-gray-600'
  };

  const iconSizes = {
    sm: 'h-3 w-3',
    md: 'h-4 w-4',
    lg: 'h-5 w-5'
  };

  return (
    <button
      onClick={handleMessageInstructor}
      disabled={creating}
      className={`
        inline-flex items-center gap-2 font-medium rounded-lg transition-colors
        ${sizeClasses[size]}
        ${variantClasses[variant]}
        ${creating ? 'opacity-50 cursor-not-allowed' : ''}
        ${className}
      `}
      title={`Message ${instructorName}`}
    >
      {creating ? (
        <div className={`animate-spin rounded-full border-2 border-current border-t-transparent ${iconSizes[size]}`} />
      ) : (
        <MessageSquare className={iconSizes[size]} />
      )}
      {size !== 'sm' && (creating ? 'Creating...' : 'Message')}
    </button>
  );
}
