'use client';

import { supabase } from '@/lib/supabase';
import { Database } from '@/types/supabase';
import { RealtimeChannel } from '@supabase/supabase-js';

// Type definitions
type ConversationRow = Database['public']['Tables']['conversations']['Row'];
type MessageRow = Database['public']['Tables']['messages']['Row'];
type ConversationInsert = Database['public']['Tables']['conversations']['Insert'];
type MessageInsert = Database['public']['Tables']['messages']['Insert'];

export interface ConversationWithDetails extends ConversationRow {
  unreadCount: number;
  instructor?: {
    id: string;
    user_id: string;
    business_name: string;
  };
  studio?: {
    id: string;
    email: string;
    user_profiles: {
      first_name: string;
      last_name: string;
      avatar_url?: string;
    };
  };
}

export interface MessageWithSender extends MessageRow {
  sender?: {
    id: string;
    email: string;
    role: string;
    user_profiles: {
      first_name: string;
      last_name: string;
      avatar_url?: string;
    };
  };
}

class MessagingService {
  private channels: Map<string, RealtimeChannel> = new Map();
  private conversationCallbacks: ((conversations: ConversationWithDetails[]) => void)[] = [];
  private messageCallbacks: Map<string, ((messages: MessageWithSender[]) => void)[]> = new Map();

  // Get all conversations for current user
  async getConversations(): Promise<ConversationWithDetails[]> {
    const { data: user } = await supabase.auth.getUser();
    if (!user.user) throw new Error('Not authenticated');

    const { data: conversations, error } = await supabase
      .from('conversations')
      .select(`
        *,
        instructor:instructors!instructor_id (
          id,
          user_id,
          business_name
        ),
        studio:users!studio_id (
          id,
          email,
          user_profiles (
            first_name,
            last_name,
            avatar_url
          )
        )
      `)
      .order('last_message_at', { ascending: false, nullsFirst: false })
      .order('created_at', { ascending: false });

    if (error) throw error;

    // Calculate unread count for each conversation
    const conversationsWithUnread = await Promise.all(
      (conversations || []).map(async (conv) => {
        const { count } = await supabase
          .from('messages')
          .select('*', { count: 'exact', head: true })
          .eq('conversation_id', conv.id)
          .neq('sender_id', user.user.id)
          .is('read_at', null);

        return {
          ...conv,
          unreadCount: count || 0,
        } as ConversationWithDetails;
      })
    );

    return conversationsWithUnread;
  }

  // Get messages for a specific conversation
  async getMessages(conversationId: string): Promise<MessageWithSender[]> {
    const { data: messages, error } = await supabase
      .from('messages')
      .select(`
        *,
        sender:users!sender_id (
          id,
          email,
          role,
          user_profiles (
            first_name,
            last_name,
            avatar_url
          )
        )
      `)
      .eq('conversation_id', conversationId)
      .order('created_at', { ascending: true });

    if (error) throw error;
    return messages as MessageWithSender[] || [];
  }

  // Send a new message
  async sendMessage(conversationId: string, content: string, attachments?: Array<{
    type: 'image' | 'file';
    url: string;
    name: string;
  }>): Promise<MessageWithSender> {
    const { data: user } = await supabase.auth.getUser();
    if (!user.user) throw new Error('Not authenticated');

    const messageData: MessageInsert = {
      conversation_id: conversationId,
      sender_id: user.user.id,
      content,
      attachments: attachments || [],
    };

    const { data: message, error } = await supabase
      .from('messages')
      .insert(messageData)
      .select(`
        *,
        sender:users!sender_id (
          id,
          email,
          role,
          user_profiles (
            first_name,
            last_name,
            avatar_url
          )
        )
      `)
      .single();

    if (error) throw error;
    return message as MessageWithSender;
  }

  // Create a new conversation
  async createConversation(
    instructorId: string,
    name: string,
    type: 'individual' | 'group' = 'individual'
  ): Promise<ConversationWithDetails> {
    const { data: user } = await supabase.auth.getUser();
    if (!user.user) throw new Error('Not authenticated');

    // Get instructor details to build participants array
    const { data: instructor, error: instructorError } = await supabase
      .from('instructors')
      .select('user_id')
      .eq('id', instructorId)
      .single();

    if (instructorError) throw instructorError;

    const conversationData: ConversationInsert = {
      studio_id: user.user.id,
      instructor_id: instructorId,
      type,
      name,
      participants: [user.user.id, instructor.user_id],
    };

    const { data: conversation, error } = await supabase
      .from('conversations')
      .insert(conversationData)
      .select(`
        *,
        instructor:instructors!instructor_id (
          id,
          user_id,
          business_name
        ),
        studio:users!studio_id (
          id,
          email,
          user_profiles (
            first_name,
            last_name,
            avatar_url
          )
        )
      `)
      .single();

    if (error) throw error;
    return { ...conversation, unreadCount: 0 } as ConversationWithDetails;
  }

  // Mark messages as read
  async markMessagesAsRead(conversationId: string): Promise<void> {
    const { data: user } = await supabase.auth.getUser();
    if (!user.user) return;

    await supabase
      .from('messages')
      .update({ read_at: new Date().toISOString() })
      .eq('conversation_id', conversationId)
      .neq('sender_id', user.user.id)
      .is('read_at', null);
  }

  // Real-time subscriptions
  subscribeToConversations(callback: (conversations: ConversationWithDetails[]) => void): () => void {
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
    callback: (messages: MessageWithSender[]) => void
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

  // Typing indicators
  async sendTypingIndicator(conversationId: string, isTyping: boolean): Promise<void> {
    const { data: user } = await supabase.auth.getUser();
    if (!user.user) return;

    // Send typing indicator through realtime channel
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

export const messagingService = new MessagingService();