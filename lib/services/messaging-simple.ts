'use client';

import { supabase } from '@/lib/supabase';
import { RealtimeChannel } from '@supabase/supabase-js';
import type { Database, Json } from '@/types/supabase';

// Simplified types that work with any auth system
export interface SimpleConversation {
  id: string;
  studio_id?: string;
  instructor_id: string;
  type: 'individual' | 'group';
  name: string;
  participants: string[];
  last_message?: string;
  last_message_at?: string;
  created_at: string;
  updated_at: string;
  unreadCount?: number;
}

export interface SimpleMessage {
  id: string;
  conversation_id: string;
  sender_id?: string;
  content: string;
  attachments?: Array<{
    type: 'image' | 'file';
    url: string;
    name: string;
  }>;
  read_at?: string;
  read?: boolean;
  created_at: string;
  updated_at: string;
}

type ConversationRow = Database['public']['Tables']['conversations']['Row'];
type MessageRow = Database['public']['Tables']['messages']['Row'];
type SimpleAttachment = NonNullable<SimpleMessage['attachments']>[number];

const normaliseTimestamp = (timestamp: string | null): string => {
  return timestamp ?? new Date().toISOString();
};

const mapConversationRow = (row: ConversationRow): SimpleConversation => ({
  id: row.id,
  studio_id: row.studio_id ?? undefined,
  instructor_id: row.instructor_id,
  type: row.type === 'group' ? 'group' : 'individual',
  name: row.name,
  participants: row.participants ?? [],
  last_message: row.last_message ?? undefined,
  last_message_at: row.last_message_at ?? undefined,
  created_at: normaliseTimestamp(row.created_at),
  updated_at: normaliseTimestamp(row.updated_at ?? row.created_at),
  unreadCount: 0
});

const normaliseAttachments = (value: Json | null): SimpleMessage['attachments'] => {
  if (!Array.isArray(value)) {
    return undefined;
  }

  const attachments: SimpleAttachment[] = [];

  for (const item of value) {
    if (
      item &&
      typeof item === 'object' &&
      'type' in item &&
      'url' in item &&
      'name' in item
    ) {
      const typedItem = item as {
        type?: unknown;
        url?: unknown;
        name?: unknown;
      };

      if (
        (typedItem.type === 'image' || typedItem.type === 'file') &&
        typeof typedItem.url === 'string' &&
        typeof typedItem.name === 'string'
      ) {
        attachments.push({
          type: typedItem.type,
          url: typedItem.url,
          name: typedItem.name
        });
      }
    }
  }

  return attachments.length > 0 ? attachments : undefined;
};

const mapMessageRow = (row: MessageRow): SimpleMessage => ({
  id: row.id,
  conversation_id: row.conversation_id,
  sender_id: row.sender_id ?? undefined,
  content: row.content,
  attachments: normaliseAttachments(row.attachments),
  read_at: row.read_at ?? undefined,
  read: Boolean(row.read_at),
  created_at: normaliseTimestamp(row.created_at),
  updated_at: normaliseTimestamp(row.updated_at ?? row.created_at)
});

class SimpleMessagingService {
  private channels: Map<string, RealtimeChannel> = new Map();
  private conversationCallbacks: ((conversations: SimpleConversation[]) => void)[] = [];
  private messageCallbacks: Map<string, ((messages: SimpleMessage[]) => void)[]> = new Map();

  // Get all conversations for current user
  async getConversations(): Promise<SimpleConversation[]> {
    try {
      // Check if there's an active session first to avoid auth errors
      const { data: session } = await supabase.auth.getSession();
      if (!session.session) {
        return [];
      }

      const { data: user } = await supabase.auth.getUser();
      if (!user.user) {
        return [];
      }

      const { data: conversations, error } = await supabase
        .from('conversations')
        .select('*')
        .order('last_message_at', { ascending: false, nullsFirst: false })
        .order('created_at', { ascending: false });

      if (error) {
        console.error('Error fetching conversations:', error);
        return [];
      }

      // Add unread count (simplified)
      return (conversations ?? []).map(mapConversationRow);
    } catch (error) {
      console.error('Failed to get conversations:', error);
      return [];
    }
  }

  // Get messages for a specific conversation
  async getMessages(conversationId: string): Promise<SimpleMessage[]> {
    try {
      // Handle demo conversations
      if (conversationId.startsWith('demo-conversation-')) {
        console.log('Returning mock messages for demo conversation:', conversationId);
        const baseTimestamp = Date.now();
        return [
          {
            id: 'demo-message-1',
            conversation_id: conversationId,
            sender_id: 'test-instructor-001',
            content: "Hi! Thanks for reaching out. I'm excited to work with you on your fitness journey.",
            created_at: new Date(baseTimestamp - 300000).toISOString(),
            updated_at: new Date(baseTimestamp - 300000).toISOString(),
            read_at: new Date(baseTimestamp - 240000).toISOString(),
            read: true
          },
          {
            id: 'demo-message-2',
            conversation_id: conversationId,
            sender_id: 'demo-studio-user',
            content: "That sounds great! I'm particularly interested in your yoga classes. Do you have any beginner-friendly options?",
            created_at: new Date(baseTimestamp - 180000).toISOString(),
            updated_at: new Date(baseTimestamp - 180000).toISOString(),
            read_at: new Date(baseTimestamp - 120000).toISOString(),
            read: true
          },
          {
            id: 'demo-message-3',
            conversation_id: conversationId,
            sender_id: 'test-instructor-001',
            content: 'Absolutely! I have a perfect Hatha Yoga class for beginners every Tuesday and Thursday at 6 PM. It focuses on basic poses and breathing techniques.',
            created_at: new Date(baseTimestamp - 60000).toISOString(),
            updated_at: new Date(baseTimestamp - 60000).toISOString(),
            read_at: new Date(baseTimestamp - 30000).toISOString(),
            read: true
          }
        ];
      }

      const { data: messages, error } = await supabase
        .from('messages')
        .select('*')
        .eq('conversation_id', conversationId)
        .order('created_at', { ascending: true });

      if (error) {
        console.error('Error fetching messages:', error);
        return [];
      }

      return (messages ?? []).map(mapMessageRow);
    } catch (error) {
      console.error('Failed to get messages:', error);
      return [];
    }
  }

  // Send a new message
  async sendMessage(conversationId: string, content: string, attachments?: Array<{
    type: 'image' | 'file';
    url: string;
    name: string;
  }>): Promise<SimpleMessage | null> {
    try {
      // Handle demo conversations
      if (conversationId.startsWith('demo-conversation-')) {
        console.log('Simulating message send for demo conversation:', conversationId);
        const mockMessage: SimpleMessage = {
          id: `demo-message-${Date.now()}`,
          conversation_id: conversationId,
          sender_id: 'demo-studio-user',
          content,
          attachments: attachments || [],
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
          read: false
        };

        // Simulate a brief delay to make it feel realistic
        await new Promise(resolve => setTimeout(resolve, 500));

        return mockMessage;
      }

      // Check if there's an active session first to avoid auth errors
      const { data: session } = await supabase.auth.getSession();
      if (!session.session) {
        return null;
      }

      const { data: user } = await supabase.auth.getUser();
      if (!user.user) {
        return null;
      }

      const messageData = {
        conversation_id: conversationId,
        sender_id: user.user.id,
        content,
        attachments: attachments || [],
      };

      const { data: message, error } = await supabase
        .from('messages')
        .insert(messageData)
        .select()
        .single();

      if (error) {
        console.error('Error sending message:', error);
        return null;
      }

      return mapMessageRow(message);
    } catch (error) {
      console.error('Failed to send message:', error);
      return null;
    }
  }

  // Create a new conversation (simplified)
  async createConversation(
    instructorId: string,
    name: string,
    type: 'individual' | 'group' = 'individual'
  ): Promise<SimpleConversation | null> {
    try {
      // Check if there's an active session first to avoid auth errors
      const { data: session } = await supabase.auth.getSession();
      if (!session.session) {
        return null;
      }

      const { data: user } = await supabase.auth.getUser();
      if (!user.user) {
        return null;
      }

      const conversationData = {
        studio_id: user.user.id,
        instructor_id: instructorId,
        type,
        name,
        participants: [user.user.id, instructorId],
      };

      const { data: conversation, error } = await supabase
        .from('conversations')
        .insert(conversationData)
        .select()
        .single();

      if (error) {
        console.error('Error creating conversation:', error);
        return null;
      }

      return mapConversationRow(conversation);
    } catch (error) {
      console.error('Failed to create conversation:', error);
      return null;
    }
  }

  // Mark messages as read (simplified)
  async markMessagesAsRead(conversationId: string): Promise<void> {
    try {
      // Check if there's an active session first to avoid auth errors
      const { data: session } = await supabase.auth.getSession();
      if (!session.session) return;

      const { data: user } = await supabase.auth.getUser();
      if (!user.user) return;

      await supabase
        .from('messages')
        .update({ read_at: new Date().toISOString() })
        .eq('conversation_id', conversationId)
        .neq('sender_id', user.user.id)
        .is('read_at', null);
    } catch (error) {
      console.error('Failed to mark messages as read:', error);
    }
  }

  // Real-time subscriptions
  subscribeToConversations(callback: (conversations: SimpleConversation[]) => void): () => void {
    this.conversationCallbacks.push(callback);

    const channel = supabase.channel('conversations')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'conversations',
        },
        () => {
          // Reload conversations when any change occurs
          this.getConversations().then(conversations => {
            this.conversationCallbacks.forEach(cb => cb(conversations));
          });
        }
      )
      .subscribe();

    this.channels.set('conversations', channel);

    // Return unsubscribe function
    return () => {
      const index = this.conversationCallbacks.indexOf(callback);
      if (index > -1) {
        this.conversationCallbacks.splice(index, 1);
      }
      if (this.conversationCallbacks.length === 0) {
        channel.unsubscribe();
        this.channels.delete('conversations');
      }
    };
  }

  subscribeToMessages(
    conversationId: string,
    callback: (messages: SimpleMessage[]) => void
  ): () => void {
    if (!this.messageCallbacks.has(conversationId)) {
      this.messageCallbacks.set(conversationId, []);
    }
    this.messageCallbacks.get(conversationId)!.push(callback);

    const channelName = `messages_${conversationId}`;

    if (!this.channels.has(channelName)) {
      const channel = supabase.channel(channelName)
        .on(
          'postgres_changes',
          {
            event: '*',
            schema: 'public',
            table: 'messages',
            filter: `conversation_id=eq.${conversationId}`,
          },
          () => {
            // Reload messages when any change occurs
            this.getMessages(conversationId).then(messages => {
              this.messageCallbacks.get(conversationId)?.forEach(cb => cb(messages));
            });
          }
        )
        .subscribe();

      this.channels.set(channelName, channel);
    }

    // Return unsubscribe function
    return () => {
      const callbacks = this.messageCallbacks.get(conversationId);
      if (callbacks) {
        const index = callbacks.indexOf(callback);
        if (index > -1) {
          callbacks.splice(index, 1);
        }
        if (callbacks.length === 0) {
          this.messageCallbacks.delete(conversationId);
          const channel = this.channels.get(channelName);
          if (channel) {
            channel.unsubscribe();
            this.channels.delete(channelName);
          }
        }
      }
    };
  }

  // Typing indicators (simplified)
  async sendTypingIndicator(conversationId: string, isTyping: boolean): Promise<void> {
    try {
      // Check if there's an active session first to avoid auth errors
      const { data: session } = await supabase.auth.getSession();
      if (!session.session) return;

      const { data: user } = await supabase.auth.getUser();
      if (!user.user) return;

      const channel = supabase.channel(`typing_${conversationId}`);
      await channel.send({
        type: 'broadcast',
        event: 'typing',
        payload: {
          user_id: user.user.id,
          conversation_id: conversationId,
          is_typing: isTyping,
          timestamp: new Date().toISOString(),
        },
      });
    } catch (error) {
      console.error('Failed to send typing indicator:', error);
    }
  }

  subscribeToTyping(
    conversationId: string,
    callback: (data: { user_id: string; is_typing: boolean }) => void
  ): () => void {
    const channelName = `typing_${conversationId}`;
    const channel = supabase.channel(channelName)
      .on('broadcast', { event: 'typing' }, (payload) => {
        callback(payload.payload);
      })
      .subscribe();

    this.channels.set(channelName, channel);

    return () => {
      channel.unsubscribe();
      this.channels.delete(channelName);
    };
  }

  // Clean up all subscriptions
  cleanup(): void {
    this.channels.forEach(channel => channel.unsubscribe());
    this.channels.clear();
    this.conversationCallbacks.length = 0;
    this.messageCallbacks.clear();
  }
}

export const simpleMessagingService = new SimpleMessagingService();
