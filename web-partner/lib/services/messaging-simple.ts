'use client';

import { supabase } from '@/lib/supabase';
import { RealtimeChannel } from '@supabase/supabase-js';

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
  created_at: string;
  updated_at: string;
}

class SimpleMessagingService {
  private channels: Map<string, RealtimeChannel> = new Map();
  private conversationCallbacks: ((conversations: SimpleConversation[]) => void)[] = [];
  private messageCallbacks: Map<string, ((messages: SimpleMessage[]) => void)[]> = new Map();

  // Get all conversations for current user
  async getConversations(): Promise<SimpleConversation[]> {
    try {
      const { data: user } = await supabase.auth.getUser();
      if (!user.user) {
        console.log('No authenticated user, returning empty conversations');
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
      const conversationsWithUnread = (conversations || []).map(conv => ({
        ...conv,
        unreadCount: 0 // Will be calculated in a future enhancement
      }));

      return conversationsWithUnread;
    } catch (error) {
      console.error('Failed to get conversations:', error);
      return [];
    }
  }

  // Get messages for a specific conversation
  async getMessages(conversationId: string): Promise<SimpleMessage[]> {
    try {
      const { data: messages, error } = await supabase
        .from('messages')
        .select('*')
        .eq('conversation_id', conversationId)
        .order('created_at', { ascending: true });

      if (error) {
        console.error('Error fetching messages:', error);
        return [];
      }

      return messages || [];
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
      const { data: user } = await supabase.auth.getUser();
      if (!user.user) {
        console.error('No authenticated user');
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

      return message;
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
      const { data: user } = await supabase.auth.getUser();
      if (!user.user) {
        console.error('No authenticated user');
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

      return { ...conversation, unreadCount: 0 };
    } catch (error) {
      console.error('Failed to create conversation:', error);
      return null;
    }
  }

  // Mark messages as read (simplified)
  async markMessagesAsRead(conversationId: string): Promise<void> {
    try {
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